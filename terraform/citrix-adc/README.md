![feature-image](/.assets/images/feature_image.png)

### Welcome to the GO-EUC lab Citrix ADC configuration repository. 

### This part of the repo is designed to get a standalone Citrix ADC up and running. The ADC does (for now) serve the following purpose
- Gateway for an OnPremises Citrix VAAD Environment

### Please note: this repository is a work in progress. The following tasks are considered ToDo:
- implement AAA
- implement proper certificate process with LetsEncrypt
- configure ADC elemnts to use certificate

### HowTo
Due to runtime restrictions, for now the submodules of the terraform repo are adressed individually. The file "run.sh" executes all modules and adds the required timeouts. The process will subsequently be altered to automatically match all runtime requirements.