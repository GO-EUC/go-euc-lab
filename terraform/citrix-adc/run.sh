terraform init &&
terraform apply --auto-approve -target="module._01_build" && sleep 5m && 
terraform apply --auto-approve -target="module._02_reset_password" && sleep 10s && 
terraform apply --auto-approve -target="module._03_license" && sleep 2m && 
terraform apply --auto-approve -target="module._04_base" && sleep 5s && 
terraform apply --auto-approve -target="module._05_ssl" && sleep 5s && 
terraform apply --auto-approve -target="module._06_lb" && sleep 5s && 
terraform apply --auto-approve -target="module._07_gw"