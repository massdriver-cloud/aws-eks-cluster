## AWS EKS (Elastic Kubernetes Service)

AWS EKS is a managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to manage your own Kubernetes control plane. Kubernetes is an open-source system for automating the deployment, scaling, and management of containerized applications.

### Design Decisions

1. **IAM Roles and Policies**: Distinct IAM roles for EKS cluster and node groups to ensure security and proper role-based access.
2. **Logging and Monitoring**: EKS control plane logs are sent to CloudWatch for centralized logging and monitoring.
3. **Add-ons**: Enabled multiple AWS EKS add-ons like EBS CSI, cluster autoscaler, and Prometheus observability.
4. **Cert-Manager and External-DNS**: Enabled cert-manager for certificate management and External-DNS for automated DNS updates.
5. **KMS Encryption**: Used AWS KMS for encrypting secrets within the EKS cluster.
6. **Fargate Support**: Conditional role creation for Fargate profile if Fargate is enabled.

### Runbook

#### Troubleshooting EKS Cluster Connectivity Issues

Kubernetes cluster endpoint might be unreachable. Verify the connectivity and authentication.

**Check Cluster Endpoint**

```sh
aws eks describe-cluster --name your-cluster-name --query "cluster.endpoint"
```
Ensure the endpoint is reachable from your network.

**Check Authentication Token**

```sh
aws eks get-token --cluster-name your-cluster-name
```
Verify that the token is generated without errors.

**Kubernetes API Server Logs**

```sh
kubectl logs -n kube-system $(kubectl get pods -n kube-system -l k8s-app=kube-apiserver -o name) -c kube-apiserver
```
This command aggregates logs from the API server for debugging potential issues.

#### Certificate Issues with Cert-Manager

Cert-Manager might fail to issue certificates due to misconfigurations or API rate limits.

**Check Cert-Manager Logs**

```sh
kubectl logs -n md-core-services -l app=cert-manager
```
Look for errors indicating why certificates might be failing.

**Validate ClusterIssuer**

```sh
kubectl describe clusterissuer letsencrypt-prod
```
Ensure that the ClusterIssuer configuration is correct and the ACME server is reachable.

#### DNS Resolution Problems with External-DNS

DNS records might fail to update in Route 53.

**Check External-DNS Logs**

```sh
kubectl logs -n md-core-services -l app=external-dns
```
Identify any error messages related to DNS updates or API limits.

**Verify Route 53 Hosted Zones**

```sh
aws route53 list-hosted-zones
```
Ensure that hosted zones' IDs and names match your Route 53 configuration.

#### EBS CSI Driver Storage Issues

Persistent Volumes may fail to provision or attach to nodes.

**Check EBS CSI Driver Logs**

```sh
kubectl logs -n kube-system -l app=ebs-csi-controller
```
Review logs to identify issues with volume provisioning or attachment.

**Manually Describe a Volume**

```sh
aws ec2 describe-volumes --volume-ids vol-xxxxxxx
```
Verify the status and details of the problematic volume directly.

#### Pod Scheduling Problems (Cluster Autoscaler)

Pods might remain in "Pending" state due to lack of resources or other scheduling issues.

**Check Cluster Autoscaler Logs**

```sh
kubectl logs -n kube-system -l app=cluster-autoscaler
```
Look for reasons why the autoscaler might not be scaling up nodes.

**Verify Node Resources**

```sh
kubectl describe node <node-name>
```
Check node capacity and allocations to identify resource issues.

#### Metrics and Monitoring Issues

Problems with collecting or visualizing metrics using Prometheus and Grafana.

**Check Prometheus Operator Logs**

```sh
kubectl logs -n md-observability -l app.kubernetes.io/name=prometheus-operator
```
Identify potential issues with Prometheus scraping or alerting configurations.

**Access Grafana UI**

```sh
kubectl port-forward svc/grafana -n md-observability 3000:3000
```
Verify that Grafana is accessible and that dashboards display the expected metrics.

By utilizing these runbook commands and tools, you can troubleshoot and manage your AWS EKS resources effectively.

