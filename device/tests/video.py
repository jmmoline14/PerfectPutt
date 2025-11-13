import serial
import numpy as np
import cv2

# Adjust COM port and baud rate
def displayVideo():
    ser = serial.Serial('COM9', 250000)
    while True:
        value = ser.readline()
        
if __name__ == "__main__":
    main()

