import pyb
import time
time.sleep_ms(1500)
import sensor
import image
import struct
import bluetooth
import math
from pyb import ADC, Pin
from micropython import const
from machine import I2C
from bno055 import BNO055

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

F_px = 146
golf_ball_d = 0.04267
golf_hole_d = 0.11
last_sensor_send = 0
IMG_W, IMG_H = 320, 240
CX0, CY0 = IMG_W//2, IMG_H//2
HIT_COOLDOWN_MS = 500
last_hit_ms = 0
WAIT_MS_SWING = 6000
swing_toggled = False
FORCE_SWING = 0
ANGLE_SWING = 0
DEGREE_SWING = 0
ELAPSED_SINCE_HIT = 0

def distance(blob, real_d_m):
    if blob is None or F_px <= 0:
        return None
    d_px = (blob.w() + blob.h()) * 0.5
    if d_px <= 0:
        return None
    Z = (F_px * real_d_m) / d_px
    dx = blob.cx() - CX0
    dy = blob.cy() - CY0
    X = Z * (dx / F_px)
    Y = Z * (dy / F_px)
    return (X, Y, Z)

def distance_circle(circle, real_d_m):
    if circle is None or F_px <= 0:
        return None
    d_px = circle.r() * 2
    if d_px <= 0:
        return None
    Z = (F_px * real_d_m) / d_px
    dx = circle.x() - CX0
    dy = circle.y() - CY0
    X = Z * (dx / F_px)
    Y = Z * (dy / F_px)
    return (X, Y, Z)

def distance_ball_to_hole(ball=None, hole_blob=None):
    pb = distance_circle(ball, golf_ball_d)
    ph = distance(hole_blob, golf_hole_d)
    if pb is None or ph is None:
        return None, pb, ph
    dx = ph[0] - pb[0]
    dy = ph[1] - pb[1]
    dz = ph[2] - pb[2]
    return math.sqrt(dx*dx + dy*dy + dz*dz), pb, ph

while True:
    img = sensor.snapshot()
    p = Pin('D0', Pin.IN, Pin.PULL_UP)
    led = Pin('LED_RED', Pin.OUT_PP)
    if(p.value() == 0):
        led.high()
    else:
        led.low()

    adc_value = adc.read()
    voltage = (adc_value / 4095.0) * 3.3

    ax, ay, az = imu.accelerometer()
    gx, gy, gz = imu.gyroscope()

    img_edges = img.copy()
    img_edges.find_edges(image.EDGE_CANNY, threshold=(50, 120))
    circles = img_edges.find_circles(threshold=3000, r_min=5, r_max=40,
                                      x_margin=2, y_margin=2, r_margin=2)
    best = None
    best_score = -1.0
    for c in circles:
        if c.magnitude() < 3000:
            continue
        if c.r() < 5 or c.r() > 40:
            continue
        if c.x() < 5 or c.x() > IMG_W - 5:
            continue
        if c.y() < 5 or c.y() > IMG_H - 5:
            continue
        score = c.magnitude() + (c.r() * 2)
        if score > best_score:
            best_score = score
            best = c
    if best:
        img.draw_circle(best.x(), best.y(), best.r(), color=255)
        img.draw_cross(best.x(), best.y(), color=0, size=10)

    holes = img.find_blobs([(0, 50)], area_threshold=200)
    best_hole = None
    best_area = 0
    for hole in holes:
        ar = hole.w() / max(1, hole.h())
        if ar < 0.6 or ar > 1.4:
            continue
        if hole.elongation() > 1.5:
            continue
        if hole.area() < 250:
            continue
        _, _, hole_z = distance(hole, golf_hole_d)
        if hole_z is None:
            continue
        exp_px = int((F_px * golf_hole_d) / hole_z)
        if abs(hole.w() - exp_px) > 0.15 * exp_px or \
               abs(hole.h() - exp_px) > 0.15 * exp_px:
            continue
        if hole.area() > best_area:
            best_hole = hole
            best_area = hole.area()

    if best_hole:
        img.draw_rectangle(best_hole.rect(), color=255)

    clock.tick()

    if (p.value() == 0) and best and best_hole:
        dist_to_hole, _, _ = distance_ball_to_hole(best, best_hole)
        if dist_to_hole is not None:
            pixel_offset = best_hole.cx() - CX0
            hole_offset_m = (F_px * pixel_offset) / best_hole.w()
            payload = struct.pack('<ff', dist_to_hole, hole_offset_m)
            ble.gatts_write(packet_handle, payload)
            if connected and subscribed:
                ble.gatts_notify(conn_handle, packet_handle, payload)

    if connected and (time.ticks_ms() - last_sensor_send > 100):
        try:
            sensor_data = struct.pack('<fffffff',
                ax, ay, az,
                gx, gy, gz,
                voltage
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

    if voltage < 3.1:
        roll, pitch, yaw = imu.euler()
        ANGLE_SWING = abs(pitch)
        swing_toggled = True
        FORCE_SWING = voltage
        ELAPSED_SINCE_HIT = time.ticks_ms()

    if swing_toggled and best and best_hole:
        now = time.ticks_ms()
        if time.ticks_diff(now, ELAPSED_SINCE_HIT) >= WAIT_MS_SWING:
            delta_x_px = best.x() - best_hole.cx()
            delta_x_m = (F_px * delta_x_px) / (best.r() * 2)
            delta_y_px = best.y() - best_hole.cy()
            delta_y_m = (F_px * delta_y_px) / (best.r() * 2)
            print("transmitted")
            impact_payload = struct.pack('fffff', delta_x_m, delta_y_m, FORCE_SWING, ANGLE_SWING, DEGREE_SWING)
            ble.gatts_write(image_handle, impact_payload)
            if connected and subscribed:
                ble.gatts_notify(conn_handle, image_handle, impact_payload)
            swing_toggled = False
            FORCE_SWING = 0
            ANGLE_SWING = 0
            DEGREE_SWING = 0
        else:
            roll, pitch, yaw = imu.euler()
            DEGREE_SWING = max(DEGREE_SWING, pitch)