# THE FOLLOWING SOURCE GAVE SOME INSIGHTS ON HOW TO DO BLOB DETECTION WITH MY PORTENTA
# https://docs.arduino.cc/tutorials/portenta-vision-shield/blob-detection/
import pyb # Import module for board related functions
import time
time.sleep_ms(1500)
import sensor # Import the module for sensor related functions
import image # Import module containing machine vision algorithms
import struct
<<<<<<< HEAD
import bluetooth
import math
from pyb import ADC, Pin
from micropython import const
from machine import I2C
from bno055 import BNO055
=======
import usocket
from pyb import Pin
>>>>>>> 7d4546770d2ecae715b57c7a05f94af3f17625dd
# Took some of below code from reccomended coding practices on the the openMV web site
sensor.reset()  # Reset and initialize the sensor.
sensor.set_pixformat(sensor.GRAYSCALE)  # Set pixel format to RGB565 (or GRAYSCALE)
sensor.set_framesize(sensor.QVGA)  # Set frame size to QVGA (320x240)
#sensor.skip_frames(time=2000)  # Wait for settings take effect.
clock = time.clock()  # Create a clock object to track the FPS.
# Initialize the FSR data
adc = ADC(Pin('A0'))
# Initialize the IMU

i2c3 = I2C(3)
time.sleep_ms(500)
imu = BNO055(i2c3)

# Initialize BLuetooth
connected = False
subscribed = False
conn_handle = None
ble = bluetooth.BLE()
ble.active(True)

SERVICE_UUID = bluetooth.UUID('d8450000-6421-4f80-928d-19548483b890')
PACKET_CHAR_UUID = bluetooth.UUID('d8450001-6421-4f80-928d-19548483b890')
IMAGE_CHAR_UUID = bluetooth.UUID('d8450002-6421-4f80-928d-19548483b890')
SENSOR_CHAR_UUID = bluetooth.UUID('d8450003-6421-4f80-928d-19548483b890')
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


<<<<<<< HEAD
#Need to track if the central is connected
_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)


PACKET_CCCD = packet_handle + 1
IMAGE_CCCD  = image_handle + 1
SENSOR_CCCD = sensor_handle + 1

# Some constants for the Hit data
HIT_COOLDOWN_MS = 500
last_hit_ms = 0
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
# Focal length
F_px = 146
# Size in meters
golf_ball_d = 0.04267
golf_hole_d = 0.108
last_sensor_send = 0
# Track based on pixels
IMG_W, IMG_H = 320, 240
CX0, CY0 = IMG_W//2, IMG_H//2

def distance(blob, real_d_m):
=======
# Now I'll initialize the wiFI access point
print(pyb.Pin.board)
SSID = 'Portenta_AP'  # Your network name
KEY  = '12345678'     # Password (must be at least 8 characters)
wlan = network.WLAN(network.AP_IF)
wlan.config(ssid=SSID, key=KEY, channel=11)
wlan.active(True)
# 2. Set up Server Socket
s = usocket.socket(usocket.AF_INET, usocket.SOCK_STREAM)
s.bind(('', 8080))
s.listen(1)
s.setblocking(False)
conn = None
addr = None
# Store the blobs data in here
blobs_data = [0, 0, 0, 0]
print(wlan.ifconfig())
def terrain_data():
    pass
def distance():
>>>>>>> 7d4546770d2ecae715b57c7a05f94af3f17625dd
    # Process for finding distance to golf ball: https://stackoverflow.com/questions/6714069/finding-distance-from-camera-to-object-of-known-size#:~:text=You%20know%20your%20ball's%20size,17.4k6%2071%20143
    # 1. Place the ball at a known distance
    # 2. since we know the size of the golf ball, the focal length is given by F = (width*distance)/(Balls height)
    # 3. Now its just a generic Distance = (F*balls height)/width

    # Process for finding distance to hole:
    # Same as above, Width should remain constant at any given distance


    # Process for finding distance from hole to ball:
    # 1. Hole and ball must be lined up in view of portenta
    # 2. distance to hole - distance to ball
<<<<<<< HEAD
    if blob is None or F_px <= 0:
            return None
=======
    pass
print("ALIVE")
names = [n for n in dir(pyb.Pin.board) if not n.startswith("_")]
print("count =", len(names))

for n in names:
    print(n)
    time.sleep_ms(5)
while True:
    p = Pin('D0', Pin.IN, Pin.PULL_UP)
    led = Pin('LED_RED', Pin.OUT_PP)   # on-board LED name usually works
    if(p.value() == 0):
        led.high()
    else:
        led.low()
    if not conn:
            try:
                conn, addr = s.accept()
                print("Client connected:", addr)
            except:
                pass
    # to the IDE. The FPS should increase once disconnected.
    if(p.value() == 0):
        golf_ball_threshold = (200, 255) # Threshold for an extremely white object
        img = sensor.snapshot()  # Take a picture and return the image.
        blobs = img.find_blobs([golf_ball_threshold], area_threshold=225, merge=False)
        if blobs:
            for blob in blobs: #Ideally only one but just in case
                if blob.roundness() > 0.8 and blob.elongation() < 0.2:
                    img.draw_rectangle(blob.rect(), color=255)
                    blobs_data[0] = blob.cx()
                    blobs_data[1] = blob.cy()
                    break
        holes = img.find_blobs([(0, 50)], area_threshold=200)
        if holes:
            for hole in holes:
                if 0.2 < hole.elongation() < 0.9:# Check if its elongate and
                    # Make sure it's wider than it is tall
                    if hole.w() > hole.h():
                        img.draw_rectangle(hole.rect(), color = 255)
                        blobs_data[2] = hole.cx()
                        blobs_data[3] = hole.cy()
                        break
        clock.tick()  # Update the FPS clock.
        #print(clock.fps())  # Note: OpenMV Cam runs about half as fast when connected

        # Send packets
        if conn:
            try:
                output = "%d,%d|%d,%d\n" % tuple(blobs_data)
                conn.send(output.encode())
            except:
                pass

    else:
        pass
