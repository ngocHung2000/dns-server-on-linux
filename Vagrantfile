# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Define the number of VMs to create
  num_vms = 2

  # Loop through the number of VMs and configure each one
  (1..num_vms).each do |i|
    config.vm.define "server#{i}" do |server|
      # Set the base box for the VM
      server.vm.box = "centos/8"

      # Set the hostname for the VM
      server.vm.hostname = "server#{i}"

      # Configure the network settings for the VM
      server.vm.network "private_network", ip: "10.10.0.#{i+10}"

      # Configure the provider (VirtualBox, in this case)
      server.vm.provider "virtualbox" do |vb|
        vb.name = "server#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
    end
  end
end