#!/bin/bash
script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd $script_dir
cd src/kubernetes

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: deploy.sh <lacework key id> <lacework secret> <lacework account, e.g. myaccount.lacework.net>"
    exit 1
fi

kubectl create secret generic lacework-api-key \
  --from-literal=lwKeyId=LWINTBVB_1C6D78E73AE77FD5E17D94B4A982EFD6438D38D9A8F612A \
  --from-literal=lwSecret=_56f0d8f4a4f28e1214384afc9c6cb2e0 \
  --from-literal=lwAccount=lwintbvboe.lacework.net

kubectl apply -f .
