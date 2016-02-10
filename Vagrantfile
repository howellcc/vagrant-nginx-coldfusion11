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
	config.vm.box_version = ">= 0"

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

	# Share an additional folder to the guest VM. The first argument is
	# the path on the host to the actual folder. The second argument is
	# the path on the guest to mount the folder. And the optional third
	# argument is a set of non-required options.
	#config.vm.synced_folder "../", "/wwwroot"

	# Provider-specific configuration so you can fine-tune various
	# backing providers for Vagrant. These expose provider-specific options.
	# Example for VirtualBox:
	#
	config.vm.provider "virtualbox" do |vb|
		#	 # Display the VirtualBox GUI when booting the machine
		#	 vb.gui = true
		#
		#	 # Customize the amount of memory on the VM:
		vb.memory = "1536"
		vb.cpus = 1
		 #move nat to the 172.20/16 subnet
		vb.customize ["modifyvm", :id, "--natnet1", "172.20/16"]

		# Create a forwarded port mapping which allows access to a specific port
		# within the machine from a port on the host machine. In the example below,
		# accessing "localhost:8080" will access port 80 on the guest machine.
		if OS.mac?
			config.vm.network "forwarded_port", guest: 80, host: 8080
			config.vm.network "forwarded_port", guest: 443, host: 8443

			config.vm.synced_folder "../", "/wwwroot"

		elsif OS.windows?
			config.vm.network "forwarded_port", guest: 80, host: 80
			config.vm.network "forwarded_port", guest: 443, host: 443

			#this is me experimenting with nfs mount.  ATM, it seems like this isn't he bottleneck
			#private network needed for nfs file mount
			#config.vm.network "private_network", ip:"192.168.50.4"
			#config.vm.synced_folder "../", "/wwwroot", :nfs=>true , :mount_options => ['rw', 'vers=3', 'tcp', 'fsc' ,'actimeo=2']

			config.vm.synced_folder "../", "/wwwroot"
		end
	end
	#
	# View the documentation for the provider you are using for more
	# information on available options.

	# Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
	# such as FTP and Heroku are also available. See the documentation at
	# https://docs.vagrantup.com/v2/push/atlas.html for more information.
	# config.push.define "atlas" do |push|
	#	 push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
	# end

	# Enable provisioning with a shell script. Additional provisioners such as
	# Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
	# documentation for more information about their specific syntax and use.
	config.vm.provision :shell,
	#if there a line that only consists of 'mesg n' in /root/.profile, replace it with 'tty -s && mesg n'
	:inline => "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error about stdin not being a tty. Fixing it now...') || exit 0;"

	config.vm.provision "shell", path: "bootstrap.sh"
	#config.vm.provision "shell", inline: <<-SHELL
	#	 sudo apt-get update
	#	 sudo apt-get install -y apache2
	# SHELL

	#fixing the sdin TTL issue
	config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

end
