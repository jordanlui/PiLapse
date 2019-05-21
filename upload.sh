#!/bin/bash

# Thank you to Kyle for this code: 
# http://kylehase.blogspot.com/2017/03/updated-raspberry-pi-timelapse-camera.html

DATE=$(date +"%Y-%m-%d")
DATESTAMP=$(date +"%Y-%m-%dT%H%M%S")
YESTERDAY=$(date -d "yesterday 13:00" +"%Y-%m-%d")
PARENT_ID=$(</home/pi/parent)
SSID="<your SSID>"

# Cleanup
if [ -f "/home/pi/$YESTERDAY" ]; then
  rm /home/pi/$YESTERDAY
fi

# Check Internet
if ! ping -q -c 1 -W 5 google.com >/dev/null; then

  # Internet connection down.
  echo "404 internet not found. Trying to fix for next run..."

  # Try to refresh connection for next time
  sudo iw dev wlan0 disconnect
  sudo iw dev wlan0 connect $SSID
  sleep 20
  sudo ifdown --force wlan0
  sudo ifup wlan0
  exit 1
fi

# Check if an instance of gdrive is already running
if pgrep -x "gdrive" >/dev/null; then
  echo "another instance of gdrive is running. skipping upload"
  exit 1
fi
  
# Check if we have the of the directory ID for today
if [ -f "/home/pi/$DATE" ]; then
  DIRECTORY_ID=$(</home/pi/$DATE)
  echo "found direcotry ID $DATE"

# No directory ID. Create new directory 
else
  echo "no daily directory found"
  DIRECTORY_ID=$(/home/pi/gdrive mkdir -p $PARENT_ID $DATE | awk {'print $2'})
  if [ -z $DIRECTORY_ID ]; then
    echo "gdrive directory creation failed"
    exit 1
  fi
  
  # Cache new directory ID as a file named by date
  echo $DIRECTORY_ID > /home/pi/$DATE
  echo "Created directory with ID $DIRECTORY_ID"
fi

# Upload current photo if a photo was passed as an argument
if [ $# -eq 1 ]; then
  TEMPFILE="/tmp/$1"
  if [ -f $TEMPFILE ]; then
    /home/pi/gdrive upload --delete -p $DIRECTORY_ID $TEMPFILE
    if [ $? -ne 0 ]; then
      echo "drive upload failed for $TEMPFILE"
      exit 1
    fi
  else
    # Photo file was passed as an argument but not found
    echo "passed photo was not found"
    exit 1
  fi
fi

# Upload any stored photos
for FILE in /home/pi/Pictures/*.jpg; do
  if [ -f $FILE ]; then
    /home/pi/gdrive upload --delete -p $DIRECTORY_ID $FILE
    if [ $? -ne 0 ]; then
      echo "drive upload failed for $FILE"
      exit 1
    fi
  fi
done

exit 0