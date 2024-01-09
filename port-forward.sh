kubectl port-forward service/grafana 3000:3000 & \
kubectl port-forward service/prometheus 9090:9090 & \
kubectl port-forward service/opentelemetry-collector 8888:8888 & \
kubectl port-forward service/opentelemetry-collector 4317:4317 & \
kubectl port-forward service/opentelemetry-collector 4318:4318 & \
echo "Grafana: http://localhost:3000" & \
echo "Prometheus: http://localhost:9090" & \
echo "OpenTelemetry Collector Metrics: http://localhost:8888/metrics" & \
echo "OpenTelemetry Collector oltp: http://localhost:4317" & \
echo "OpenTelemetry Collector oltp http: http://localhost:4318" & \

echo "Press CTRL-C to stop port forwarding and exit the script"
wait


