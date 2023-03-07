# AKS


In the [Bicep parameter file](./parameters-pre-req.json) :
- set your laptop/dev station IP adress to the field "clientIPAddress"
- Instead of putting a secure value (like a password) directly in your Bicep file or parameter file, you can retrieve the value from an Azure Key Vault during a deployment. When a module expects a string parameter with secure:true modifier, you can use the getSecret function to obtain a key vault secret. The value is never exposed because you only reference its key vault ID.


FYI, if you want to check the services available per locations :
```sh
az provider list --output table

az provider show -n  Microsoft.ContainerService --query  "resourceTypes[?resourceType == 'managedClusters']".locations | jq '.[0]' | jq 'length'

az provider show -n  Microsoft.RedHatOpenShift --query  "resourceTypes[?resourceType == 'OpenShiftClusters']".locations | jq '.[0]' | jq 'length’

az provider show -n  Microsoft.AppPlatform --query  "resourceTypes[?resourceType == 'Spring']".locations | jq '.[0]' | jq 'length'

az provider show -n  Microsoft.App --query  "resourceTypes[?resourceType == 'managedEnvironments']".locations | jq '.[0]' | jq 'length’
az provider show -n  Microsoft.App --query  "resourceTypes[?resourceType == 'connectedEnvironments']".locations | jq '.[0]' | jq 'length'

```


```sh
az group create --name rg-iac-kv33 --location westeurope
az group create --name rg-iac-aks-petclinic-mic-srv --location westeurope

#ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/bicep_key -C "youremail@groland.grd"
#cat ~/.ssh/bicep_key.pub

# az deployment group create --name iac-101-kv -f ./modules/kv/kv.bicep -g rg-iac-kv \
#    --parameters @./modules/kv/parameters-kv.json

# az deployment group create --name iac-101-pre-req -f ./pre-req.bicep -g rg-iac-aks-petclinic-mic-srv \
#    --parameters @./parameters-pre-req.json # --debug # --what-if to test like a dry-run

```

Note: you can Run a Bicep script to debug and output the results to Azure Storage, see :
-  [doc](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep#sample-bicep-files)
- [https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep)