cluster.init:
	-cd src && terraform init
	-cd core-services && terraform init
	-cd custom-resources && terraform init

cluster.plan:
	-cd src && terraform plan
	-cd core-services && terraform plan
	-cd custom-resources && terraform plan

cluster.provision:
	-cd src && terraform apply -auto-approve
	-cd core-services && terraform apply -auto-approve
	-cd custom-resources && terraform apply -auto-approve

cluster.decomission:
	-cd custom-resources && terraform destroy -auto-approve
	-cd core-services && terraform destroy -auto-approve
	-cd src && terraform destroy -auto-approve
