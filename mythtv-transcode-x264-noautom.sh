#!/bin/bash
#
#  User Job for MythTV
#
#     Transcode from mp3 (mpeg-ps or ts)  to mp4 container for Apple TV 3  
#
#  $1 = *_NOC.mpg file
#  #2 = Output file name
#    Output:  Output file name.m4v
#
Inputfile=$1
Outfilename=$1
#
PROGNAME=$(basename $0)

function error_exit
{

#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#          Uses Automator to send error to  Notification Center
#	----------------------------------------------------------------


# echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
echo "${PROGNAME}: ${1:-"Unknown Error"}"
# automator -D Title='MythTV Job Error'  -D Subtitle=${PROGNAME}   -D Message=${1:-"Unknown Error"}  $MYTHTRANSCODE_DIR/'Display Notification.workflow'


# move source file from transcode directory back to recording directory on error
mv $1_$2.mpg  $MYTHREC_DIR/


exit 1
}

MYTHTRANSCODE_DIR=/Mythtv/transcode
MYTHREC_DIR=/Mythtv/default
HANDBRAKE_DIR=/Applications



# PID of this process. We'll create a working directory named with this ID
MYPID=$$

# play nice with other processes  -10  Highest Priority    +10 Lowest Priority
renice 0 $MYPID

#  ionice -c 3 -p $MYPID  (don’t see this for OSX )


# Transcode using Handbrake from a mpeg-ps without commericals to a mp4 
# container that is friendly to  Apple devices and sufficient quality for  a # Home Theatre setup.

cd $MYTHTRANSCODE_DIR || error_exit "CD to the Transcode directory failed "

# automator -D Title='Start Handbrake x264 ' -D Subtitle=${PROGNAME} -D Message='Transcoding *NOC.mpg version to x264 *.m4v' $MYTHTRANSCODE_DIR/'Display Notification.workflow'


# $HANDBRAKE_DIR/HandBrakeCLI -i $MYTHREC_DIR/$Inputfile.mpg -o $Outfilename.mp4v -q 20.0 -r 30 --pfr  -a 1,1 -E faac,copy:ac3 -B 160,160 -6 dpl2,none -R Auto,Auto -D 0.0,0.0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 -f mp4 -4 -X 1280 -Y 720 --loose-anamorphic --modulus 2 -m --x264-preset medium --h264-profile high --h264-level 3.1 --large-file

$HANDBRAKE_DIR/HandBrakeCLI -i $MYTHREC_DIR/$1_$2_NOC.mpg -o $1_$2_NOC.m4v --preset="AppleTV 3" --large-file --decomb 7:2:6:9:1:80 ||  error_exit "Transcoding_to_x264_Failed"


# CleanUp

mv $1_$2_NOC.m4v  ../$MYTHREC_DIR  ||  error_exit "Moving transcoded X264 to Recording Directory Failed"


# automator -D Title='Handbrake x264 Completion' -D Subtitle=${PROGNAME} -D Message='Sucessfully x264 Transcode via Handbrake ' $MYTHTRANSCODE_DIR/'Display Notification.workflow'
