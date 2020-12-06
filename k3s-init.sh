#!/usr/bin/env bash

mkdir -p /etc/k3s

# master node (server)
F=/home/vagrant/token
[[ -r $F ]] && mv -v $F /etc/k3s/token

# worker nodes
F=/vagrant/node-token
[[ -r $F ]] && cp -vf $F /home/k3s/token 

echo "INSTALL_K3S_EXEC='$INSTALL_K3S_EXEC'"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC:-}" sh -

# master node (server)
sleep 10
F=/var/lib/rancher/k3s/server/node-token
[[ -r $F ]] && cp -vf $F /vagrant
