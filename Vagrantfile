# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-10.2"

  config.vm.provider "virtualbox" do |vb|
    vb.default_nic_type = "virtio"
    vb.linked_clone = true
    vb.cpus = "4"
    vb.memory = "4096"
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end

  config.vm.provider "libvirt" do |lv, override|
    override.vm.box = "debian/buster64"
    lv.cpus = "4"
    lv.memory = "4096"
    lv.machine_virtual_size = 40
  end

  config.vm.provision "shell", inline: <<-SCRIPT
  set -e
  apt-get update
  apt-get install -qq python-pip python3-pip
  set +e
  SCRIPT

  config.vm.provision "ansible_local" do |ansible|
    ansible.install_mode = "pip"
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "provisioning/playbook.yml"
  end
end
