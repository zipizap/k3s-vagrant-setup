IP_SERVER = "192.168.99.20"
IP_WORKER = "192.168.99.3"
NUM_WORKERS=0
VM_NETWORK = "vboxnet1"


Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.cpus = 4
    #vb.memory = "2048"
    vb.memory = "8048"
  end
  config.vm.provision "file", source: "./token", destination: "~/token"
  config.vm.define "server" do |node|
    node.vm.hostname = "server"
    node.vm.network "private_network", ip: IP_SERVER, virtualbox__hostnet: VM_NETWORK, adapter: 2
    node.vm.provision "shell" do |s|
      the_INSTALL_K3S_EXEC='
  --disable traefik \
  --flannel-iface=enp0s8 \
  --node-ip ${NODE_IP} \
  --node-external-ip ${NODE_EXTERNAL_IP} \
  --node-name ${NODE_NAME} \
  --token-file /etc/k3s/token 
'
      s.env = {NODE_IP:IP_SERVER,NODE_EXTERNAL_IP:IP_SERVER,NODE_NAME:"server",INSTALL_K3S_EXEC:the_INSTALL_K3S_EXEC}
      s.path = "./k3s-server-init.sh"
    end
  end

  (1..NUM_WORKERS).each do |i|
    config.vm.define "worker#{i}" do |node|
      node.vm.hostname = "worker#{i}"
      node.vm.network "private_network", ip: "#{IP_WORKER}#{i}", virtualbox__hostnet: VM_NETWORK, adapter: 2
      node.vm.provision "shell" do |s|
        the_INSTALL_K3S_EXEC='
  --disable traefik \
  --server https://${SERVER_IP}:6443 \
  --flannel-iface=enp0s8 \
  --node-ip ${NODE_IP} \
  --node-external-ip ${NODE_EXTERNAL_IP} \
  --node-name ${NODE_NAME} \
  --token-file /etc/k3s/token 
'
        s.env = {NODE_IP:"#{IP_WORKER}#{i}",NODE_EXTERNAL_IP:"#{IP_WORKER}#{i}",NODE_NAME:"worker#{i}",SERVER_IP:IP_SERVER,INSTALL_K3S_EXEC:the_INSTALL_K3S_EXEC}
        s.path = "./k3s-agent-init.sh"
      end
    end
  end
end
