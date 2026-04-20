import pyb
import time
time.sleep_ms(1500)
import sensor
import time
import ml
import math
import uos
import gc
import struct
import bluetooth
import math
from pyb import ADC, Pin
from micropython import const
from machine import I2C
from bno055 import BNO055
from ml.postprocessing.edgeimpulse import Fomo
from pyb import UART
led = Pin('LED_RED', Pin.OUT_PP)
while True:
    try:
        sensor.reset()
        sensor.set_pixformat(sensor.GRAYSCALE)
        sensor.set_framesize(sensor.QVGA)
        sensor.skip_frames(time=3000)
        sensor.snapshot()
        break
    except Exception as e:
        pyb.hard_reset()
        if led.value() == 0:
            led.high()
        else:
            led.low()
        time.sleep_ms(500)
uart = UART(1, 115200)
uart.init(115200, bits=8, parity=None, stop=1)
clock = time.clock()
adc = ADC(Pin('A0'))
i2c3 = I2C(3)
time.sleep_ms(500)
imu = BNO055(i2c3)

connected = False
subscribed = False
conn_handle = None
ble = bluetooth.BLE()
ble.active(True)

SERVICE_UUID = bluetooth.UUID(0x0075)
PACKET_CHAR_UUID = bluetooth.UUID(0x0081)
IMAGE_CHAR_UUID = bluetooth.UUID(0x0080)
SENSOR_CHAR_UUID = bluetooth.UUID(0x0075)
FLAGS = bluetooth.FLAG_READ | bluetooth.FLAG_WRITE | bluetooth.FLAG_NOTIFY
((packet_handle, image_handle, sensor_handle),) = ble.gatts_register_services((
    (SERVICE_UUID, (
        (PACKET_CHAR_UUID, FLAGS),
        (IMAGE_CHAR_UUID, FLAGS),
        (SENSOR_CHAR_UUID, FLAGS),
    )),
))
name = b'PERFECTPUTT'
adv_data = bytes([0x02, 0x01, 0x06]) + bytes([len(name) + 1, 0x09]) + name
ble.gap_advertise(100000, adv_data=adv_data)

_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)

PACKET_CCCD = packet_handle + 1
IMAGE_CCCD  = image_handle + 1
SENSOR_CCCD = sensor_handle + 1

def ble_irq(event, data):
    global connected, subscribed, conn_handle
    if event == _IRQ_CENTRAL_CONNECT:
        conn_handle, addr_type, addr = data
        connected = True
        subscribed = False
        print("CONNECTED", conn_handle)
    elif event == _IRQ_CENTRAL_DISCONNECT:
        conn_handle, addr_type, addr = data
        connected = False
        subscribed = False
        conn_handle = None
        print("DISCONNECTED")
        ble.gap_advertise(100_000, adv_data=adv_data)
    elif event == _IRQ_GATTS_WRITE:
        ch, value_handle = data
        if value_handle in (PACKET_CCCD, IMAGE_CCCD, SENSOR_CCCD):
            cccd = ble.gatts_read(value_handle)
            enabled = (cccd[0] & 0x01) == 0x01
            subscribed = enabled
            print("SUBSCRIBED" if enabled else "UNSUBSCRIBED", "handle", value_handle)

ble.irq(ble_irq)
impact = 0
hit_detected = 0
hit_start = 0
last_notify_time = 0
NOTIFY_INTERVAL_MS = 100
state_practice = 0
state_automatic = 1
voltage_threshold = 2.8
distance = 0
last_shot_time = 0
SHOT_COOLDOWN_MS = 2000
press_start = 0
last_button = 1
LONG_PRESS_MS = 2000
p = Pin('D0', Pin.IN, Pin.PULL_UP)
q = Pin('D4', Pin.IN, Pin.PULL_UP)
led_red = Pin('LED_RED', Pin.OUT_PP)
led_green = Pin('LED_GREEN', Pin.OUT_PP)
led_blue = Pin('LED_BLUE', Pin.OUT_PP)
# Next few lines set up the neural network information
min_confidence = 0.8
try:
    net = ml.Model("trained.tflite", load_to_fb=uos.stat('trained.tflite')[6] > (gc.mem_free() - (64*1024)), postprocess=Fomo(threshold=min_confidence))
except Exception as e:
    raise Exception('Failed to load "trained.tflite" (' + str(e) + ')')

try:
    labels = [line.rstrip('\n') for line in open("labels.txt")]
except Exception as e:
    raise Exception('Failed to load "labels.txt" (' + str(e) + ')')
