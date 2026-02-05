# THE FOLLOWING SOURCE GAVE SOME INSIGHTS ON HOW TO DO BLOB DETECTION WITH MY PORTENTA
# https://docs.arduino.cc/tutorials/portenta-vision-shield/blob-detection/
import pyb # Import module for board related functions
import sensor # Import the module for sensor related functions
import image # Import module containing machine vision algorithms
import time # Import module for tracking elapsed time

# Took some of below code from reccomended coding practices on the the openMV web site
sensor.reset()  # Reset and initialize the sensor.
sensor.set_pixformat(sensor.GRAYSCALE)  # Set pixel format to RGB565 (or GRAYSCALE)
sensor.set_framesize(sensor.QVGA)  # Set frame size to QVGA (320x240)
sensor.skip_frames(time=2000)  # Wait for settings take effect.
clock = time.clock()  # Create a clock object to track the FPS.

    

while True:
    
    # to the IDE. The FPS should increase once disconnected.
    golf_ball_threshold = (200, 255) # Threshold for an extremely white object
    img = sensor.snapshot()  # Take a picture and return the image.
    blobs = img.find_blobs([golf_ball_threshold], area_threshold=225, merge=False)
    for blob in blobs: #Ideally only one but just in case
        if blob.roundness() > 0.8 and blob.elongation() < 0.2:
            img.draw_rectangle(blob.rect(), color=255)
    clock.tick()  # Update the FPS clock.
    print(clock.fps())  # Note: OpenMV Cam runs about half as fast when connected
    
