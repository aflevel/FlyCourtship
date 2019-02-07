#!/usr/bin/python

import sys
import os
import numpy as np
import cv2
import datetime
from moviepy.video.io.ffmpeg_reader import FFMPEG_VideoReader

#sys.argv=['','359_CTMxCTF_6.mp4',2]

cap = cv2.VideoCapture(sys.argv[1])

rec = FFMPEG_VideoReader(sys.argv[1],True)
rec.initialize()

frameWidth = int(cap.get(3))
frameHeight = int(cap.get(4))
frameNum=int(cap.get(7))
fps=int(cap.get(5))

fgbg = cv2.createBackgroundSubtractorMOG2(detectShadows = False)

FrameDiff=np.array([])

lapse=int(sys.argv[2])

i=0

while(i<frameNum):
	ret, frame = cap.read()
	fgmask = fgbg.apply(frame)
	if i>lapse*fps+1 and i<frameNum-fps:
		ref=rec.get_frame((i-lapse*fps)/fps)
		refmask = fgbg.apply(ref)
		try:
			frameDelta = cv2.absdiff(refmask, fgmask)
		except:
			frameDelta = np.array([])
			print(str(i) + ' out of ' + str(frameNum))
		entry=[float(i)/fps,np.sum(frameDelta)]
		FrameDiff=np.insert(FrameDiff,[0],entry,axis=0)
	if i<frameNum-fps:
		try:
			cv2.imshow('frame',fgmask)
		except:
			print(str(i) + ' out of ' + str(frameNum))
			break
	i+=1
	k = cv2.waitKey(30) & 0xff
	if k == ord('q'):
	    break

LogFile='Log_' + sys.argv[1].replace(".mp4","_" + str(sys.argv[2]) + "sec.csv")
FrameDiff=np.reshape(FrameDiff,(len(FrameDiff)/2,2))
np.savetxt(LogFile, FrameDiff, delimiter=",")
cap.release()
cv2.destroyAllWindows()

