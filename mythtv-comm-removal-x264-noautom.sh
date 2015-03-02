#!/bin/bash
#
#  User Job for MythTV
#
#     Generate a cutlist of the commercially flagged content from the recorded (mpeg-ts)  
#     Transcode to mpeg-ps without commercials
#     Transcode from mpeg-ps to m4v with Apple TV3 preset
#          Updated on 11/9/14 to point to new hard drive
#
#  $1 = Channel Id of Recorded Program 
#  $2 - Start Time of Recorded Program
#  $1 is passed with Mythtv variable %CHANID% , %STARTTIMEUTC%
#   
#    Output:  Chanid_Starttime_NOC.mpg replaces Chanid_Startime.mpg  and map file to Myth Default
#             Chanid_Starttime_NOC.m4v file is created
#  PROGNAME holds the name of the program run
#
#  value from the first item on the command line ($0).

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


#
Chanid=$1
Start_time=$2  
MYTHREC_DIR="/volumes/macintosh\ HD\ 2/Mythtv/default"
MYTHTRANSCODE_DIR="/volumes/macintosh\ HD\ 2/Mythtv/transcode"
HANDBRAKE_DIR=/Applications

# Go to Myth Default Directory and move file to Transcode dir
echo $MYTHREC_DIR
echo cd $MYTHREC_DIR 
echo mv $MYTHREC_DIR/$1_$2.mpg $MYTHTRANSCODE_DIR/ 
eval cd "$MYTHREC_DIR" || error_exit "CD_to_Recording_Directory_Not_found"
eval mv $MYTHREC_DIR/$1_$2.mpg $MYTHTRANSCODE_DIR/ || error_exit "Moving_Source_MPEG_file_to_transcode_directory_failed"
eval cd $MYTHTRANSCODE_DIR || error_exit "CD_to_Transcode_Directory_Failed"

# automator -D Title='Start Commercial Removal Job' -D Subtitle=${PROGNAME} -D Message='Starting Cutlist, Transcode to MPEG to x264' $MYTHTRANSCODE_DIR/'Display Notification.workflow'

# PID of this process. We'll create a working directory named with this ID
MYPID=$$

# play nice with other processes..set at average ..  -10 is highest priority ...   +10  is lowest priority
renice 0 -p $MYPID

#  ionice -c 3 -p $MYPID  (don’t see this for OSX )


# Generate the cutlist for the recorded program based on running mythcommflag during recording


mythutil --gencutlist --chanid $Chanid --starttime $Start_time || error_exit  "Generating_Cutlist_Failed"

#   Get the cultist for the recorded program based on running mythutil  for input to the mythtranscode step

mythutil --getcutlist --chanid $Chanid --starttime $Start_time || error_exit  "Getting_Cutlist_Failed"


# Transcode the mpeg-ts to mpeg-ps while removing the commercial content from the cutlist


mythtranscode --mpeg2 --honorcutlist --showprogress -i $1_$2.mpg -o $1_$2_NOC.mpg || error_exit  "Transcoding_to_Remove_Commericals_Failed"

#  Transcode to x264 with Handbrake with Apple TV preset plus large-file and decomb settings


$HANDBRAKE_DIR/HandBrakeCLI -i $1_$2_NOC.mpg -o $1_$2_NOC.m4v --preset="AppleTV 3" --large-file --decomb 7:2:6:9:1:80 ||  error_exit  "Transcoding_to_x264_Failed"

# remmove the original recording and then replace it with the commercial free one

rm -f $1_$2.mpg || error_exit  "Removing_original_mpg_source"

mv $1_$2_NOC.mpg $1_$2.mpg || error_exit  "Replacing_mpg_transcode_commerical_source"
mv $1_$2_NOC.mpg.map $1_$2.mpg.map || error_exit  "Replacing_mpg_map_source"

#  Cleanup Files and move sorces files back  mpg (with commercials) and m4v (x264)


eval mv $1_$2*  $MYTHREC_DIR/ || error_exit  "Moving_Source_and_Transcoded_files_back_failed"



# Announce Completion of job

# automator -D Title='Commercial Removal Completion' -D Subtitle=${PROGNAME} -D Message='Sucessfully x264 Transcode to remove commercials' $MYTHTRANSCODE_DIR/'Display Notification.workflow'



