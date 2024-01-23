# OpenTelemetry Connector for Lacework
Project for exposing metrics from Lacework using the [OpenTelemetry](https://opentelemetry.io/) project.

# Deployment Instructions
* Spin up and connect to a Kubernetes cluster
* In the Lacework UI, generate and download an API Key
* Deploy the integration, OpenTelemetry collector, Prometheus and Grafana using the following command:
  ```
  git clone https://github.com/lacework/opentelemetry
  cd opentelemetry
  helm upgrade --install \
        --set laceworkApiKey.account="youraccount.lacework.net" \
        --set laceworkApiKey.keyId="keyid" \
        --set laceworkApiKey.secret="secret" \
        open-telemetry lacework-opentelemetry
  ```
* The synchronization of data happens in batches every 30 minutes. Run the following command to start all batch jobs immediately:
  ```
  kubectl get cronjobs --no-headers -o custom-columns=":metadata.name" | xargs -I {} sh -c 'kubectl create job {}-$(date +%s) --from=cronjob/{}'
  ```
* Run the following command to open ports to communicate with OpenTelemetry Connector, Prometheus and Grafana:
  ```
  ./port-forward.sh
  Grafana: http://localhost:3000
  Prometheus: http://localhost:9090
  OpenTelemetry Collector Metrics: http://localhost:8888/metrics
  OpenTelemetry Collector oltp: http://localhost:4317
  OpenTelemetry Collector oltp http: http://localhost:4318
  ```

# How To Customize The Deployment
All Kubernetes deployment configurations are located in [src/kubernetes](src/kubernetes). If you need to reconfigure the OpenTelemetry connector, take a look at it's configuration [here](src/kubernetes/opentelemetry-collector.yaml).
