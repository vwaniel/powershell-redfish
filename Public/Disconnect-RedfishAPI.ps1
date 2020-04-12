<#
	.SYNOPSIS
	Disconnect active connections to out-of-band management controllers running the Redfish API.
	
	.DESCRIPTION
	Disconnect active connections to out-of-band management controllers running the Redfish API.
	
	If no connection objects are provided, the cmdlet will disconnect from all API sessions that are stored in memory.
	
	.PARAMETER Tokens
	The connection object(s) created by Connect-RedfishAPI.  Multiple connection objects can be specified as an array.  This parameter accepts pipeline input.
	
	.EXAMPLE
	PS> Disconnect-RedfishAPI
	
	Disconnect from all Redfish API sessions that are stored in memory.
#>
function Disconnect-RedfishAPI {
	[cmdletbinding()]
	param(
		[Parameter(Mandatory=$false,ValueFromPipeline=$true)][object[]]$Tokens
	)
	Begin {
		if (!($Tokens)) {
			$Tokens = Manage-RedfishCredentials
		}
	}
	Process {
		foreach ($Token in $Tokens) {
			# Test for correct token object type.
			if ($Token -isnot [RedfishConnection]) {
				Write-Error "Input object was not of type [RedfishConnection]!"
			}
			try {
				Invoke-RedfishAPIRequest $Token "DELETE" "/redfish/v1/SessionService/Sessions/$($Token.SessionID)"
				$Token | Manage-RedfishCredentials -Remove
			}
			catch {
				Write-Error "Unable to log out of Redfish API on $($Token.BaseURL).  $($_.Exception.Message)"
			}
		}
	}
	End {
		
	}
}