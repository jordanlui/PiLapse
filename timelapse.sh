#!/bin/bash
# Thank you to Kyle for this code: 
# http://kylehase.blogspot.com/2017/03/updated-raspberry-pi-timelapse-camera.html

DATESTAMP=$(date +"%Y-%m-%dT%H%M%S")

# kill any running raspistill preview windows. See below
pkill raspistill

# Take photo
echo "taking photo $DATESTAMP.jpg"
raspistill -ISO 100 -ev 5 -co 20 -sa 10 -awb auto -ifx denoise -mm matrix -drc med -th none -o /tmp/$DATESTAMP.jpg

# Show live preview window at all times while not shooting
raspistill -t 7200000 -f & 

# upload photo
/home/pi/upload.sh $DATESTAMP.jpg
if [ $? -ne 0 ]; then
  # upload failed, move out of tmp to SD
  mv /tmp/$DATESTAMP.jpg /home/pi/Pictures/$DATESTAMP.jpg
  echo "Upload failed. Storing photo in ~./Pictures"
fi