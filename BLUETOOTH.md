Update Apt
$ sudo apt update

## Install Audio support

### Install pulseudio and pulseaudio-module-bluetooth
$ sudo apt install pulseudio pulseaudio-module-bluetooth 

ensure pulseaudio runs on start:
$ echo "pulseaudio --start" >> ~/.bashrc

### Add BT auto-connect scripts:
$ echo "wait" >> ~/.bashrc
$ echo "~/pi-radio/on.py" >> ~/.bashrc

## Pair a BT speaker:

$ bluetoothctl

You should get a different command prompt like:

[bluetooth]#

With your BT speaker on, type this:

[bluetooth]# scan on

[new] FC:58:FA:64:BA:38

[bluetooth]# info <speaker mac address>

[bluetooth]# pair <speaker mac address>

[bluetooth]# trust <speaker mac address>

[bluetooth]# quit

Script to auto-connect BT:
https://raspberrypi.stackexchange.com/questions/53408/automatically-connect-trusted-bluetooth-speaker