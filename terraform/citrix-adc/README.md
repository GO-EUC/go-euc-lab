![feature-image](/.assets/images/feature_image.png)

### Welcome to the GO-EUC lab Citrix ADC configuration repository. 

### This part of the repo is designed to get a standalone Citrix ADC up and running. The ADC does (for now) serve the following purpose
- Gateway for an OnPremises Citrix VAAD Environment

### Please note: this repository is a work in progress. The following tasks are considered ToDo:
- Upgrade to ADC 13.1 usage
- implement AAA

### HowTo Configure
You need to edit the following information to make this work in your environment
- ADC License: A valid ADC license needs to be put into the "./sources/license" folder
- ADC OVF: your ADC image sources need to be put into "./sources/image"
- provider.tf: review the required versions
- provider.tf: select either ACME staging or production certificates
- variables.tf: adjust all variables to represent your environemnt. Required ones are marked with a "# Comment".

### HowTo Deploy
- apply.sh: Due to runtime restrictions, for now the submodules of the terraform repo are adressed individually. The file "apply.sh" executes all modules and adds the required timeouts. The process will subsequently be altered to automatically match all runtime requirements.

### HowTo Delete
- destroy.sh: 