git pull &&
terraform init -upgrade &&
terraform apply --auto-approve -target="module.adc-01-build" && 
terraform apply --auto-approve -target="module.adc-02-reset-password" && 
terraform apply --auto-approve -target="module.adc-03-license" && 
terraform apply --auto-approve -target="module.adc-04-base" && 
terraform apply --auto-approve -target="module.adc-05-ssl" && 
terraform apply --auto-approve -target="module.adc-06-letsencrypt-lb" && 
sudo terraform apply --auto-approve -target="module.adc-07-letsencrypt" && 
terraform destroy --auto-approve -target="module.adc-06-letsencrypt-lb" && 
terraform apply --auto-approve -target="module.adc-09-lb" && 
terraform apply --auto-approve -target="module.adc-10-gateway" && 
terraform apply --auto-approve -target="module.adc-11-cs" && 
terraform apply --auto-approve -target="module.adc-99-finish"