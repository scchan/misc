#!/bin/bash

# Adapted from Erik Johnson's script at 
# http://terminalmage.net/2011/11/17/setting-a-usb-headset-as-the-default-pulseaudio-device/
#
# Updated by Edward Faulkner <ef@alum.mit.edu> to move existing
# streams and eliminate the extra fork script.

# You'll need to change these to point at your headset device.
#OUTPUT="alsa_output.usb-Generic_FREETALK_Everyman_0000000001-00-Everyman.analog-stereo"
#INPUT="alsa_input.usb-Generic_FREETALK_Everyman_0000000001-00-Everyman.analog-stereo"

OUTPUT="alsa_output.usb-Logitech_Logitech_USB_Headset-00-Headset.analog-stereo"
INPUT="alsa_input.usb-Logitech_Logitech_USB_Headset-00-Headset.analog-mono"

if [ "$1" == "--fork" ]; then
    # When run from udev, we fork to give pulseaudio a chance to
    # detect the new device
    bash $0 &
elif [ "$UID" == "0" ]; then
    # If we're running as root, we just forked from udev. Now sleep so
    # pulseaudio can run.
    sleep 1
 
    # Check process table for users running PulseAudio
    #
    for user in `ps axc -o user,command | grep pulseaudio | cut -f1 -d' ' | sort | uniq`;
    do
	# And relaunch ourselves for each of those users.
	su $user -c "bash $0"
    done
else
    # Running as non-root, so adjust our PulseAudio directly.
    pacmd set-default-sink $OUTPUT >/dev/null 2>&1
    pacmd set-default-source $INPUT >/dev/null 2>&1

    for playing in $(pacmd list-sink-inputs | awk '$1 == "index:" {print $2}')
    do
	pacmd move-sink-input $playing $OUTPUT >/dev/null 2>&1
    done

    for recording in $(pacmd list-source-outputs | awk '$1 == "index:" {print $2}')
    do
	pacmd move-source-output $recording $INPUT >/dev/null 2>&1
    done
fi

# Invoke from udev by creating a file like:
# /etc/udev/rules.d/85-usb-headset.rules
# Containing a rule like this (will need to be customized for your device):
#KERNEL=="card?", SUBSYSTEM=="sound", ATTR{id}=="Everyman", ACTION=="add", RUN+="/path/to/this/script/usb-headset --fork"
