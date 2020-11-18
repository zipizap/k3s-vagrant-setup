#!/usr/bin/env bash

mkdir -p /etc/k3s
mv /home/vagrant/token /etc/k3s/

echo "INSTALL_K3S_EXEC='$INSTALL_K3S_EXEC'"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC:-}" sh -
