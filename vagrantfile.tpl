# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version '>= 2.2.5'

Vagrant.configure(2) do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.disk_driver :bus => 'virtio-scsi', :cache => 'unsafe', :discard => 'unmap', :detect_zeroes => 'unmap'
    libvirt.machine_type = "q35"
    libvirt.disk_bus = "scsi"
  end
  config.vm.guest = :freebsd
end
