param(    
    [Parameter(Mandatory=$false)] 
    [String] $ResourceGroupName
)

Write-Output $ResourceGroupName 

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

# If there is a specific resource group, then get all VMs in the resource group,
# otherwise get all VMs in the subscription.
if ($ResourceGroupName) 
{ 
    Write-Output "Resource Group specified: $($ResourceGroupName)"
	$VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
}
else 
{ 
    Write-Output "No Resource Group specified"
	$VMs = Get-AzureRmVM
}

# Stop each of the VMs
foreach ($VM in $VMs)
{
    Write-Output "Stopping VM: $($VM.Name)"
	$StopRtn = $VM | Stop-AzureRmVM -Force -ErrorAction Continue

	if ($StopRtn.IsSuccessStatusCode -ne $true)
	{
		# The VM failed to stop, so send notice
        Write-Output ($VM.Name + " failed to stop")
        Write-Error ($VM.Name + " failed to stop. Error was:") -ErrorAction Continue
		Write-Error (ConvertTo-Json $StopRtn.Error) -ErrorAction Continue
	}
	else
	{
		# The VM stopped, so send notice
		Write-Output ($VM.Name + " has been stopped")
	}
} 
