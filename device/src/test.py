import sensor
import time
import ml
import math
import uos
import gc
from ml.postprocessing.edgeimpulse import Fomo

sensor.reset()
sensor.set_pixformat(sensor.GRAYSCALE)
sensor.set_framesize(sensor.QVGA)
sensor.set_windowing((240, 240))
sensor.skip_frames(time=2000)

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

clock = time.clock()
while True:
    clock.tick()
    img = sensor.snapshot()
    for i, detection_list in enumerate(net.predict([img])):
        if i == 0:
            continue
        if len(detection_list) == 0:
            continue
        print("********** %s **********" % labels[i])
        for (x, y, w, h), score in detection_list:
            center_x = math.floor(x + (w / 2))
            center_y = math.floor(y + (h / 2))
            print(f"x {center_x}\ty {center_y}\tscore {score}")
            img.draw_circle((center_x, center_y, 12), color=colors[i])
    print(clock.fps(), "fps", end="\n\n")