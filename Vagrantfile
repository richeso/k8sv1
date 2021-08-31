# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Define the number of master and worker nodes
# If this number is changed, remember to update setup-hosts.sh script with the new hosts IP details in /etc/hosts of each VM.

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  # config.vm.box = "base"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Provision Master Nodes
 # Define the number of master and worker nodes
# If this number is changed, remember to update setup-hosts.sh script with the new hosts IP details in /etc/hosts of each VM.
# ------- Private IP Address Ranges are: ---------
#  10.0.0.0   to 10.255.255.255
# 172.16.0.0  to 172.31.255.255
# 192.168.0.0 to 192.168.255.255
# ------------------------------------------------
CLUSTER_NAME="K8SDEV1"
NUM_WORKER_NODE = 2
IPNETW = "192.168.56.1"
MASTER_IP=IPNETW+"0"
POD_CIDR="172.16.0.0"
CIDR_RANGE="16"
MASTER_NODE="kubem"
WORKER_NODE="knode"

Vagrant.configure("2") do |config|

 ## pass environment variables from vagrant invocation
 ## e.g. VAR1=123 VAR2=456 vagrant up

 ##   config.vm.provision "shell" do |s|
 ##       s.inline = "VAR1 is $1 and VAR2 is $2"
 ##       s.args   = "#{ENV['VAR1']} #{ENV['VAR2']}"
 ##   end

    config.vm.provision "shell",
        env: {
          "MASTER_IP" => MASTER_IP,
          "MASTER_NODE" => MASTER_NODE,
          "WORKER_NODE" => WORKER_NODE,
          "IPNETW" => IPNETW
        },
        inline: <<-SHELL
            apt-get update -y
            echo $MASTER_IP" "$MASTER_NODE >> /etc/hosts
            echo $IPNETW"1 "$WORKER_NODE"1" >> /etc/hosts
            echo $IPNETW"2 "$WORKER_NODE"2" >> /etc/hosts
            cp /vagrant/ssl/*.* /etc/ssl/certs
            cp /vagrant/ssl/*.* /usr/local/share/ca-certificates
            sudo update-ca-certificates --fresh
        SHELL
    
    config.vm.define MASTER_NODE do |master|
      master.vm.box = "ubuntu/bionic64"
      master.vm.hostname = MASTER_NODE
      master.vm.network "private_network", ip: MASTER_IP
      master.vm.provider "virtualbox" do |vb|
          vb.memory = 2048
          vb.cpus = 2
      end
      master.vm.provision "shell", path: "scripts/common.sh"
      master.vm.provision "shell", path: "scripts/master.sh", :args => [CLUSTER_NAME, MASTER_IP, POD_CIDR, CIDR_RANGE]
    end

# Provision Worker Nodes

    (1..NUM_WORKER_NODE).each do |i|
    config.vm.define WORKER_NODE+"#{i}" do |node|
      node.vm.box = "ubuntu/bionic64"
      node.vm.hostname = WORKER_NODE+"#{i}"
      node.vm.network "private_network", ip: IPNETW+"#{i}"
      node.vm.provider "virtualbox" do |vb|
          vb.memory = 1024
          vb.cpus = 1
      end
      node.vm.provision "shell", path: "scripts/common.sh"
      node.vm.provision "shell", path: "scripts/node.sh"
    end
    end
  end