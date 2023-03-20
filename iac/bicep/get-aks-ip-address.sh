echo "get-aks-ip-address.sh arg1 is: $1"
ipResourceId=$1
echo "get-aks-ip-address.sh ipResourceId is: $ipResourceId" 

aksOutboundIP=$(az network public-ip show --ids $1 --query ipAddress  | tr -d "\\r\\n\"")
echo "aksOutboundIP=$aksOutboundIP"

jq -n --arg aksip "$(az network public-ip show --ids $ipResourceId --query ipAddress | tr -d "\\r\\n\"")" '{ "Result":"\($aksip)" }'  > $AZ_SCRIPTS_OUTPUT_PATH
# echo "{ \"Result\": \"$aksOutboundIP\" }" | jq -c . > $AZ_SCRIPTS_OUTPUT_PATH

# jq -c "{\\"Result\\": \\"$aksOutboundIP\\"}" > $AZ_SCRIPTS_OUTPUT_PATH'
