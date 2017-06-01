workflow Start-VMsFromWebhook
{
 
    param ( 
        [object]$WebhookData
    )
 
    # If runbook was called from Webhook, WebhookData will not be null.
    if ($WebhookData -ne $null) {   
 
        # Collect properties of WebhookData
        $WebhookName    =   $WebhookData.WebhookName
        $WebhookHeaders =   $WebhookData.RequestHeader
        $WebhookBody    =   $WebhookData.RequestBody
 
        # Collect individual headers. VMList converted from JSON.
        $From = $WebhookHeaders.From
        $VMList = ConvertFrom-Json -InputObject $WebhookBody
        Write-Output "Runbook started from webhook $WebhookName by $From."
 
#====================START OF CONNECTION SETUP=======================
$connectionName = "AzureRunAsConnection"
$SubId = Get-AutomationVariable -Name 'AzureSubscriptionId'
try
{
   # Get the connection "AzureRunAsConnection "
   $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

   "Logging in to Azure..."
   Add-AzureRmAccount `
     -ServicePrincipal `
     -TenantId $servicePrincipalConnection.TenantId `
     -ApplicationId $servicePrincipalConnection.ApplicationId `
     -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
   "Setting context to a specific subscription"  
   Set-AzureRmContext -SubscriptionId $SubId             
}
catch {
    if (!$servicePrincipalConnection)
    {
       $ErrorMessage = "Connection $connectionName not found."
       throw $ErrorMessage
     } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
     }
     }
#====================END OF CONNECTION SETUP=======================

        # Start each virtual machine
        foreach ($VM in $VMList)
        {
            Write-Output "Starting $VM.Name."
            $VMObject = get-azureRMVM | ?{$_.Name -eq $VM.Name}
            $VMObject | Start-AzureRMVM
        }
    }
    else {
        Write-Error "Runbook meant to be started only from a webhook." 
    } 

}