>>>>>>> 7d4546770d2ecae715b57c7a05f94af3f17625dd

    d_px = (blob.w() + blob.h()) * 0.5
    if d_px <= 0:
        return None

    Z = (F_px * real_d_m) / d_px
    dx = blob.cx() - CX0
    dy = blob.cy() - CY0

    X = Z * (dx / F_px)
    Y = Z * (dy / F_px)
    return (X, Y, Z)
def distance_ball_to_hole(ball_blob=None, hole_blob=None):
    pb = distance(ball_blob, golf_ball_d)
    ph = distance(hole_blob, golf_hole_d)
    if pb is None or ph is None:
        return None, pb, ph

    dx = ph[0] - pb[0]
    dy = ph[1] - pb[1]
    dz = ph[2] - pb[2]
    return math.sqrt(dx*dx + dy*dy + dz*dz), pb, ph

while True:
    #print("BLE Active:", ble.active())
    # see if I'm connected
    # Test the button
    img = sensor.snapshot()
    p = Pin('D0', Pin.IN, Pin.PULL_UP)
    led = Pin('LED_RED', Pin.OUT_PP)   # on-board LED name usually works
    if(p.value() == 0):
        led.high()
    else:
        led.low()
    #print(p.value())
    # Test the FSR
    adc_value = adc.read()
    voltage = (adc_value / 4095.0) * 3.3
    #print("ADC:", adc_value, "Voltage:", voltage)
    # Test the IMU
    ax, ay, az = imu.accelerometer()
    gx, gy, gz = imu.gyroscope()
    print("X: %6.2f | Y: %6.2f | Z: %6.2f (m/s^2)" % (ax, ay, az))

    golf_ball_threshold = (200, 255) # Threshold for an extremely white object
    #img = sensor.snapshot()  # Take a picture and return the image.
    blobs = img.find_blobs([golf_ball_threshold], area_threshold=225, merge=False)

    best = None
    best_score = -1.0
    if blobs:
        for blob in blobs:
            if blob.pixels() < 225:
                continue
            r = blob.roundness()
            e = blob.elongation()
            score = (2.0 * r) - (1.0 * e) + (0.002 * blob.pixels())
            if score > best_score:
                best_score = score
                best = blob
    if best:
        img.draw_rectangle(best.rect(), color=255)
        img.draw_cross(best.cx(), best.cy(), color=255, size=10)
    holes = img.find_blobs([(0, 50)], area_threshold=200)
    best_hole = None
    best_area = 0
    for hole in holes:
        ar = hole.w() / max(1, hole.h())
        if hole.area() > 300 and ar > 1.3 and hole.elongation() > 0.7:
            if hole.area() > best_area:
                best_hole   = hole
                best_area = hole.area()
    if best_hole:
        img.draw_rectangle(best_hole.rect(), color=255)
    clock.tick()  # Update the FPS clock.
    IMG_CHUNK = 120
    IMG_COOLDOWN_MS = 10_000
    last_img_send = 0
    #print(p.value())
    if (p.value() == 0) and best and best_hole:
        dist_m, pb, ph = distance_ball_to_hole(best, best_hole)

        if dist_m is not None:
            force = int(min(1000, max(0, dist_m * 700)))   # tune 700
            payload = struct.pack('<fH', dist_m, force)

            ble.gatts_write(packet_handle, payload)
            if connected and subscribed:
                ble.gatts_notify(conn_handle, packet_handle, payload)
    if connected and (time.ticks_ms() - last_sensor_send > 100):
        try:
            # Stream: accel + gyro + FSR voltage
            sensor_data = struct.pack('<fffffff',
                ax, ay, az,    # Accelerometer
                gx, gy, gz,    # Gyroscope
                voltage        # FSR voltage
            )
            ble.gatts_write(sensor_handle, sensor_data)

            if subscribed:
                ble.gatts_notify(conn_handle, sensor_handle, sensor_data)

            last_sensor_send = time.ticks_ms()
        except OSError as e:
            print("Stream failed:", e)
            connected = False
            subscribed = False
            conn_handle = None
    #if best and best_hole: print("Ball->Hole: %.3f m" % distance_ball_to_hole(best, best_hole)[0])
    now = time.ticks_ms()
    if voltage < 3.1 and time.ticks_diff(now, last_hit_ms) > HIT_COOLDOWN_MS:
        last_hit_ms = now
        impact_payload = struct.pack('<Ifffffff', now, ax, ay, az, gx, gy, gz, voltage)
        ble.gatts_write(image_handle, impact_payload)  
        if connected and subscribed:
            ble.gatts_notify(conn_handle, image_handle, impact_payload)
    #print("FSR: %.3f V" % voltage)
