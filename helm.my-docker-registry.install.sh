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
export PS4='\[\e[44m\]\[\e[1;30m\](${BASH_SOURCE}:${LINENO}):${FUNCNAME[0]:+ ${FUNCNAME[0]}():}\[\e[m\]	'

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
  helm_install_my-docker-registry_using_PVClocalPath
}
main "${@}"
