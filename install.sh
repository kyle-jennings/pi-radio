#!/bin/bash

HOME=/home/pi
APP_HOME=$HOME/pi-radio
SYSTEMD_HOME=/etc/systemd/system
PI_RADIO_SERVICE=radio-player.service
BT_MANAGER_SERVICE=bluetooth-manager.service
USER=pi

echo PI Radio install starting...

cd $HOME
echo Updating OS and installing system dependencies...
sudo apt update

sudo apt install pulseudio pulseaudio-module-bluetooth mpg123

echo Starting Pulse Audio on boot
echo "pulseaudio --start" >> ~/.bashrc


echo installing $BT_MANAGER_SERVICE...
sudo cp $APP_HOME/services/$BT_MANAGER_SERVICE $SYSTEMD_HOME
sudo chmod 644 $SYSTEMD_HOME/$BT_MANAGER_SERVICE
sudo systemctl start $BT_MANAGER_SERVICE
sudo systemctl enable $BT_MANAGER_SERVICE

echo installing $PI_RADIO_SERVICE...
sudo cp $APP_HOME/services/$PI_RADIO_SERVICE $SYSTEMD_HOME
sudo chmod 644 $SYSTEMD_HOME/$PI_RADIO_SERVICE
sudo systemctl start $PI_RADIO_SERVICE
sudo systemctl enable $PI_RADIO_SERVICE

sudo systemctl daemon-reload

echo *************************************
echo Pi Radio install complete.
echo *************************************
echo *****Reboot to ensure all installed dependencies work as expected*****