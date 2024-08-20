## AWS EKS Cluster

Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service that helps deploy, manage, and scale containerized applications using Kubernetes. EKS integrates with many AWS services to provide scalability and security for your applications.

### Design Decisions

- **Cluster Resources**: Managed using AWS IAM roles with specific policies for the EKS cluster and node groups. Dedicated roles and policies enhance security and ensure least privilege access.
- **Logging and Monitoring**: CloudWatch is used for logging the control plane activities, and Prometheus for cluster monitoring. Alarm modules are included to monitor critical conditions.
- **Networking**: Configured with VPC, subnets, and specific security group policies. Includes support for Fargate profiles for serverless Kubernetes workloads.
- **Add-ons**: Includes support for EBS CSI, EFS CSI, cert-manager, and external DNS for managing persistent storage and ingress traffic.
- **OIDC Integration**: The OIDC provider is set up to support IAM roles for service accounts, allowing fine-grained access controls for pods.

### Runbook

#### Issue: Node Group Not Scaling

Check if the node group is correctly configured and active.

```sh
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>
```

Expect the status to be `ACTIVE`. If not, review the configuration and ensure the IAM role is properly attached.

#### Issue: Unable to Access EKS Cluster

Check the authentication token and certificate authority data.

```sh
aws eks get-token --cluster-name <cluster-name> | jq -r .status.token

kubectl config view --minify | grep certificate-authority-data | awk '{print $2}' | base64 --decode
```

Ensure the token and certificate authority data match the EKS cluster configuration.

#### Issue: API Server Not Responding

Verify the EKS control plane is operational.

```sh
aws eks describe-cluster --name <cluster-name> --query 'cluster.status'
```

Expect the status to be `ACTIVE`. If not, review recent changes or AWS service statuses.

#### Issue: Kubernetes Pod Cannot Pull Images

Ensure the EKS node IAM role has sufficient permissions.

```sh
aws iam list-attached-role-policies --role-name <node-instance-role>
```

Check for `AmazonEC2ContainerRegistryReadOnly` policy and attach it if missing.

#### Issue: Ingress Controller Not Working Correctly

Check the Ingress controller logs.

```sh
kubectl logs -n <namespace> -l app.kubernetes.io/name=ingress-nginx
```

Review logs for errors related to service annotations or deployment issues.

#### Issue: External DNS Not Updating Records

Verify the External DNS logs and ensure correct IAM permissions.

```sh
kubectl logs -f -n md-core-services deployment/external-dns
```

Check for errors related to Route 53 and ensure the IAM role associated with External DNS has permissions for Route 53 actions.

#### Issue: Certificates Not Issuing

Check the cert-manager logs for diagnosing certificate issues.

```sh
kubectl describe certificate <cert-name> -n <namespace>
kubectl logs -n <namespace> deployment/cert-manager
```

Review logs for ACME challenges and solver configuration errors.

#### Issue: Volume Attachments Failing

Ensure CSI drivers are correctly deployed and check their logs.

```sh
kubectl logs -n kube-system -l app=ebs-csi-controller
kubectl logs -n kube-system -l app=efs-csi-controller
```

Look for errors related to volume provisioning and ensure the IAM roles have the necessary permissions for EBS and EFS.

