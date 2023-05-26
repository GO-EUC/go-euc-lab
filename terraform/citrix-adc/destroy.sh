terraform init --upgrade &&
terraform destroy --auto-approve -target="module.adc-01-build" &&
sleep 15s &&
rm /home/localadmin/GIT/deviceTRUST-democloud/environment/terraform/citrix-adc/.terraform.lock.hcl -f &&
rm /home/localadmin/GIT/deviceTRUST-democloud/environment/terraform/citrix-adc/terraform.tfstate.backup -f &&
rm /home/localadmin/GIT/deviceTRUST-democloud/environment/terraform/citrix-adc/terraform.tfstate -f &&
rm /home/localadmin/GIT/deviceTRUST-democloud/environment/terraform/citrix-adc/.terraform -f -r