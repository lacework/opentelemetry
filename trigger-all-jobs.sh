#!/bin/bash
kubectl get cronjobs --no-headers -o custom-columns=":metadata.name" | xargs -I {} sh -c 'kubectl create job {}-$(date +%s) --from=cronjob/{}'
