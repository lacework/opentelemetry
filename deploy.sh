#!/bin/bash
script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd $script_dir
cd src/kubernetes

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: deploy.sh <lacework key id> <lacework secret> <lacework account, e.g. myaccount.lacework.net>"
    exit 1
fi

kubectl create secret generic lacework-api-key \
  --from-literal=lwKeyId=$1 \
  --from-literal=lwSecret=$2 \
  --from-literal=lwAccount=$3

kubectl apply -f .

echo Waiting for pods to run
kubectl get pods --no-headers -o custom-columns=":metadata.name" | xargs -I {} kubectl wait --for=condition=ready pod {}

echo Triggering all jobs manually
kubectl get cronjobs --no-headers -o custom-columns=":metadata.name" | xargs -I {} sh -c 'kubectl create job {}-$(date +%s) --from=cronjob/{}'