colors = [
    (255,   0,   0),
    (  0, 255,   0),
    (255, 255,   0),
    (  0,   0, 255),
    (255,   0, 255),
    (  0, 255, 255),
    (255, 255, 255),
]
'''
# FSM states
SWING_IDLE = 0
SWING_BACKSWING = 1
SWING_DOWNSWING = 2
SWING_IMPACT = 3
SWING_FOLLOW = 4
SWING_DONE = 5
'''
# FSM variables
done_start = 0
swing_state = 0
backswing_start = 0
downswing_start = 0
impact_time = 0
follow_start = 0
backswing_duration = 0
downswing_duration = 0
GYRO_THRESHOLD = 20.0
impact = 0.0
follow = 0.0
tempo = 0.0
stability = 0.0
straightness = 0.0
direction = 0
result = 0
swing_done_ind = 0
impact_pitch = 0
while True:
    adc_value = adc.read()
    voltage = (adc_value / 4095.0) * 3.3

    ax, ay, az = imu.accelerometer()
    gx, gy, gz = imu.gyroscope()
    heading, roll, pitch = imu.euler()
    current_time = time.ticks_ms()
    ax_lin, ay_lin, az_lin = imu.linear_acceleration()
    accel_mag = math.sqrt(ax_lin*ax_lin + ay_lin*ay_lin + az_lin*az_lin)
    if(gy > 0):
        gyro_mag = math.sqrt(gx*gx + gy*gy)
    else:
        gyro_mag = -1 * math.sqrt(gx*gx + gy*gy)
    clock.tick()
    img = sensor.snapshot()
    if(state_practice == 1):
        if(swing_done_ind == 1):
            led_red.low()
        else:
            led_red.high()
        led_green.low()
    else:
        led_green.high()
        led_red.low()
    # handle button pressses
    if(p.value() == 0):
        if(last_button == 1):
            press_start = time.ticks_ms()
            last_button = 0

    else:
        if(last_button == 0):
            time_duration = time.ticks_diff(time.ticks_ms(), press_start)
            if(time_duration >= LONG_PRESS_MS):
                if(state_automatic == 1):
                    state_automatic = 0
                    state_practice = 1
                else:
                    state_automatic = 1
                    state_practice = 0
            else:
                if(state_automatic == 1):
                    distance = distance + 1
        last_button = 1
    if(state_practice == 1):
        distance = 0
        ball_present = 0

        detections = net.predict([img])

        if len(detections) > 1:
            ball_detections = detections[1]
        else:
            ball_detections = []

        if len(ball_detections) > 0:
            ball_present = 1
            print("Ball present")
            for (x, y, w, h), score in ball_detections:
                center_x = int(x + (w / 2))
                center_y = int(y + (h / 2))
                img.draw_circle(center_x, center_y, 12, color=colors[1])

        if ball_present == 1:
            led_blue.low()
        else:
            led_blue.high()
        #print(pitch)


        if swing_state == 0:
            if time.ticks_diff(current_time, done_start) < 4000:
                swing_done_ind = 1
            elif (gz > 0.12):
                swing_done_ind = 0
                swing_state = 1
                backswing_start = current_time
                print("BACKSWING")

        elif swing_state == 1:
            if gz < -0.12:
                swing_state = 2
                downswing_start = current_time
                backswing_duration = time.ticks_diff(current_time, backswing_start)
                print("DOWNSWING")
            elif time.ticks_diff(current_time, backswing_start) > 750:
                swing_state = 0
        elif swing_state == 2:
            if pitch < -90:
                swing_state = 3
                impact_time = current_time
                downswing_duration = time.ticks_diff(current_time, downswing_start)
                # capture at moment of contact
                impact = accel_mag
                impact_pitch = pitch
                stability = gyro_mag
                straightness = math.sqrt(ax_lin*ax_lin + az_lin*az_lin)
                direction = 1 if ax_lin > 0 else 0
                tempo = downswing_duration / backswing_duration if backswing_duration > 0 else 0.0
                print("IMPACT")
            elif time.ticks_diff(current_time, downswing_start) > 1000:
                swing_state = 0


        elif swing_state == 3:
            if accel_mag > impact:
                impact = accel_mag
            if time.ticks_diff(current_time, impact_time) > 500:
                swing_state = 4
                follow_start = current_time
                print("FOLLOW")

        elif swing_state == 4:
            if (abs(pitch - impact_pitch) > follow):
                follow = abs(pitch-impact_pitch)
            if time.ticks_diff(current_time, follow_start) > 2000:
                swing_state = 5
                print("DONE")
        elif swing_state == 5:
            done_start = current_time
            result = 1 if ball_present == 1 else 0
            swing_state = 0
            print(follow)
            # send final packet once with real values
            if connected and conn_handle is not None:
                packet = struct.pack("<fffffff", impact, follow, tempo, stability, straightness, direction, result)
                ble.gatts_write(sensor_handle, packet)
                ble.gatts_notify(conn_handle, sensor_handle, packet)

    else:
        # Auto hitter mode, will integrate UART with ESP32 later
        if(q.value() == 0):
            current_time = time.ticks_ms()
            if time.ticks_diff(current_time, last_shot_time) > SHOT_COOLDOWN_MS:
                msg = "{}\n".format(distance)  # newline helps ESP32 parsing
                uart.write(msg)
                print(distance) # This will actually go over UART
                last_shot_time = current_time
                distance = 0



    #Uncomment to test BLE

    '''
    #impact = 12.34 #Peak acceleration magnitude around impact,
    #follow = 45.6 # How much the club rotates after impact
    tempo = 2.1 # downswing/backswing
    stability = 3.3 #How much the club is rotating at the exact moment of impact
    straightness = 0.8 # Acceleration perpendicular to swing axis
    direction = 1   # right = 1, left = 0, ball not detected = 0.5
    result = 0      # miss = 0, hit = 1

                    # Pack into binary (little endian)
    current_time = time.ticks_ms()
    if connected and conn_handle is not None:
        if time.ticks_diff(current_time, last_notify_time) > NOTIFY_INTERVAL_MS:
            packet = struct.pack("<fffffff", impact, follow, tempo, stability, straightness, direction, result)
            ble.gatts_write(sensor_handle, packet)
            ble.gatts_notify(conn_handle, sensor_handle, packet)
            last_notify_time = current_time


    '''





