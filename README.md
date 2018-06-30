# piWebHooksSignals & PiPowerOff
## Introduction

This application do two things
- the hardware provides a complete power on/off system, where the raspi can be powered by a battery powerpack and turns himself off after finishing his job. In off state the battery is completely disconnected, so there's no quiescent current which could drain the battery.
 - the software deamon  manages the LEDs and the poweroff. It's controlled by ascii commands received on port 3000.

## Details
The hardware power on is triggered by a short press on the button. When the raspi is going into power off state at the end, it pulls GPIO pin 22 to HIGH, which switches the hardware power off again. (In case of emergency, a longer press also switches the power off)
The sample application reads the `webhooks.cfg` and tries to fire all found webhooks out of the config, while it send ASCII status commands via TCP port 3000 to the LED & power control task. At the end the command EXIT makes the system to power off.

## Install

To install piWebHooksSignals, get a virgin raspian lite image from raspberry.org (tested on raspian stretch)
boot the virgin raspian image, login
start the install script with

    bash <(curl -s https://raw.githubusercontent.com/stko/piWebHooksSignals/master/install.sh)

the installation will take appr. 20 minutes.

After the installation you should adjust your settings before reboot, because after that your file system will be read only (which you can temporarily change with `sudo mount -o remount,rw /` then)

In case of the sample application, the settings would be the UMTS stick settings in `/etc/wvdial.conf` and the web hooks to call in `/etc/piWebHooksSignals/webhooks.cfg`

