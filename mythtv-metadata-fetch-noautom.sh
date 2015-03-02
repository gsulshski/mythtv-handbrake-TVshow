#!/bin/sh

#  mythtv-metadata-fetch-noautom.sh
#  
#
#  Created by Gregory Ulsh on 2/8/14.
#  Updated to work with Mariadb 5.5 on 11/2/14
#       Changing mysql5 to mariadb
#       Change to new hard drive on 11/9/14
#
#  User Job for MythTV
#
#  Based on the Channel ID & Startime
#  Fetch the Title and SubTitle from mySQL db based on Channel ID and Starttime
#  Fetch from TTVDB the TV Show Metadata for the recorded show ->  xml
#
#  $1 = Channel Id of Recorded Program
#  $2 = Start Time of Recorded Prog
#, %CHANID%, %STARTTIMEUTC%
#
#   rename and move m4v file to a Plex Comopliant Naming Convention
#    chanid_starttime_NOC.mpg to Title -sxxeyy - subtitle  or
#                                Title -  20xx-mm-dd - subtitle  or
#                                Title - subtitle  or
#                                Title - YYYY-mm-dd
# Chanid = 1784
# Start_time = 20140120000000

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

# Cleanup Temporary data

rm *.txt
rm *.sql
cd "$TEMPDIR"
rmdir "$TEMPDIR"/mythtmp-$MYPID



exit 1
}


# path to MythTV transcoding tools

INSTALLPREFIX=/opt/local/bin
TTVDBPath=/opt/local/share/mythtv/metadata/Television
# MySQLPath=/opt/local/lib/mysql5/bin   (all other references are done without comments
MySQLPath=/opt/local/lib/mariadb/bin
MYTHTRANSCODE_DIR="/volumes/macintosh HD 2/Mythtv/transcode"
MYTHTVSHOW_DIR="/volumes/macintosh HD 2/Mythtv/default/TV Shows"

# Mac install directory for macport tools
# a temporary working directory (must be writable by mythtv user)

TEMPDIR="/volumes/macintosh HD 2/Mythtv/transcode"


# MySQL database login information (from mythconverg database)

DATABASEUSER="mythtv"
DATABASEPASSWORD="mythtv"
DATABASE="mythconverg"


# PID of this process. We'll create a working directory named with this ID
# This will allow for multiple recordings, fetch metadata

MYPID=$$
OUTDIR="/volumes/macintosh HD 2/Mythtv/Default"

# play nice with other processes, ionice not supported in OSX

renice 0 -p $MYPID


# make working dir, and enter working dir

mkdir "$TEMPDIR"/mythtmp-$MYPID
cd "$TEMPDIR"/mythtmp-$MYPID

# automator -D Title='Start Metadata Fetch' -D Subtitle=${PROGNAME} -D Message='Starting TVdb fetch or MySQL and move *.m4v file to Plex TV Shows' $MYTHTRANSCODE_DIR/'Display Notification.workflow'

#
#
# Fetch the  title  and subtitle by a simple query in the mySQL db
#
#


echo "SELECT CONCAT(title) FROM recorded WHERE basename='$1_$2.mpg';" > get-tv-title_$MYPID.sql

echo "SELECT CONCAT(subtitle) FROM recorded WHERE basename='$1_$2.mpg';" > get-tv-subtitle_$MYPID.sql

# echo "/opt/local/lib/mariadb/bin/mysql --user=$DATABASEUSER --password=$DATABASEPASSWORD $DATABASE <  get-tv-title_$MYPID.sql > title_$MYPID.txt"

/opt/local/lib/mariadb/bin/mysql --user=$DATABASEUSER --password=$DATABASEPASSWORD $DATABASE <  get-tv-title_$MYPID.sql > title_$MYPID.txt

/opt/local/lib/mariadb/bin/mysql --user=$DATABASEUSER --password=$DATABASEPASSWORD $DATABASE <  get-tv-subtitle_$MYPID.sql > subtitle_$MYPID.txt


# Extract the data from the second line from this query



TVTITLE=`sed -n '2,2p' title_$MYPID.txt`

# Extract out unwanted characters and form the Title Form

TVTITLE=`echo "$TVTITLE" | awk -F/ '{print $NF}' | sed 's/ /_/g' | sed 's/://g' | sed 's/?//g' | sed s/"'"/""/g | sed 's/,//g'`


TVSUBTITLE=`sed -n '2,2p' subtitle_$MYPID.txt`

# Extract out unwanted characters and form the Subtitle form

TVSUBTITLE=`echo "$TVSUBTITLE" | awk -F/ '{print $NF}' | sed 's/ /_/g' | sed 's/://g' | sed 's/?//g' | sed s/"'"/""/g | sed 's/,//g'`


# add recording start time if there is a blank subtitle
# only use the yyyymmdd and remove the remaining


if [ "$TVTITLE" == "" ]
then
error_exit  "TV_Recording_Not_Found"
fi

if [ "$TVSUBTITLE" == "" ]
then
TVSUBTITLE="${2:0:4}-${2:4:2}-${2:6:2}"
fi

# echo "tvtitle tvsubtitle"  $TVTITLE $TVSUBTITLE
#
#
# Get Metadata from TVdb for TV show (if exists)
#
#

# TTVdb.py parameters -N with  TVTITLE  and $2= TVSUBTITLE


