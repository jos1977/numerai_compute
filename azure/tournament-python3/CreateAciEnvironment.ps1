#Set Execution polict setting
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Push-Location $PSScriptRoot
Write-Host CurrentDirectory $CurDir

#Install Modules if doesn't exist yet
if (Get-Module -ListAvailable -Name Az.Resources) {
    Write-Host "Az.Resources Module exists"
} 
else {
    Write-Host "Az.Resources Module does not exist, installing"
    Install-Module -Name Az.Resources -Scope CurrentUser -Force
}
if (Get-Module -ListAvailable -Name Az.Accounts) { 
    Write-Host "Az.Accounts Module exists"
} 
else {
    Write-Host "Az.Accounts Module does not exist, installing"
    Install-Module -Name Az.Accounts -Scope CurrentUser -Force
}
if (Get-Module -ListAvailable -Name Az.LogicApp) { 
    Write-Host "Az.LogicApp Module exists"
} 
else {
    Write-Host "Az.LogicApp Module does not exist, installing"
    Install-Module -Name Az.LogicApp -Scope CurrentUser -Force
}
if (Get-Module -ListAvailable -Name Az.ContainerInstance) { 
    Write-Host "Az.ContainerInstance Module exists"
} 
else {
    Write-Host "Az.ContainerInstance Module does not exist, installing"
    Install-Module -Name Az.ContainerInstance -Scope CurrentUser -Force
}

Import-Module Az.Resources
Import-Module Az.ContainerInstance
Import-Module Az.LogicApp

#Connect to Azure Account
Connect-AzAccount

#Default variables
$overwriteOldSubmissions = "False"
$OSType="Linux"

#Read in variables
Write-Host "The following details are needed to provision the resources:"
$publicId = Read-Host "Please enter your Numerai Public Id (XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)"
$secretKey = Read-Host "Please enter your Numerai Secret Key (XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)"
$modelId = Read-Host "Please enter your Numerai Model Id Key (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"

$subscriptionId = Read-Host "Please enter your Azure subscription id (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
$location = Read-Host "Please enter the Azure Location (example eastus)"
$resourceGroupName = Read-Host "Please enter the Azure Resourcegroup Name"
$aciName = Read-Host "Please enter the Azure Container Instances Name"
$containerGroup_memoryInGB = Read-Host "Please enter the ACI Memory allocation (example: 2.5)"
$containerGroup_CPU = Read-Host "Please enter the ACI CPU allocation (example: 1)"

$dockerUri = "index.docker.io"
$dockerUserName = Read-Host "Please enter the Docker Hub Username"
$dockerPassword = Read-Host "Please enter the Docker Hub Password"
$image = Read-Host "Please enter the Docker Hub Image (example: user/name:latest)"


$logicapp_conn_aci_externalid = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.Web/connections/aci"
$logicapp_conn_path = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupname + "/providers/Microsoft.ContainerInstance/containerGroups/" + $aciName + "/start"

#Create resource group if it doesnt exist
Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    # ResourceGroup doesn't exist
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

#Create Azure Containers Instance, or update existing one
$aci = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
    -TemplateFile ".\arm\aci_template.json" `
    -TemplateParameterFile ".\arm\aci_parameters.json" `
    -containerGroups_name $aciName `
    -containerGroups_Image $image `
    -containerGroups_memoryInGB $containerGroup_memoryInGB`
    -containerGroups_Cpu $containerGroup_CPU `
    -containerGroups_overwriteOldSubmissions "False" `
    -containerGroups_publicId $publicId `
    -containerGroups_secretKey $secretKey `
    -containerGroups_modelId $modelId `
    -imageRegistry_Uri $dockerUri `
    -imageRegistry_Login $dockerUserName `
    -imageRegistry_Password $dockerPassword `
    -location $location

#Stop the ACI after deployment, or else it will already perform a run immediately
$cg = Get-AzContainerGroup -ResourceGroupName $resourceGroupName -Name $aciName 
Invoke-AzResourceAction -ResourceId $cg.Id -Action stop -Force

#Create Logic App, or update existing one
Write-Output "Create/Update API Connector"
$conn = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
    -TemplateFile ".\arm\conn_template.json" `
    -TemplateParameterFile ".\arm\conn_parameters.json" `
    -location $location `
    -subscription_id $subscriptionId

Write-Output "Create/Update Logic App"
$logicapp = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
    -TemplateFile ".\arm\logicapp_template.json" `
    -TemplateParameterFile ".\arm\logicapp_parameters.json" `
    -connections_aci_externalid $logicapp_conn_aci_externalid `
    -connections_path $logicapp_conn_path `
    -location $location `
    -resourceGroup_name $resourceGroupName `
    -aci_name $aciName `
    -subscription_id $subscriptionId

#Get Callback Url and report this to the user
Write-Output "Get Callback Url"
$callback = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroupName  -Name "startaci" -TriggerName "request"

Write-Output "Use the following webhook url in numerai to trigger the Logic App (and in turn triggers the Azure Container Instance):"
Write-Output $callback.Value