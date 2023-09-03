echo "Initiating removal of NetScaler"
terraform init --upgrade &&
terraform destroy --auto-approve -target="module.adc-01-build" &&
echo "Cleaning NetScaler configuration..."
sleep 15s &&
rm .terraform.lock.hcl -f &&
rm terraform.tfstate.backup -f &&
rm terraform.tfstate -f &&
rm .terraform -f -r