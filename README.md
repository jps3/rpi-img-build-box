# rpi-img-build-box

## Overview

Vagrantfile and related requirements to customize existing (Raspberry Pi) disk images, build Raspbian images from scratch, or cross-compile custom Linux kernel for ARM.

## Considerations

1. You really should have prior experience with setting up and running your own virtual machines.
1. You really should have command line experience with your host operating system.
1. You really should have command line experience with Linux.
1. It can be helpful to have experience with Docker if you choose to use the pi-gen `build-docker.sh` script.

## Requirements

- [Virtualbox](https://www.virtualbox.org/) ([download](https://www.virtualbox.org/wiki/Downloads))
	- _Other hypervisors will likely work fine, but this was developed and tested on Virtualbox._
- [Packer](https://www.packer.io/docs/) ([download](https://www.packer.io/downloads.html))
- [Vagrant](https://www.vagrantup.com/docs/) ([download](https://www.vagrantup.com/downloads.html))

## Steps

1. Install Virtualbox and the Extension Pack, or ensure they are current and up-to-date.
1. Install Packer.
1. Install Vagrant.
