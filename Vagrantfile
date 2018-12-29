# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-9.5"

  config.vm.provider :virtualbox do |vb|
    vb.default_nic_type = "virtio"
    vb.linked_clone = true
    vb.cpus = "4"
    vb.memory = "4096"
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end

  config.vm.provider :libvirt do |lv, override|
    override.vm.box = "debian/stretch64"
    lv.cpus = "4"
    lv.memory = "4096"
    lv.machine_virtual_size = 40
  end

  config.vm.provision :ansible_local do |ansible|
    ansible.install_mode = :pip
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "provisioning/playbook.yml"
  end
end