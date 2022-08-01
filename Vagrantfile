# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-11"

  config.vm.provider :vmware_desktop do |vmwd, override|
    vmwd.gui             = true
    vmwd.linked_clone    = true
    vmwd.vmx["memsize"]  = "4096"
    vmwd.vmx["numvcpus"] = "4"
    override.vm.synced_folder ".", "/vagrant"
    override.vagrant.plugins = ["vagrant-vmware-desktop"]
  end

  config.vm.provider :libvirt do |lv, override|
    override.vm.box = "debian/buster64"
    lv.cpus = "4"
    lv.memory = "4096"
    lv.machine_virtual_size = 40
  end

  config.vm.provision "shell", inline: <<-SCRIPT
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -qq python-pip python3-pip
  set +e
  SCRIPT

  config.vm.provision "ansible_local" do |ansible|
    ansible.install_mode = "pip"
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "provisioning/playbook.yml"
    ansible.extra_vars = {
      ansible_python_interpreter: "/usr/bin/python3"
    }
  end
end
