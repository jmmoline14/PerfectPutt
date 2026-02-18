# THE FOLLOWING SOURCE GAVE SOME INSIGHTS ON HOW TO DO BLOB DETECTION WITH MY PORTENTA
# https://docs.arduino.cc/tutorials/portenta-vision-shield/blob-detection/
import pyb # Import module for board related functions
import sensor # Import the module for sensor related functions
import image # Import module containing machine vision algorithms
import time # Import module for tracking elapsed time
import network
import struct
import usocket
from pyb import Pin
# Took some of below code from reccomended coding practices on the the openMV web site
sensor.reset()  # Reset and initialize the sensor.
sensor.set_pixformat(sensor.GRAYSCALE)  # Set pixel format to RGB565 (or GRAYSCALE)
sensor.set_framesize(sensor.QVGA)  # Set frame size to QVGA (320x240)
#sensor.skip_frames(time=2000)  # Wait for settings take effect.
clock = time.clock()  # Create a clock object to track the FPS.


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
    # Process for finding distance to golf ball: https://stackoverflow.com/questions/6714069/finding-distance-from-camera-to-object-of-known-size#:~:text=You%20know%20your%20ball's%20size,17.4k6%2071%20143
    # 1. Place the ball at a known distance
    # 2. since we know the size of the golf ball, the focal length is given by F = (width*distance)/(Balls height)
    # 3. Now its just a generic Distance = (F*balls height)/width

    # Process for finding distance to hole:
    # Same as above, Width should remain constant at any given distance


    # Process for finding distance from hole to ball:
    # 1. Hole and ball must be lined up in view of portenta
    # 2. distance to hole - distance to ball
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

