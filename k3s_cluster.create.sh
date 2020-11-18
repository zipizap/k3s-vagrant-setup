#!/usr/bin/env bash
# Paulo Aleixo Campos
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__dbg_on_off=on  # on off
function shw_info { echo -e '\033[1;34m'"$1"'\033[0m'; }
function error { echo "ERROR in ${1}"; exit 99; }
trap 'error $LINENO' ERR
function dbg { [[ "$__dbg_on_off" == "on" ]] || return; echo -e '\033[1;34m'"dbg $(date +%Y%m%d%H%M%S) ${BASH_LINENO[0]}\t: $@"'\033[0m';  }
#exec > >(tee -i /tmp/$(date +%Y%m%d%H%M%S.%N)__$(basename $0).log ) 2>&1
set -o errexit
  # NOTE: the "trap ... ERR" alreay stops execution at any error, even when above line is commente-out
set -o pipefail
set -o nounset
set -o xtrace

vagrant_up() {
  if [ ! -f ./token ]; then
    head -c 64 </dev/urandom | xxd -o off -ps -c 64 > token
  fi
  
  if [ ! -f ./id_rsa ]; then
    ssh-keygen -t rsa -f ./id_rsa -q -N ""
  fi
  
  vagrant up
}

  
setup_k3sYaml_kubeconfig() {
  IP_SERVER=$(vagrant ssh server -c "ip address show enp0s8 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//'" | tr -d "\n\r")
  export KUBECONFIG=$PWD/k3s.yaml
  
  rm -f "${KUBECONFIG}"
  
  vagrant ssh server -c "sudo cat /etc/rancher/k3s/k3s.yaml" \
    | sed -e "s/127.0.0.1/${IP_SERVER}/" > "${KUBECONFIG}"
  
  kubectl --kubeconfig="${KUBECONFIG}" get nodes
  kubectl get ingress,service,deploy,pods -A
}

helm_cleanup_repo_stable() {
  # Helm: add repo stable
  # Note: all charts in https://github.com/helm/charts/tree/master/stable
  if helm repo list | grep stable &>/dev/null
  then
    helm repo remove stable
  fi
  #helm repo add stable https://charts.helm.sh/stable &&\
  helm repo update
}

main__install_istio() {
  ## https://istio.io/latest/docs/setup/getting-started/
  # Download
  if [[ ! -d "${__dir}/istio-1.7.4" ]]
  then
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.7.4 TARGET_ARCH=x86_64 sh -
  fi

  local ISTIO_DIR=$(find $PWD -maxdepth 2 -type d -iname 'istio*')
  if [[ "${ISTIO_DIR}" ]];
  then
    # ISTIO_DIR found
    export PATH=$PATH:"${ISTIO_DIR}"/bin
  else
    echo "ISTIO_DIR not found... something went very wrong... aborting"
    exit 1
  fi
  cd "${ISTIO_DIR}"
  istioctl install --set profile=demo
  kubectl label namespace default istio-injection=enabled

  cd "${__dir}"
    # ATP: istioctl can be used (is in PATH)
}

helm_install_my-docker-registry_using_PVClocalPath() {
  # Optional: my-docker-registry 
  #  - via traefik-ingress, 
  #  - with persistent-storage on k3s "local-path"
  #helm \
  #  upgrade --install --atomic \
  #  my-docker-registry \
  #  stable/docker-registry \
  #  --values "${__dir}"/charts/docker-registry.values.yaml
  helm repo add twuni https://helm.twun.io
  helm \
    upgrade --install --atomic \
    my-docker-registry \
    twuni/docker-registry --version 1.9.6 \
    --values "${__dir}"/charts/docker-registry.values.yaml
}



main() {
  shw_info "== Vagrant'ing machines up =="
  vagrant_up
  shw_info "== Setup k3s.yaml and KUBECONFIG =="
  setup_k3sYaml_kubeconfig
    # ATP:
    #  - We have the k3s cluster setup and up-and-running :)
    #  - kubectl/helm can be used against k3s cluster
  shw_info "== Istio install =="
  main__install_istio 
    # ATP: istioctl can be used (is included in PATH)

  shw_info "== Helm: clean repo stable =="
  helm_cleanup_repo_stable
  shw_info "== Helm: my-docker-registry =="
  helm_install_my-docker-registry_using_PVClocalPath 

  kubectl get all,ingress -A
  shw_info "== Execution complete =="
  cat <<EOT
Manually do:
   
  # add k3smaster into /etc/hosts
  sudo vi /etc/hosts
  ...
  k3smaster $IP_SERVER

  # go happy hacking with the k3s cluster :)
  source ${__dir}/k3s.source
  kubectl get namespaces
  k get all,ingress,persistentvolumeclaims

EOT
}

main "${@}"

