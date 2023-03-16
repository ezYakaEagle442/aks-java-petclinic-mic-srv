/*
If you need to purge KV: https://docs.microsoft.com/en-us/azure/key-vault/general/key-vault-recovery?tabs=azure-portal
The user will need the following permissions (at subscription level) to perform operations on soft-deleted vaults:
Microsoft.KeyVault/locations/deletedVaults/purge/action
*/

// https://argonsys.com/microsoft-cloud/library/dealing-with-deployment-blockers-with-bicep/

@description('A UNIQUE name')
@maxLength(21)
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('Secret Name.')
param secretName string

@description('Secret value')
@secure()
param secretValue string

// https://learn.microsoft.com/en-us/azure/key-vault/secrets/secrets-best-practices#secrets-rotation
// Because secrets are sensitive to leakage or exposure, it's important to rotate them often, at least every 60 days. 
@description('Expiry date in seconds since 1970-01-01T00:00:00Z. Ex: 1672444800 ==> 31/12/2022')
param secretExpiryDate int = 1703980800 // 31/12/2023

// https://en.wikipedia.org/wiki/ISO_8601#Durations
/* P is the duration designator (for period) placed at the start of the duration representation.
Y is the year designator that follows the value for the number of years.
M is the month designator that follows the value for the number of months.
W is the week designator that follows the value for the number of weeks.
D is the day designator that follows the value for the number of days.
*/
@description('KV The expiration time for the new key version. It should be in ISO8601 format. Eg: P90D, P1Y ')
param keyExpiryTime string = 'P1Y'

@description('The time duration before key expiring to rotate or notify. It will be in ISO 8601 duration format. Eg: P90D, P1Y')
param lifetimeActionTriggerBeforeExpiry string = 'P7D'

// DateA: 30/06/2022  00:00:00
// DateB: 30/06/2022  00:00:00
// =(DateB-DateA)*24*60*60
@description('The AKS SSH Keys stoted in KV / Expiry date in seconds since 1970-01-01T00:00:00Z')
param aksSshKeyExpirationDate int = 1703980800 // 31/12/2023

@description('the AKS cluster SSH key name')
param aksSshKeyName string = 'kv-ssh-keys-aks${appName}'

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: kvName
}

// https://docs.microsoft.com/en-us/azure/developer/github/github-key-vault
// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets?tabs=bicep

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  name: secretName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      // https://learn.microsoft.com/en-us/azure/key-vault/secrets/secrets-best-practices#secrets-rotation
      // Because secrets are sensitive to leakage or exposure, it's important to rotate them often, at least every 60 days. 
      // Expiry date in seconds since 1970-01-01T00:00:00Z.
      // 1672444800 ==> 31/12/2022
      exp: secretExpiryDate
    }
    contentType: 'text/plain'
    value: secretValue
  }
}

output kvSecretsId string = kvSecrets.id
output kvSecretsName string = kvSecrets.name

// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/keys?tabs=bicep
// https://docs.microsoft.com/en-us/azure/key-vault/keys/about-keys-details
/*
resource kvKeys 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  name: aksSshKeyName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      exp: aksSshKeyExpirationDate // Expiry date in seconds since 1970-01-01T00:00:00Z.
      exportable: true // Indicates if the private key can be exported. Exportable keys must have release policy.
      // nbf: int
    }
    keySize: 4096
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: keyExpiryTime
      }
      lifetimeActions: [
        {
          action: {
            type: 'notify'
          }
          trigger: { 
            // timeAfterCreate: 'string'
            timeBeforeExpiry: lifetimeActionTriggerBeforeExpiry
          }
        }
      ]
    }
    // https://github.com/Azure/azure-rest-api-specs/issues/17657
    // https://learn.microsoft.com/en-us/azure/key-vault/keys/policy-grammar
    // https://raw.githubusercontent.com/Azure/confidential-computing-cvm/main/cvm_deployment/key/skr-policy.json
    release_policy: {
      contentType: 'application/json; charset=utf-8' // https://learn.microsoft.com/en-us/rest/api/keyvault/keys/create-key/create-key?tabs=HTTP#keyreleasepolicy
      data: {
        'anyOf': [
          {
            'allOf': [
              {
                'claim': 'x-ms-attestation-type'
                'equals': 'sevsnpvm'
              }
              {
                'claim': 'x-ms-compliance-status'
                'equals': 'azure-compliant-cvm'
              }
            ]
            'authority': 'https://sharedeus.eus.attest.azure.net/'
          }
          {
            'allOf': [
              {
                'claim': 'x-ms-attestation-type'
                'equals': 'sevsnpvm'
              }
              {
                'claim': 'x-ms-compliance-status'
                'equals': 'azure-compliant-cvm'
              }
            ]
            'authority': 'https://sharedwus.wus.attest.azure.net/'
          }
          {
            'allOf': [
              {
                'claim': 'x-ms-attestation-type'
                'equals': 'sevsnpvm'
              }
              {
                'claim': 'x-ms-compliance-status'
                'equals': 'azure-compliant-cvm'
              }
            ]
            'authority': 'https://sharedneu.neu.attest.azure.net/'
          }
          {
            'allOf': [
              {
                'claim': 'x-ms-attestation-type'
                'equals': 'sevsnpvm'
              }
              {
                'claim': 'x-ms-compliance-status'
                'equals': 'azure-compliant-cvm'
              }
            ]
            'authority': 'https://sharedweu.weu.attest.azure.net/'
          }
        ]
      }
    }
  }
}
output keyUri string = kvKeys.properties.keyUri
*/
