#!/bin/sh
set -e

if [ -e /tmp/rc-local ]; then
	DBUS_RC_CONF_FILE=/etc/rc.conf.local
	VBOXGUEST_RC_CONF_FILE=/etc/rc.conf.local
	VBOXSERVICE_RC_CONF_FILE=/etc/rc.conf.local
	VMWARE_GUESTD_RC_CONF_FILE=/etc/rc.conf.local
	QEMU_AGENT_RC_CONF_FILE=/etc/rc.conf.local
elif [ -e /tmp/rc-vendor ]; then
	DBUS_RC_CONF_FILE=/etc/defaults/vendor.conf
	VBOXGUEST_RC_CONF_FILE=/etc/defaults/vendor.conf
	VBOXSERVICE_RC_CONF_FILE=/etc/defaults/vendor.conf
	VMWARE_GUESTD_RC_CONF_FILE=/etc/defaults/vendor.conf
	QEMU_AGENT_RC_CONF_FILE=/etc/defaults/vendor.conf
elif [ -e /tmp/rc-name ]; then
	DBUS_RC_CONF_FILE=/usr/local/etc/rc.conf.d/dbus
	VBOXGUEST_RC_CONF_FILE=/usr/local/etc/rc.conf.d/vboxguest
	VBOXSERVICE_RC_CONF_FILE=/usr/local/etc/rc.conf.d/vboxservice
	VMWARE_GUESTD_RC_CONF_FILE=/usr/local/etc/rc.conf.d/vmware_guestd
	QEMU_AGENT_RC_CONF_FILE=/usr/local/etc/rc.conf.d/qemu_agentd
	mkdir -p /usr/local/etc/rc.conf.d
else
	DBUS_RC_CONF_FILE=/etc/rc.conf
	VBOXGUEST_RC_CONF_FILE=/etc/rc.conf
	VBOXSERVICE_RC_CONF_FILE=/etc/rc.conf
	VMWARE_GUESTD_RC_CONF_FILE=/etc/rc.conf
	QEMU_AGENT_RC_CONF_FILE=/etc/rc.conf
fi

case "$PACKER_BUILDER_TYPE" in

	virtualbox-iso|virtualbox-ovf)
		pkg install -qy virtualbox-ose-additions-nox11

		sysrc -f "$DBUS_RC_CONF_FILE" dbus_enable=YES
		sysrc -f "$VBOXGUEST_RC_CONF_FILE" vboxguest_enable=YES
		sysrc -f "$VBOXSERVICE_RC_CONF_FILE" vboxservice_enable=YES

		cat >> /boot/loader.conf <<- END
		#VIRTUALBOX-BEGIN
		vboxdrv_load="YES"
		virtio_balloon_load="YES"
		virtio_blk_load="YES"
		virtio_scsi_load="YES"
		#VIRTUALBOX-END
		END
		;;

	vmware-iso|vmware-vmx)
		pkg install -qy open-vm-tools-nox11

		cat >> "$VMWARE_GUESTD_RC_CONF_FILE" <<- END
		vmware_guest_vmblock_enable="YES"
		vmware_guest_vmmemctl_enable="YES"
		vmware_guest_vmxnet_enable="YES"
		vmware_guestd_enable="YES"
		END
		;;

	parallels-iso|parallels-pvm)
		mkdir /tmp/parallels
		mount -o loop /root/prl-tools-lin.iso /tmp/parallels
		/tmp/parallels/install --install-unattended-with-deps
		umount /tmp/parallels
		rmdir /tmp/parallels
		rm /root/*.iso
		;;

	qemu)
		kldload virtio_console
		cat >> /boot/loader.conf <<- END
		virtio_console_load="YES"
		END

		pkg install -qy qemu-guest-agent
		cat >> "$QEMU_AGENT_RC_CONF_FILE" <<- END
		qemu_guest_agent_enable="YES"
		qemu_guest_agent_flags="-d -v -l /var/log/qemu-ga.log"
		END
		;;

	*)
		echo "Unknown Packer Builder Type >>$PACKER_BUILDER_TYPE<< selected."
		echo "Known types are virtualbox-iso|virtualbox-ovf|vmware-iso|vmware-vmx|parallels-iso|parallels-pvm|qemu."
		echo "Or set with PACKER_BUILDER_TYPE=\"qemu\" or other." 
		;;

esac
