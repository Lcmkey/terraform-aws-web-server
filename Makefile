init:
	terraform init

run:
	terraform apply --auto-approve

plan:
	terraform plan

destroy:
	terraform destroy --auto-approve

refresh:
	terraform refresh

list:
	terraform state list

output:
	terraform output