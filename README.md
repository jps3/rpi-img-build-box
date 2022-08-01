# rpi-img-build-box

## Overview

This repo is used to create a customized Pi OS Lite build using [pi-gen](https://github.com/RPi-distro/pi-gen), with some additions (ex. salt-minion) as both NOOBS and standard `*.img` file.

Vagrant will use a Debian box on either VMware Fusion/Workstation or Linux’s libvirt, and provision using Ansible to prepare the VM with the packages and tools necessary to more easily use the pi-gen tools.

**NOTE:** The default provisioning and pi-gen customization is aimed toward building a 3DPrinterOS client.


## Considerations

1. It _really_ helps to have prior experience with Vagrant and virtual machines in general.
1. It _really_ helps to have command line experience with your host operating system.
1. It _really_ helps to have command line experience with Linux.
1. It helps to have some basic experience with Docker containers.


## Requirements

- VMware
  - [VMware Fusion](https://www.vmware.com/ca/products/fusion.html)
  - [VMware Workstation Pro](https://www.vmware.com/ca/products/workstation-pro.html)
  - Vagrant vmware Utility
    - [download](https://www.vagrantup.com/vmware/downloads)
    - [install](https://www.vagrantup.com/docs/providers/vmware/installation)
  - _(Considering supporting ESXi and/or vSphere)_
- [libvirt](https://libvirt.org/docs.html) _(tested on Ubuntu 18.04 host)_
- [Vagrant](https://www.vagrantup.com/docs/) ([download](https://www.vagrantup.com/downloads.html))

## Steps

1. Set your hypervisor of choice (VMware or libvirt)
1. Install Vagrant
1. `vagrant up`
1. `vagrant ssh`
1. `cd build/pi-gen`
1. Edit `config` file as needed.
1. Edit `config-luaml` as desired.
1. `./build-docker.sh`