# echo " tvtitle tvsubtitle" $TVTITLE $TVSUBTITLE

$TTVDBPath/ttvdb.py -N "$TVTITLE" "$TVSUBTITLE" > temp.xml

# Returns xml format of metadata from TVdb  ->  temp.xml



# Extract  Title , Subtitle, Season, Episode, Release Date and Inetref individiually

awk -F'[<|>]' '/title/ && $2 !~/subtitle/ {printf "%s\n",$3}' temp.xml > title.txt

awk -F'[<|>]' '/subtitle/ && $2 ~/subtitle/ {printf "%s\n",$3}' temp.xml > subtitle.txt

awk -F'[<|>]' '/season/ && $2 !~/dvdseason/ && $2 ~/season/{printf "%s\n",$3}' temp.xml > season.txt

awk -F'[<|>]' '/releasedate/ && $2 ~/releasedate/ {printf "%s\n",$3}' temp.xml > reldate.txt

awk -F'[<|>]' '/inetref/ && $2 ~/inetref/ {printf "%s\n",$3}' temp.xml > inetref.txt

awk -F'[<|>]' '/episode/ && $2 !~/dvdepisode/ && $2 ~/episode/ && $2 !~/episodes/ {printf "%s\n",$3}' temp.xml > episode.txt




# Save parsed data from fetched  XML data

Title=`sed -n '1,2p' title.txt`
Subtitle=`sed -n '1,2p' subtitle.txt`
Season=`sed -n '1,2p' season.txt`
Reldate=`sed -n '1,2p' reldate.txt`
Inetref=`sed -n '1,2p' inetref.txt`
Episode=`sed -n '1,2p' episode.txt`

# echo " title subtitle" $Title $Subtitle $Season $Reldate $Inetref $Episode


#  Build the New filename with the following forms:
#   If the XML Title is blank..then use the mysql  $TVTITLE - $TVSUBTITLE
#   (note: $TVSubtitle = the recording date and time if the subtitle is blank)
#   Else if
#         if  season is blank.. then Season=Reldate
#         if  episode is blank  then  use the  title - yyyy-mm-dd - subtitle form
#                 Else if
#                       Title - sxxeyy - subtitle form
#                  end if
#    end if



# Final_form="$TVTITLE-$TVSUBTITLE"

if [ "$Title" == "" ]
then
     Final_form="$TVTITLE - $TVSUBTITLE"
elif [ "$Season" ==  "" ]
then
    Season=$Reldate
elif [ "$Episode" == "" ]
then
    Final_form="$Title - $Reldate - $Subtitle"
else
   Final_form="$Title - s$Season""e$Episode - $Subtitle"
fi



# echo "final form" $Final_form


# Output   temp.xml ->  inetref.xml  and move it to default directory for now
# Rename commerically removed  mpeg to new form


if [ "$Title" == "" ]
then
   rm temp.xml
   Season="${2:0:4}"
else
   mv temp.xml "$OUTDIR"/$Inetref.xml
fi



# Move Transcoded x264 files to the TV shows directory structure
#      /TV Shows
#        /Title
#         /Season
#           Final_form.m4v


 ls "$MYTHTVSHOW_DIR" || error_exit "TV_Shows_directory_is_not_found"

if [ "$Title" == "" ]
then
  ls "$MYTHTVSHOW_DIR/$TVTITLE" ||  mkdir "$MYTHTVSHOW_DIR/$TVTITLE" || error_exit "TVTitle_Directory_not_created"
else
  ls "$MYTHTVSHOW_DIR/$Title" ||  mkdir "$MYTHTVSHOW_DIR/$Title" || error_exit "TV_Title_Directory_not_created"
fi

# Since Season has been fixed to be the year if not found in XML Data

if [ "$Title" == "" ]
then
 ls "$MYTHTVSHOW_DIR/$TVTITLE/$Season" ||  mkdir "$MYTHTVSHOW_DIR/$TVTITLE/$Season" || error_exit "TVT_Season_Directory_not_created"
else
 ls "$MYTHTVSHOW_DIR/$Title/Season $Season" ||  mkdir "$MYTHTVSHOW_DIR/$Title/Season $Season" || error_exit "TV_Season_Directory_not_created"
fi

# Currently writes over the recording

# Echo "TV Title Name"  "$MYTHTVSHOW_DIR/$TVTITLE/$Season/$Final_form.m4v"
# Echo "Title Name"  "$MYTHTVSHOW_DIR/$Title/Season $Season/$Final_form.m4v"

if [ "$Title" == "" ]
then
 mv "$OUTDIR/$1_$2_NOC.m4v" "$MYTHTVSHOW_DIR/$TVTITLE/$Season/$Final_form.m4v" || error_exit "Transcoded_M4v_TV_not_moved_to_final_destination"
else
 mv "$OUTDIR/$1_$2_NOC.m4v" "$MYTHTVSHOW_DIR/$Title/Season $Season/$Final_form.m4v" || error_exit "Transcoded_M4v_not_moved_to_final_destination"
fi




rm *.txt
rm *.sql
cd "$TEMPDIR"
rmdir "$TEMPDIR"/mythtmp-$MYPID

# automator -D Title='Completed Metadata Fetch' -D Subtitle=${PROGNAME} -D Message='Successfully Completed TVdb fetch or MySQL and move *.m4v file to Plex TV Shows' $MYTHTRANSCODE_DIR/'Display Notification.workflow'

