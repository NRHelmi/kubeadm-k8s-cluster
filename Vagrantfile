# -*- mode: ruby -*-
# vi: set ft=ruby :

LB_NODE_COUNT = 2
SERVER_NODE_COUNT = 3
WORKER_NODE_COUNT  = 2

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  (1..LB_NODE_COUNT).each() do |i|
    config.vm.define "haproxy-#{i}" do |haproxy|
      haproxy.vm.hostname = "haproxy-#{i}"
      haproxy.vm.network "private_network", ip: "192.168.56.1#{i}"
      haproxy.vm.provision :shell, path: "scripts/haproxy.sh"
      haproxy.vm.provider "virtualbox" do |v|
        v.name = "haproxy-#{i}"
        v.memory = 1024
        v.cpus = 2
      end
    end
  end

  (1..SERVER_NODE_COUNT).each() do |i|
    config.vm.define "server-#{i}" do |server|
      server.vm.hostname = "server-#{i}"
      server.vm.network "private_network", ip: "192.168.56.2#{i}"
      server.vm.provision :shell, path: "scripts/server.sh"
      server.vm.provider "virtualbox" do |v|
        v.name = "server-#{i}"
        v.memory = 2048
        v.cpus = 2
      end
    end
  end

  (1..WORKER_NODE_COUNT).each() do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.hostname = "worker-#{i}"
      worker.vm.network "private_network", ip: "192.168.56.3#{i}"
      worker.vm.provision :shell, path: "scripts/worker.sh"
      worker.vm.provider "virtualbox" do |v|
        v.name = "agent-#{i}"
        v.memory = 2048
        v.cpus = 2
      end
    end
  end
end
