<#
	.SYNOPSIS
	Connect to the Redfish API on an out-of-band management controller.
	
	.DESCRIPTION
	Connect to the Redfish API on an out-of-band management controller.
	
	If the connection is successful, this cmdlet returns an object which contains connection information.  This object is also stored in memory, so the connection object does not have to be input to other cmdlets in this module.
	
	This cmdlet assumes that the out-of-band maangement controller has a signed certificate installed that is trusted by the computer running this module.
	
	.PARAMETER BMCControllers
	The hostname or IP address of the out-of-band management controller(s).  Multiple controllers may be specified as an array or a comma-separated list.  This parameter accepts pipeline input.
	
	.PARAMETER Username
	The username that will be used to authenticate to the out-of-band management controller.  If no username is specified the user will be prompted to provide a username and password.
	
	.PARAMETER Password
	The password that will be used to authenticate to the out-of-band management controller.  If a username is specified but no password is specified, the user will be prompted to enter the password.
	
	.PARAMETER Credential
	A pscredential object containing the credentials that will be used to authenticate to the out-of-band management controller.  If no credentials are specified the user will be prompted to enter a username and password.
	
	.EXAMPLE
	PS> "ipmi1.mgmt.example.com","ipmi2.mgmt.example.com" | Connect-RedfishAPI
	
	The user will be prompted to enter a username and password, and the cmdlet will attempt to authenticate to the Redfish API on ipmi1.mgmt.example.com and ipmi2.mgmt.example.com.
#>
function Connect-RedfishAPI {
	[cmdletbinding()]
	param(
		[Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)][string[]]$BMCControllers,
		[Parameter(Mandatory=$false)][string]$Username,
		[Parameter(Mandatory=$false)][string]$Password,
		[Parameter(Mandatory=$false)][pscredential]$Credential
	)
	Begin {
		if (!($Username) -and !($Password)) {
			if (!($Username) -and !($Password) -and $Credential -eq $null) {
				$Credential = $host.UI.PromptForCredential("Redfish API Credentials","Enter the credentials used to connect to the Redfish API.","","")
				if ($Credential) {
					$Username = $Credential.GetNetworkCredential().Username
					$Password = $Credential.GetNetworkCredential().Password
				}
			} elseif ($Credential -ne $null) {
				$Username = $Credential.GetNetworkCredential().Username
				$Password = $Credential.GetNetworkCredential().Password
			}
		} elseif (!($Username)) {
			Write-Error "Username cannot be null."
			break
		} elseif (!($Password)) {
			$Credential = $host.UI.PromptForCredential("Redfish API Credentials","Enter the credentials used to connect to the Redfish API.",$Username,"")
			if ($Credential) {
				$Username = $Credential.GetNetworkCredential().Username
				$Password = $Credential.GetNetworkCredential().Password
			} else {
				Write-Error "Password cannot be null."
			}
		}
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::TLS12
		[System.Net.ServicePointManager]::Expect100Continue = $false
	}
	Process {
		foreach ($BMCController in $BMCControllers) {
			if ($Username -and $Password) {
				try {
					$response = Invoke-WebRequest -Method POST -URI "https://$($BMCController)/redfish/v1/SessionService/Sessions" -Body $(ConvertTo-JSON @{"UserName"="$($Username)";"Password"="$($Password)"}) -ErrorAction "Stop"
				}
				catch {
					Write-Error "Unable to authenticate to Redfish API on $($BMCController).  $($_.Exception.Message)"
					break
				}
				$objToken = [RedfishConnection]::New($BMCController,"https://$($BMCController)",$(ConvertFrom-JSON $response.Content).Id,$response.Headers["X-Auth-Token"])
				Remove-Variable response
				[GC]::Collect()
				[GC]::WaitForPendingFinalizers()
				$objToken | Manage-RedfishCredentials
				$objToken
			}  else {
				Write-Error "Please enter valid credentials for $($BMCController)."
			}
		}
	}
	End {
		
	}
}