# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-9.5"

  config.vm.provider :virtualbox do |v|
    v.name = "pi-img-dev-box"
    #v.linked_clone = true
    v.cpus = "4"
    v.memory = "4096"
    v.customize ["modifyvm", :id, "--ioapic", "on"]
    v.customize ["modifyvm", :id, "--audio", "none"]
  end

  config.vm.hostname = "pi-img-dev-box"

  # Set the name of the VM. See: http://stackoverflow.com/a/17864388/100134
  config.vm.define :pi_img_dev_box do |pigen|
  end

  config.vm.provision :ansible_local do |ansible|
    ansible.install_mode = :pip
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "provisioning/playbook.yml"
  end
end

