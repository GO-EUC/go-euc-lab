terraform init &&
terraform destroy --auto-approve -target="module._01_build" &&
rm ./terraform.tfstate -f &&
rm ./terraform.tfstate.backup -f &&
rm ./.terraform.lock.hcl -f