#!/bin/bash

#clear screen
clear

#display message to user

: <<'END_COMMENT'
Make sure you are on your ~/Desktop directory and that this file is also on that same directory before you run it.

You can also edit the system path to include the path where this file will recide in your system, therefore not requiring
you to have to change directory before running it.

Do as you wish
END_COMMENT

#reset tput handler
tput reset

#move to current user desktop
cd ~/Desktop

#make drive mount path structure if it does not already exists
mkdir -p ./usb-drive >/dev/null 2>&1


#delete previous code temp files if exissts
files_to_delete=("usbdrives.txt" "devpath.txt")

for file in "${files_to_delete[@]}"; do
  if [ -f "$file" ]; then
    rm "$file"
    echo "Files found and deleted: $file"
  fi
done


# list usb drives and save the result to a file
sudo blkid | grep ntfs |awk '{print $1}' | sed -E 's/(.{0,9}).*/\1/' >> ./usbdrives.txt

# Define the input file
INFILE=./usbdrives.txt

# Check that attached USB drives were found
if [[ -z $(grep '[^[:space:]]' $INFILE) ]] ; then
  echo "No USB drives found" 
  exit
else 
  #list number of drives found
  drivenums=$(wc -l ./usbdrives.txt | awk '{ print $1 }')
  echo $drivenums 'exterbnal drives were detected'

fi

#asks users how many external drivesa to mount
while :; do
    read -ep 'How many folders to create: ' number
    [[ $number =~ ^[[:digit:]]+$ ]] || continue
    (( ( (number=(10#$number)) <= 9999 ) && number >= 1 )) || continue
    
    break
done

#creates folder per each pf the selected disks
echo ''
echo 'Creating folders ...'
for a in `seq 1 $number` ; do mkdir ./usb-drive/disk${a} ; done

#display the found devi ce paths and save output to a text file to be used later in code
echo 'Listing external drives full path'
for d in ./usb-drive/* ; do [[ -d "$d" ]] && echo "$d" ; done 
for d in ./usb-drive/* ; do [[ -d "$d" ]] && echo "$d" ; done >> ./devpath.txt

#display list of devices found
echo 'We found the following drives:'
set -Ee    
test -e ${INFILE} || exit
while read -r line
do
    echo ${line}
done < ${INFILE}


#Read found device paths and mount point from our previous text files
dev1_path=`sed -n '1,1p' ./usbdrives.txt`
dev2_path=`sed -n '2,1p' ./usbdrives.txt`

disk1_mount_path=`sed -n '1,1p' ./devpath.txt`
disk2_mount_path=`sed -n '2,1p' ./devpath.txt`

#Now we'll mount each disk to its own path
sudo mount -t ntfs-3g $dev1_path $disk1_mount_path
sudo mount -t ntfs-3g $dev2_path $disk2_mount_path


#Allow user to press 'Q' to exit code and unmound drives
userinput=""
echo "Drive(s) mounted to: Desktop/usb-drive"
echo ""
tput blink; echo "Press [q] to unmount drive(s)"; tput sgr0
# read a single character
while read -r -n1 key
do
if [[ $key = "q" ]] || [[ $key = "Q" ]] 
then
break;
fi
# Add the key to the variable which is pressed by the user.
userinput+=$key
done
sudo umount -lf $dev1_path $dev2_path
tput reset
printf "\nusb drive unmounted successfully: $userinput\n"
