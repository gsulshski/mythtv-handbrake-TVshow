  mythtv-handbrake-TVshow

Script that will remove commercials, X264 encode (apple tv3 preset) 

mythtv-comm-remov-x264-noautom.sh   %CHANID%, %STARTTIMEUTC%

      Generate a cutlist of the commercially flagged content from the recorded (mpeg-ts)  
      Transcode to mpeg-ps without commercials
      Transcode from mpeg-ps to m4v with Apple TV3 preset
           Updated on 11/9/14 to point to new hard drive
 
   $1 = Channel Id of Recorded Program 
   $2 - Start Time of Recorded Program
   $1 is passed with Mythtv variable %CHANID% , %STARTTIMEUTC%
    
     Output:  Chanid_Starttime_NOC.mpg replaces Chanid_Startime.mpg  and map file to Myth Default
              Chanid_Starttime_NOC.m4v file is created

Script to fetch TV show metadata and save in Plex/Kodi directory/filename conventions

   Based on the Channel ID & Startime
   Fetch the Title and SubTitle from mySQL db based on Channel ID and Starttime
   Fetch from TTVDB the TV Show Metadata for the recorded show ->  xml
 
   $1 = Channel Id of Recorded Program
   $2 = Start Time of Recorded Prog
   %CHANID%, %STARTTIMEUTC%
 
    rename and move m4v file to a Plex Compliant Naming Convention
     chanid_starttime_NOC.mpg to Title -sxxeyy - subtitle  or
                                 Title -  20xx-mm-dd - subtitle  or
                                 Title - subtitle  or
                                 Title - YYYY-mm-dd
     Directory will be created with the following formats
                               TV_Show_name/Season X/ or
                               TV_Show_name/20xx/ 



Prereq: 
OSX Mavericks and beyond ;
Mythtv 0.27.4 and beyond ;
A recorded TV Program ;
 Handbrake CLI 0.10 and beyond



