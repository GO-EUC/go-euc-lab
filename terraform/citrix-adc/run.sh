terraform init &&
terraform apply --auto-approve -target="module._01_build" && sleep 5m && 
terraform apply --auto-approve -target="module._02_reset_password" && sleep 10s && 
terraform apply --auto-approve -target="module._03_license" && sleep 2m && 
terraform apply --auto-approve -target="module._04_base" && sleep 5s &&
terraform apply --auto-approve -target="module._05_letsencrypt_lb" && sleep 5s &&  
sudo terraform apply --auto-approve -target="module._06_letsencrypt" && sleep 5s &&  
sudo terraform destroy --auto-approve -target="module._05_letsencrypt_lb" && sleep 5s &&
sudo terraform apply --auto-approve -target="module._07_ssl" && sleep 5s && 
sudo terraform apply --auto-approve -target="module._08_lb" && sleep 5s && 
sudo terraform apply --auto-approve -target="module._09_gw"

sfdsf