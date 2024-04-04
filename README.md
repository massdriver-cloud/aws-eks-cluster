[![Massdriver][logo]][website]

# aws-eks-cluster

[![Release][release_shield]][release_url]
[![Contributors][contributors_shield]][contributors_url]
[![Forks][forks_shield]][forks_url]
[![Stargazers][stars_shield]][stars_url]
[![Issues][issues_shield]][issues_url]
[![MIT License][license_shield]][license_url]


Elastic Kubernetes Service is an open source container orchestration platform that automates many of the manual processes involved in deploying, managing, and scaling containerized applications.


---

## Design

For detailed information, check out our [Operator Guide](operator.mdx) for this bundle.

## Usage

Our bundles aren't intended to be used locally, outside of testing. Instead, our bundles are designed to be configured, connected, deployed and monitored in the [Massdriver][website] platform.

### What are Bundles?

Bundles are the basic building blocks of infrastructure, applications, and architectures in [Massdriver][website]. Read more [here](https://docs.massdriver.cloud/concepts/bundles).

## Bundle

### Params

Form input parameters for configuring a bundle for deployment.

<details>
<summary>View</summary>

<!-- PARAMS:START -->
## Properties

- **`core_services`** *(object)*: Configure core services in Kubernetes for Massdriver to manage.
  - **`enable_efs_csi`** *(boolean)*: Enabling this will install the AWS EFS storage controller into your cluster, allowing you to provision persistent volumes backed by EFS file systems. Default: `False`.
  - **`enable_ingress`** *(boolean)*: Enabling this will create an nginx ingress controller in the cluster, allowing internet traffic to flow into web accessible services within the cluster. Default: `False`.
  - **`route53_hosted_zones`** *(array)*: Route53 Hosted Zones to associate with this cluster. Enables Kubernetes to automatically manage DNS records and SSL certificates. Hosted Zones can be configured at https://app.massdriver.cloud/dns-zones. Default: `[]`.
    - **Items** *(string)*: .

      Examples:
      ```json
      "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
      ```

      ```json
      "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
      ```

- **`fargate`** *(object)*: AWS Fargate provides on-demand, right-sized compute capacity for running containers on EKS without managing node pools or clusters of EC2 instances.
  - **`enabled`** *(boolean)*: Enables EKS Fargate. Default: `False`.
- **`k8s_version`** *(string)*: The version of Kubernetes to run. Must be one of: `['1.22', '1.23', '1.24', '1.25', '1.26', '1.27']`. Default: `1.27`.
- **`monitoring`** *(object)*
  - **`control_plane_log_retention`** *(integer)*: Duration to retain control plane logs in AWS Cloudwatch (Note: control plane logs do not contain application or container logs). Default: `7`.
    - **One of**
      - 7 days
      - 30 days
      - 90 days
      - 180 days
      - 1 year
      - Never expire
  - **`prometheus`** *(object)*: Configuration settings for the Prometheus instances that are automatically installed into the cluster to provide monitoring capabilities".
    - **`grafana_enabled`** *(boolean)*: Install Grafana into the cluster to provide a metric visualizer. Default: `False`.
    - **`persistence_enabled`** *(boolean)*: This setting will enable persistence of Prometheus data via EBS volumes. However, in small clusters (less than 5 nodes) this can create problems of pod scheduling and placement due EBS volumes being zonally-locked, and thus should be disabled. Default: `True`.
- **`node_groups`** *(array)*
  - **Items** *(object)*: Definition of a node group.
    - **`advanced_configuration_enabled`** *(boolean)*: Default: `False`.
    - **`instance_type`** *(string)*: Instance type to use in the node group.
      - **One of**
        - C5 High-CPU Large (2 vCPUs, 4.0 GiB)
        - C5 High-CPU Extra Large (4 vCPUs, 8.0 GiB)
        - C5 High-CPU Double Extra Large (8 vCPUs, 16.0 GiB)
        - C5 High-CPU Quadruple Extra Large (16 vCPUs, 32.0 GiB)
        - C5 High-CPU 9xlarge (36 vCPUs, 72.0 GiB)
        - C5 High-CPU 12xlarge (48 vCPUs, 96.0 GiB)
        - C5 High-CPU 18xlarge (72 vCPUs, 144.0 GiB)
        - C5 High-CPU 24xlarge (96 vCPUs, 192.0 GiB)
        - M5 General Purpose Large (2 vCPUs, 8.0 GiB)
        - M5 General Purpose Extra Large (4 vCPUs, 16.0 GiB)
        - M5 General Purpose Double Extra Large (8 vCPUs, 32.0 GiB)
        - M5 General Purpose Quadruple Extra Large (16 vCPUs, 64.0 GiB)
        - M5 General Purpose Eight Extra Large (32 vCPUs, 128.0 GiB)
        - M5 General Purpose 12xlarge (48 vCPUs, 192.0 GiB)
        - M5 General Purpose 16xlarge (64 vCPUs, 256.0 GiB)
        - M5 General Purpose 24xlarge (96 vCPUs, 384.0 GiB)
        - T3 Small (2 vCPUs for a 4h 48m burst, 2.0 GiB)
        - T3 Medium (2 vCPUs for a 4h 48m burst, 4.0 GiB)
        - T3 Large (2 vCPUs for a 7h 12m burst, 8.0 GiB)
        - T3 Extra Large (4 vCPUs for a 9h 36m burst, 16.0 GiB)
        - T3 Double Extra Large (8 vCPUs for a 9h 36m burst, 32.0 GiB)
        - P2 General Purpose GPU Extra Large (4 vCPUs, 61.0 GiB)
        - P2 General Purpose GPU Eight Extra Large (32 vCPUs, 488.0 GiB)
        - P2 General Purpose GPU 16xlarge (64 vCPUs, 732.0 GiB)
    - **`max_size`** *(integer)*: Maximum number of instances in the node group. Minimum: `0`. Default: `10`.
    - **`min_size`** *(integer)*: Minimum number of instances in the node group. Minimum: `0`. Default: `1`.
    - **`name_suffix`** *(string)*: The name of the node group. Default: ``.
## Examples

  ```json
  {
      "__name": "Wizard",
      "core_services": {
          "enable_efs_csi": false,
          "enable_ingress": true,
          "route53_hosted_zones": []
      },
      "fargate": {
          "enabled": false
      },
      "k8s_version": "1.27",
      "monitoring": {
          "control_plane_log_retention": 7,
          "prometheus": {
              "grafana_enabled": false,
              "persistence_enabled": false
          }
      },
      "node_groups": [
          {
              "advanced_configuration_enabled": false,
              "instance_type": "t3.medium",
              "max_size": 10,
              "min_size": 1,
              "name_suffix": "shared"
          }
      ]
  }
  ```

  ```json
  {
      "__name": "Development",
      "k8s_version": "1.27",
      "monitoring": {
          "control_plane_log_retention": 7,
          "prometheus": {
              "grafana_enabled": false,
              "persistence_enabled": false
          }
      },
      "node_groups": [
          {
              "instance_type": "t3.medium",
              "max_size": 10,
              "min_size": 1,
              "name_suffix": "shared"
          }
      ]
  }
  ```

  ```json
  {
      "__name": "Production",
      "k8s_version": "1.27",
      "monitoring": {
          "control_plane_log_retention": 365,
          "prometheus": {
              "grafana_enabled": false,
              "persistence_enabled": true
          }
      },
      "node_groups": [
          {
              "instance_type": "c5.2xlarge",
              "max_size": 10,
              "min_size": 1,
              "name_suffix": "shared"
          }
      ]
  }
  ```

<!-- PARAMS:END -->

</details>

### Connections

Connections from other bundles that this bundle depends on.

<details>
<summary>View</summary>

<!-- CONNECTIONS:START -->
## Properties

- **`aws_authentication`** *(object)*: . Cannot contain additional properties.
  - **`data`** *(object)*
    - **`arn`** *(string)*: Amazon Resource Name.

      Examples:
      ```json
      "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
      ```

      ```json
      "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
      ```

    - **`external_id`** *(string)*: An external ID is a piece of data that can be passed to the AssumeRole API of the Security Token Service (STS). You can then use the external ID in the condition element in a role's trust policy, allowing the role to be assumed only when a certain value is present in the external ID.
  - **`specs`** *(object)*
    - **`aws`** *(object)*: .
      - **`region`** *(string)*: AWS Region to provision in.

        Examples:
        ```json
        "us-west-2"
        ```

- **`vpc`** *(object)*: . Cannot contain additional properties.
  - **`data`** *(object)*
    - **`infrastructure`** *(object)*
      - **`arn`** *(string)*: Amazon Resource Name.

        Examples:
        ```json
        "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
        ```

        ```json
        "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
        ```

      - **`cidr`** *(string)*

        Examples:
        ```json
        "10.100.0.0/16"
        ```

        ```json
        "192.24.12.0/22"
        ```

      - **`internal_subnets`** *(array)*
        - **Items** *(object)*: AWS VCP Subnet.
          - **`arn`** *(string)*: Amazon Resource Name.

            Examples:
            ```json
            "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
            ```

            ```json
            "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
            ```

          - **`aws_zone`** *(string)*: AWS Availability Zone.

            Examples:
          - **`cidr`** *(string)*

            Examples:
            ```json
            "10.100.0.0/16"
            ```

            ```json
            "192.24.12.0/22"
            ```


          Examples:
      - **`private_subnets`** *(array)*
        - **Items** *(object)*: AWS VCP Subnet.
          - **`arn`** *(string)*: Amazon Resource Name.

            Examples:
            ```json
            "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
            ```

            ```json
            "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
            ```

          - **`aws_zone`** *(string)*: AWS Availability Zone.

            Examples:
          - **`cidr`** *(string)*

            Examples:
            ```json
            "10.100.0.0/16"
            ```

            ```json
            "192.24.12.0/22"
            ```


          Examples:
      - **`public_subnets`** *(array)*
        - **Items** *(object)*: AWS VCP Subnet.
          - **`arn`** *(string)*: Amazon Resource Name.

            Examples:
            ```json
            "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
            ```

            ```json
            "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
            ```

          - **`aws_zone`** *(string)*: AWS Availability Zone.

            Examples:
          - **`cidr`** *(string)*

            Examples:
            ```json
            "10.100.0.0/16"
            ```

            ```json
            "192.24.12.0/22"
            ```


          Examples:
  - **`specs`** *(object)*
    - **`aws`** *(object)*: .
      - **`region`** *(string)*: AWS Region to provision in.

        Examples:
        ```json
        "us-west-2"
        ```

<!-- CONNECTIONS:END -->

</details>

### Artifacts

Resources created by this bundle that can be connected to other bundles.

<details>
<summary>View</summary>

<!-- ARTIFACTS:START -->
## Properties

- **`kubernetes_cluster`** *(object)*: Kubernetes cluster authentication and cloud-specific configuration. Cannot contain additional properties.
  - **`data`** *(object)*
    - **`authentication`** *(object)*
      - **`cluster`** *(object)*
        - **`certificate-authority-data`** *(string)*
        - **`server`** *(string)*
      - **`user`** *(object)*
        - **`token`** *(string)*
    - **`infrastructure`** *(object)*: Cloud specific Kubernetes configuration data.
      - **One of**
        - AWS EKS infrastructure config*object*: . Cannot contain additional properties.
          - **`arn`** *(string)*: Amazon Resource Name.

            Examples:
            ```json
            "arn:aws:rds::ACCOUNT_NUMBER:db/prod"
            ```

            ```json
            "arn:aws:ec2::ACCOUNT_NUMBER:vpc/vpc-foo"
            ```

          - **`oidc_issuer_url`** *(string)*: An HTTPS endpoint URL.

            Examples:
            ```json
            "https://example.com/some/path"
            ```

            ```json
            "https://massdriver.cloud"
            ```

        - Infrastructure Config*object*: Azure AKS Infrastructure Configuration. Cannot contain additional properties.
          - **`ari`** *(string)*: Azure Resource ID.

            Examples:
            ```json
            "/subscriptions/12345678-1234-1234-abcd-1234567890ab/resourceGroups/resource-group-name/providers/Microsoft.Network/virtualNetworks/network-name"
            ```

          - **`oidc_issuer_url`** *(string)*
        - GCP Infrastructure GRN*object*: Minimal GCP Infrastructure Config. Cannot contain additional properties.
          - **`grn`** *(string)*: GCP Resource Name (GRN).

            Examples:
            ```json
            "projects/my-project/global/networks/my-global-network"
            ```

            ```json
            "projects/my-project/regions/us-west2/subnetworks/my-subnetwork"
            ```

            ```json
            "projects/my-project/topics/my-pubsub-topic"
            ```

            ```json
            "projects/my-project/subscriptions/my-pubsub-subscription"
            ```

            ```json
            "projects/my-project/locations/us-west2/instances/my-redis-instance"
            ```

            ```json
            "projects/my-project/locations/us-west2/clusters/my-gke-cluster"
            ```

  - **`specs`** *(object)*
    - **`aws`** *(object)*: .
      - **`region`** *(string)*: AWS Region to provision in.

        Examples:
        ```json
        "us-west-2"
        ```

    - **`azure`** *(object)*: .
      - **`region`** *(string)*: Select the Azure region you'd like to provision your resources in.
    - **`gcp`** *(object)*: .
      - **`project`** *(string)*
      - **`region`** *(string)*: The GCP region to provision resources in.

        Examples:
        ```json
        "us-east1"
        ```

        ```json
        "us-east4"
        ```

        ```json
        "us-west1"
        ```

        ```json
        "us-west2"
        ```

        ```json
        "us-west3"
        ```

        ```json
        "us-west4"
        ```

        ```json
        "us-central1"
        ```

    - **`kubernetes`** *(object)*: Kubernetes distribution and version specifications.
      - **`cloud`** *(string)*: Must be one of: `['aws', 'gcp', 'azure']`.
      - **`distribution`** *(string)*: Must be one of: `['eks', 'gke', 'aks']`.
      - **`platform_version`** *(string)*
      - **`version`** *(string)*
<!-- ARTIFACTS:END -->

</details>

## Contributing

<!-- CONTRIBUTING:START -->

### Bug Reports & Feature Requests

Did we miss something? Please [submit an issue](https://github.com/massdriver-cloud/aws-eks-cluster/issues) to report any bugs or request additional features.

### Developing

**Note**: Massdriver bundles are intended to be tightly use-case scoped, intention-based, reusable pieces of IaC for use in the [Massdriver][website] platform. For this reason, major feature additions that broaden the scope of an existing bundle are likely to be rejected by the community.

Still want to get involved? First check out our [contribution guidelines](https://docs.massdriver.cloud/bundles/contributing).

### Fix or Fork

If your use-case isn't covered by this bundle, you can still get involved! Massdriver is designed to be an extensible platform. Fork this bundle, or [create your own bundle from scratch](https://docs.massdriver.cloud/bundles/development)!

<!-- CONTRIBUTING:END -->

## Connect

<!-- CONNECT:START -->

Questions? Concerns? Adulations? We'd love to hear from you!

Please connect with us!

[![Email][email_shield]][email_url]
[![GitHub][github_shield]][github_url]
[![LinkedIn][linkedin_shield]][linkedin_url]
[![Twitter][twitter_shield]][twitter_url]
[![YouTube][youtube_shield]][youtube_url]
[![Reddit][reddit_shield]][reddit_url]

<!-- markdownlint-disable -->

[logo]: https://raw.githubusercontent.com/massdriver-cloud/docs/main/static/img/logo-with-logotype-horizontal-400x110.svg
[docs]: https://docs.massdriver.cloud/?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=docs
[website]: https://www.massdriver.cloud/?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=website
[github]: https://github.com/massdriver-cloud?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=github
[slack]: https://massdriverworkspace.slack.com/?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=slack
[linkedin]: https://www.linkedin.com/company/massdriver/?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=linkedin



[contributors_shield]: https://img.shields.io/github/contributors/massdriver-cloud/aws-eks-cluster.svg?style=for-the-badge
[contributors_url]: https://github.com/massdriver-cloud/aws-eks-cluster/graphs/contributors
[forks_shield]: https://img.shields.io/github/forks/massdriver-cloud/aws-eks-cluster.svg?style=for-the-badge
[forks_url]: https://github.com/massdriver-cloud/aws-eks-cluster/network/members
[stars_shield]: https://img.shields.io/github/stars/massdriver-cloud/aws-eks-cluster.svg?style=for-the-badge
[stars_url]: https://github.com/massdriver-cloud/aws-eks-cluster/stargazers
[issues_shield]: https://img.shields.io/github/issues/massdriver-cloud/aws-eks-cluster.svg?style=for-the-badge
[issues_url]: https://github.com/massdriver-cloud/aws-eks-cluster/issues
[release_url]: https://github.com/massdriver-cloud/aws-eks-cluster/releases/latest
[release_shield]: https://img.shields.io/github/release/massdriver-cloud/aws-eks-cluster.svg?style=for-the-badge
[license_shield]: https://img.shields.io/github/license/massdriver-cloud/aws-eks-cluster.svg?style=for-the-badge
[license_url]: https://github.com/massdriver-cloud/aws-eks-cluster/blob/main/LICENSE


[email_url]: mailto:support@massdriver.cloud
[email_shield]: https://img.shields.io/badge/email-Massdriver-black.svg?style=for-the-badge&logo=mail.ru&color=000000
[github_url]: mailto:support@massdriver.cloud
[github_shield]: https://img.shields.io/badge/follow-Github-black.svg?style=for-the-badge&logo=github&color=181717
[linkedin_url]: https://linkedin.com/in/massdriver-cloud
[linkedin_shield]: https://img.shields.io/badge/follow-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&color=0A66C2
[twitter_url]: https://twitter.com/massdriver?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=twitter
[twitter_shield]: https://img.shields.io/badge/follow-Twitter-black.svg?style=for-the-badge&logo=twitter&color=1DA1F2
[discourse_url]: https://community.massdriver.cloud?utm_source=github&utm_medium=readme&utm_campaign=aws-eks-cluster&utm_content=discourse
[discourse_shield]: https://img.shields.io/badge/join-Discourse-black.svg?style=for-the-badge&logo=discourse&color=000000
[youtube_url]: https://www.youtube.com/channel/UCfj8P7MJcdlem2DJpvymtaQ
[youtube_shield]: https://img.shields.io/badge/subscribe-Youtube-black.svg?style=for-the-badge&logo=youtube&color=FF0000
[reddit_url]: https://www.reddit.com/r/massdriver
[reddit_shield]: https://img.shields.io/badge/subscribe-Reddit-black.svg?style=for-the-badge&logo=reddit&color=FF4500

<!-- markdownlint-restore -->

<!-- CONNECT:END -->
