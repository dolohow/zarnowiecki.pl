---
title: "Local Multi-Node K3s Setup with Vagrant"
date: 2025-03-04T13:14:15+01:00
summary: A step-by-step guide to setting up a local multi-node K3s cluster using Vagrant and VirtualBox.
---

## Abstract
Recently, I needed to test a new K3s configuration. However, I didn't
want to do it on a production cluster. Therefore, I considered running
it locally while ensuring I had at least two nodes to properly test my
solution.

I figured out how to achieve this using Vagrant. While Vagrant seems to
be somewhat forgotten and feels almost obsolete these days, I still find
it quite useful.

## Vagrant
What is [Vagrant](https://en.wikipedia.org/wiki/Vagrant_%28software%29)?
It is a Ruby-based tool that allows for the programmatic setup of
virtual machines, primarily for development, using a `Vagrantfile`. It
supports several virtualization technologies, primarily
[VirtualBox](https://en.wikipedia.org/wiki/VirtualBox), which we will
use in this guide.

## Solution
First, ensure you have
[Vagrant](https://developer.hashicorp.com/vagrant/tutorials/get-started/install)
installed. You will also need a hypervisor. Today, we will focus on
[VirtualBox](https://www.virtualbox.org/wiki/Downloads), though
[libvirt](https://en.wikipedia.org/wiki/Libvirt) is also a viable
option. I will skip the installation steps for brevity since they vary
between operating systems and distributions. If you choose to use
`libvirt`, adjust the `provider` blocks in the examples accordingly.

Now, let's create a `Vagrantfile`. It starts with the following line:

```ruby
Vagrant.configure("2") do |config|
```

This configures Vagrant to use API version 2.

Next, let's define some constants. Feel free to modify them as needed:

```ruby
k3s_channel = "v1.30"
agent_count = 3
master_ip = "192.168.56.3"
```

### Master Node Configuration
Now, let's define the master node. Here, we configure the hostname,
network, and system resources. The memory and CPU values are the minimum
recommended by the K3s documentation:

```ruby
config.vm.define "master" do |master|
  master.vm.hostname = "master"
  master.vm.network "private_network", ip: master_ip
  master.vm.provider "virtualbox" do |vb|
    vb.name = "k3s-master"
    vb.memory = "2048"
    vb.cpus = 2
  end
```

Vagrant allows us to execute scripts during machine provisioning. Let's
take advantage of this functionality. One key detail is specifying the
network interface for flannel. This is important because Vagrant
provides `eth0` and `eth1` interfaces, but machines can only communicate
over the latter. The first is typically used for SSH access and internet
connectivity. I also chose `wireguard-native` as the flannel backend
since that's what I use in production, though it likely doesn’t make a
big difference.

```ruby
master.vm.provision "shell", inline: <<-SHELL
  sudo dnf update -y
  sudo dnf install -y curl vim

  # Install K3s (master node) with the specified channel
  curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=#{k3s_channel} sh -s - \
    --write-kubeconfig-mode=0664 \
    --write-kubeconfig-group=vagrant \
    --node-external-ip=#{master_ip} \
    --flannel-backend=wireguard-native \
    --flannel-iface=eth1

  # Get K3s token and save it for joining the agent
  sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s_token
SHELL
```

### Agent Nodes Configuration
Agent nodes follow a similar setup, but we wrap the configuration inside
a loop to create the desired number of machines dynamically.

```ruby
(1..agent_count).each do |i|
  agent_ip = "192.168.56.#{i + 3}"
  config.vm.define "agent#{i}" do |agent|
    agent.vm.hostname = "agent#{i}"
    agent.vm.network "private_network", ip: agent_ip
    agent.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-agent#{i}"
      vb.memory = "2048"
      vb.cpus = 2
    end
    agent.vm.provision "shell", inline: <<-SHELL
      sudo dnf update -y
      sudo dnf install -y curl

      curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=#{k3s_channel} K3S_URL=https://#{master_ip}:6443 K3S_TOKEN=$(cat /vagrant/k3s_token) sh -
    SHELL
  end
end
```

### Full `Vagrantfile`
Here is the complete `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "almalinux/9"

  k3s_channel = "v1.30"
  agent_count = 3
  master_ip = "192.168.56.3"

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: master_ip
    master.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-master"
      vb.memory = "2048"
      vb.cpus = 2
    end
    master.vm.provision "shell", inline: <<-SHELL
      sudo dnf update -y
      sudo dnf install -y curl vim

      # Install K3s (master node) with the specified channel
      curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=#{k3s_channel} sh -s - \
        --write-kubeconfig-mode=0664 \
        --write-kubeconfig-group=vagrant \
        --node-external-ip=#{master_ip} \
        --flannel-backend=wireguard-native \
        --flannel-iface=eth1

      # Get K3s token and save it for joining the agent
      sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s_token
    SHELL
  end

  (1..agent_count).each do |i|
    agent_ip = "192.168.56.#{i + 3}"
    config.vm.define "agent#{i}" do |agent|
      agent.vm.hostname = "agent#{i}"
      agent.vm.network "private_network", ip: agent_ip
      agent.vm.provider "virtualbox" do |vb|
        vb.name = "k3s-agent#{i}"
        vb.memory = "2048"
        vb.cpus = 2
      end
      agent.vm.provision "shell", inline: <<-SHELL
        sudo dnf update -y
        sudo dnf install -y curl

        curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=#{k3s_channel} K3S_URL=https://#{master_ip}:6443 K3S_TOKEN=$(cat /vagrant/k3s_token) sh -
      SHELL
    end
  end
end
```

Save this file in your chosen directory and run:

```bash
vagrant up
```

Wait for the process to complete. It may take some time as it runs
sequentially.

After setup, log into the master node:

```bash
vagrant ssh master
```

Then, verify that all nodes are connected:

```bash
kubectl get nodes
```

You should see output similar to:

```bash
NAME     STATUS   ROLES                  AGE     VERSION
agent1   Ready    <none>                 5m4s    v1.30.10+k3s1
agent2   Ready    <none>                 34s     v1.30.10+k3s1
master   Ready    control-plane,master   9m29s   v1.30.10+k3s1
```

Congratulations, now lets go and break something!

## Conclusion
Despite its aging ecosystem and occasional plugin issues, Vagrant remains a powerful tool for quickly provisioning development environments on demand. Its ability to create multiple machines makes it an excellent choice for testing network configurations, clusters, and other distributed setups.

