#!/bin/bash
script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd $script_dir
cd src/kubernetes

kubectl delete -f .
kubectl delete secret lacework-api-key