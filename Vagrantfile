# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

	module OS
	    def OS.windows?
	        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	    end

	    def OS.mac?
	        (/darwin/ =~ RUBY_PLATFORM) != nil
	    end

	    def OS.unix?
	        !OS.windows?
	    end

	    def OS.linux?
	        OS.unix? and not OS.mac?
	    end
	end
	# The most common configuration options are documented and commented below.
	# For a complete reference, please see the online documentation at
	# https://docs.vagrantup.com.

	# Every Vagrant development environment requires a box. You can search for
	# boxes at https://atlas.hashicorp.com/search.
	config.vm.box = "ubuntu/trusty64"

	# Disable automatic box update checking. If you disable this, then
	# boxes will only be checked for updates when the user runs
	# `vagrant box outdated`. This is not recommended.
	# config.vm.box_check_update = false

	# Create a private network, which allows host-only access to the machine
	# using a specific IP.
	# config.vm.network "private_network", ip: "192.168.33.10"

	# Create a public network, which generally matched to bridged network.
	# Bridged networks make the machine appear as another physical device on
	# your network.
	# config.vm.network "public_network"

	# Provider-specific configuration so you can fine-tune various
	# backing providers for Vagrant. These expose provider-specific options.
	# Example for VirtualBox:
	#
	config.vm.provider "virtualbox" do |vb|
		#	 vb.gui = true
		vb.memory = "1536"
		vb.cpus = 1
		 #move nat to the 172.20/16 subnet
		vb.customize ["modifyvm", :id, "--natnet1", "172.20/16"]

		if OS.mac?
			#port forwarding on the mac relies on the firewall taking requests on 80 -> 8080 where virtbox will pick up and route back down to 80 on the guest.
			config.vm.network "forwarded_port", guest: 80, host: 8080
			config.vm.network "forwarded_port", guest: 443, host: 8443

			config.vm.synced_folder "../", "/wwwroot", owner:"vagrant",group:"www-data", mount_options:["dmode=775,fmode=664"]

		elsif OS.windows?
			#port forwarding on windows is much more straight forward
			config.vm.network "forwarded_port", guest: 80, host: 80
			config.vm.network "forwarded_port", guest: 443, host: 443

			#this is me experimenting with nfs mount.  ATM, it seems like this isn't he bottleneck
			#private network needed for nfs file mount
			#config.vm.network "private_network", ip:"192.168.50.4"
			#config.vm.synced_folder "../", "/wwwroot", :nfs=>true , :mount_options => ['rw', 'vers=3', 'tcp', 'fsc' ,'actimeo=2']
			#config.vm.synced_folder "../", "/wwwroot", type: 'nfs',  nfs_udp: false, nfs_version: 3

			config.vm.synced_folder "../", "/wwwroot", owner:"vagrant",group:"www-data", mount_options:["dmode=775,fmode=664"]
		end
	end

	# Enable provisioning with a shell script. Additional provisioners such as
	# Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
	# documentation for more information about their specific syntax and use.
	config.vm.provision :shell,
	#if there a line that only consists of 'mesg n' in /root/.profile, replace it with 'tty -s && mesg n'
	:inline => "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error about stdin not being a tty. Fixing it now...') || exit 0;"

	config.vm.provision "shell", path: "bootstrap.sh"

	#fixing the sdin TTL issue
	config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

end
