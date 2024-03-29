# aws-eks-cluster
AWS EKS (Elastic Kubernetes Service) is Amazon's managed Kubernetes service, making it easy to deploy, operate, and scale containerized applications and providing benefits such as automatic scaling of worker nodes, automatic upgrades and patching, integration with other AWS services, and access to the Kubernetes community and ecosystem.

## Use Cases
### Container orchestration
Kubernetes is the most powerful container orchestrator, making it easy to deploy, scale, and manage containerized applications.
### Microservices architecture
Kubernetes can be used to build and manage microservices-based applications, allowing for flexibility and scalability in a distributed architecture.
### Big Data and Machine Learning
Kubernetes can be used to deploy and manage big data and machine learning workloads, providing scalability and flexibility for processing and analyzing large data sets.
### Internet of Things (IoT)
Kubernetes can be used to manage and orchestrate IoT applications, providing robust management and scaling capabilities for distributed IoT devices and gateways.

## Configuration Presets
### Development Cluster
This preset creates a cluster with a single node group of cost effective t3.medium instances.
### Production Cluster
This preset creates a cluster with a single node group of compute optimized c5.2xlarge instances.

## Design
EKS provides a "barebones" Kubernetes control plane, meaning that it only includes the essential components required to run a Kubernetes cluster. These components include the [Kubernetes API server](https://kubernetes.io/docs/concepts/overview/components/#kube-apiserver), [etcd](https://kubernetes.io/docs/concepts/overview/components/#etcd) (a distributed key-value store for storing Kubernetes cluster data), the [controller manager](https://kubernetes.io/docs/concepts/overview/components/#kube-controller-manager) and the [scheduler](https://kubernetes.io/docs/concepts/overview/components/#kube-scheduler).

In order simplify deploying and operating a Kubernetes cluster, this bundle includes numerous optional addons to deliver a fully capable and feature rich cluster that's ready for production workloads. Some of these addons are listed below.

### Cluster Autoscaler
A [cluster autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler) is installed into every EKS cluster to automatically scale the number of nodes in the cluster based on the current resource usage. This providers numerous benefits such as cost efficiency, higher availability and better resource utilization.
### NGINX Ingress Controller
Users can optionally install the ["official" Kubernetes NGINX ingress controller](https://kubernetes.github.io/ingress-nginx/) (not to be confused with [NGINX's own ingress controller](https://docs.nginx.com/nginx-ingress-controller/) based on the paid nGinx-plus) into their cluster, which allows workloads in your EKS cluster to be accessible from the internet.
### External-DNS and Cert-Manager
If users associate one or more Route53 domains to their EKS cluster, this bundle will automatically install [external-dns](https://github.com/kubernetes-sigs/external-dns) and [cert-manager](https://cert-manager.io/docs/) in the cluster, allowing the cluster to automatically create and manage DNS records and TLS certificates for internet accessible workloads.
### EBS CSI Driver
[Beginning in Kubernetes version 1.23, EKS no longer comes with the default EBS provisioner](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-1.23). In order to allow users to continue using the default `gp2` storage class, this bundle includes the [EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html), which replaces the deprecated EBS provisioner.
### EFS CSI Driver
Optionally, users can also install the [EFS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html) which will allow the EKS cluster to attach EFS volumes to cluster workloads for persistant storage. EFS volumes offer some benefits over EBS volumes, such as [allowing multiple pods to use the volume simultaneously (ReadWriteMany)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) and not being being locked to a single AWS availability zone, but these benefits come with higher storage costs and increased latency.

### Fargate

Fargate can be enabled to allow AWS to provide on-demand, right-sized compute capacity for running containers on EKS without managing node pools or clusters of EC2 instances.

For workloads that require high uptime, its recommended to keep some node pools populated even when enabling Fargate to ensure compute is always available during surges.

Fargate has many [limitations](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html).

Currently only `namespace` selectors are implemented. If you need `label` selectors please file an [issue](https://github.com/massdriver-cloud/aws-eks-cluster/issues).

## Best Practices
### Managed Node Groups
Worker nodes in the cluster are provisioned as [managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html).
### Secure Networking
Cluster is designed according to [AWS's EKS networking best practices](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html) including deploying nodes in private subnets and only deploying public load balancers into public subnets.
### Cluster Autoscaler
A cluster autoscaler is automatically installed to provide node autoscaling as workload demand increases.
### Open ID Connect (OIDC) Provider
Cluster is pre-configured for out-of-the box support of [IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).


## Security
### Nodes Deployed into Private Subnets
Worker nodes are provisioned into private subnets for security.
### IAM Roles for Service Accounts
IRSA allows kubernetes pods to assume AWS IAM Roles, removing the need for static credentials to access AWS services.
### Secret Encryption
An AWS KMS key is created and associated to the cluster to enable [encryption of secrets](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) at rest.
### IMDSv2 Required on Node Groups
The [Instance Metadata Service version 2 (IMDSv2)]() is required on all EKS node groups. IMDSv1, which was the cause of the [2019 CapitalOne data breach](https://divvycloud.com/capital-one-data-breach-anniversary/), is disabled on all node groups.

## Connecting
After you have deployed a Kubernetes cluster through Massdriver, you may want to interact with the cluster using the powerful [kubectl](https://kubernetes.io/docs/reference/kubectl/) command line tool.

### Install Kubectl

You will first need to install `kubectl` to interact with the kubernetes cluster. Installation instructions for Windows, Mac and Linux can be found [here](https://kubernetes.io/docs/tasks/tools/#kubectl).

Note: While `kubectl` generally has forwards and backwards compatibility of core capabilities, it is best if your `kubectl` client version is matched with your kubernetes cluster version. This ensures the best stability and compability for your client.


The standard way to manage connection and authentication details for kubernetes clusters is through a configuration file called a [`kubeconfig`](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file.

### Download the Kubeconfig File

The standard way to manage connection and authentication details for kubernetes clusters is through a configuration file called a [`kubeconfig`](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file. The `kubernetes-cluster` artifact that is created when you make a kubernetes cluster in Massdriver contains the basic information needed to create a `kubeconfig` file. Because of this, Massdriver makes it very easy for you to download a `kubeconfig` file that will allow you to use `kubectl` to query and administer your cluster.

To download a `kubeconfig` file for your cluster, navigate to the project and target where the kubernetes cluster is deployed and move the mouse so it hovers over the artifact connection port. This will pop a windows that allows you to download the artifact in raw JSON, or as a `kubeconfig` yaml. Select "Kube Config" from the drop down, and click the button. This will download the `kubeconfig` for the kubernetes cluster to your local system.

![Download Kubeconfig](https://github.com/massdriver-cloud/aws-eks-cluster/blob/main/images/kubeconfig-download.gif?raw=true)

### Use the Kubeconfig File

Once the `kubeconfig` file is downloaded, you can move it to your desired location. By default, `kubectl` will look for a file named `config` located in the `$HOME/.kube` directory. If you would like this to be your default configuration, you can rename and move the file to `$HOME/.kube/config`.

A single `kubeconfig` file can hold multiple cluster configurations, and you can select your desired cluster through the use of [`contexts`](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#context). Alternatively, you can have multiple `kubeconfig` files and select your desired file through the `KUBECONFIG` environment variable or the `--kubeconfig` flag in `kubectl`.

Once you've configured your environment properly, you should be able to run `kubectl` commands. Here are some commands to try:

```bash
# get a list of all pods in the current namespace
kubectl get pods

# get a list of all pods in the kube-system namespace
kubectl get pods --namespace kube-system

# get a list of all the namespaces
kubectl get namespaces

# view the logs of a running pod in the default namespace
kubectl logs <pod name> --namespace default

# describe the status of a deployment in the foo namespace
kubectl describe deployment <deployment name> --namespace foo

# get a list of all the resources the kubernetes cluster can manage
kubectl api-resources
```

## AWS Access

If you would like to manage access your EKS cluster through AWS IAM principals, you can do so via the `aws-auth` ConfigMap. This will allow the desired AWS IAM principals to view cluster status in the AWS console, as well as generate short-lived credentials for `kubectl` access. Refer to the [AWS documentation](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html) for more details.

**Note**: In order to connect to the EKS cluster to view or modify the `aws-auth` ConfigMap, you'll need to download the `kubeconfig` file and use `kubectl` as discussed earlier.
