TF_SOURCES=$(wildcard *.tf)
TF_VARS=$(wildcard *.tfvars)

terraform.tfstate: build/tf_init $(TF_SOURCES)
	terraform apply -auto-approve

tf_lint: build/tf_init
	terraform fmt -diff
	terraform validate

plan: build/tf_init #: Review a plan before applying it
	terraform plan

destroy: build/tf_init #: Destroy terraform infrastructure
	terraform destroy

build/tf_init: providers.tf build/.dir
	terraform init
	touch $@
