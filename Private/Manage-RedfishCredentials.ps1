function Manage-RedfishCredentials {
	[cmdletbinding()]
	param(
		[Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)][psobject]$objToken,
		[Parameter(Mandatory=$false)][string]$BaseURL,
		[Parameter(Mandatory=$false)][switch]$Remove
	)

	# Create a global variable to store Redfish API tokens.
	if (-NOT ($global:RedfishConnections)) {
		$global:RedfishConnections = [System.Collections.ArrayList]@()
	}

	if ($objToken) {
			# Test for correct token object type.
			if ($objToken -isnot [RedfishConnection]) {
				throw "Input object was not of type [RedfishConnection]!"
			}
		if ($Remove) {
			$token_match = $global:RedfishConnections | Where {$_.BaseURL -eq $objToken.BaseURL -and $_.SessionID -eq $objToken.SessionID}
			if ($token_match) {
				foreach ($_ in $token_match) {
					$global:RedfishConnections.Remove($_) > $null
				}
			}
		} else {
			# Check global token variable for tokens that match, and update date/time if any are found.
			$token_match = $global:RedfishConnections | Where {$_.BaseURL -eq $objToken.BaseURL -and $_.SessionID -eq $objToken.SessionID}
			if ($token_match) {
				foreach ($_ in $token_match) {
					$global:RedfishConnections[$global:RedfishConnections.IndexOf($_)] = $objToken
				}
			} else {
				$global:RedfishConnections.Add($objToken) > $null
			}
		}
	} else {
		if ($BaseURL) {
			return $($global:RedfishConnections | Where {$_.BaseURL -eq $BaseURL})
		} else {
			# Token was not provided, return global token variable.
			return $global:RedfishConnections
		}
	}
}