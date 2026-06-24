# -*- mode: ruby -*-
# vi: set ft=ruby :


# ============================================================================
# K3s cluster: 1 master + 1 agent
# Provider: VirtualBox
# Box: bento/ubuntu-24.04 (ships with guest additions preinstalled)
# ============================================================================

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"
  config.vm.box_check_update = false

  MASTER_IP = "192.168.56.10"
  AGENT_IP = "192.168.56.11"
  TOKEN_FILE = "/vagrant/.k3s-token"

  # --------------------------------------------------------------------------
  # Master node (control plane)
  # --------------------------------------------------------------------------
  config.vm.define "master-node" do |master|
    master.vm.hostname = "master-node"
    master.vm.network :private_network, ip: MASTER_IP
    master.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-master"
      vb.memory = "2048"
      vb.cpus = 2
    end

    master.vm.provision "shell",
      path: "scripts/k3s-master.sh",
      env: { "MASTER_IP" => MASTER_IP, "TOKEN_FILE" => TOKEN_FILE }
  end

  # --------------------------------------------------------------------------
  # Agent node (worker)
  # --------------------------------------------------------------------------
  config.vm.define "agent1-node" do |agent|
    agent.vm.hostname = "agent1-node"
    agent.vm.network :private_network, ip: AGENT_IP
    agent.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-agent"
      vb.memory = "2048"
      vb.cpus = 2
    end

    agent.vm.provision "shell",
      path: "scripts/k3s-agent.sh",
      env: { "MASTER_IP" => MASTER_IP, "TOKEN_FILE" => TOKEN_FILE }
  end
end
