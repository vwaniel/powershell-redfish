<#
	.SYNOPSIS
	Returns information about all of the chassis listed in /redfish/v1/Chassis.
	
	.DESCRIPTION
	Returns information about all of the chassis listed in /redfish/v1/Chassis.
	
	If run without parameters the cmdlet will attempt to get chassis information from all API connections that are stored in memory.
	
	.PARAMETER Tokens
	The connection object(s) created by Connect-RedfishAPI.  Multiple connection objects can be specified as an array.  This parameter accepts pipeline input.
	
	.EXAMPLE
	PS> Get-RedfishChassis
	
	Get chassis information from all API connections.
#>
function Get-RedfishChassis {
	[cmdletbinding()]
	param(
		[Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)][object[]]$Tokens
	)
	Begin {
		if ($Tokens) {
			$Tokens | Manage-RedfishCredentials
		} else {
			$Tokens = Manage-RedfishCredentials
		}
	}
	Process {
		foreach ($Token in $Tokens) {
			# Test for correct token object type.
			if ($Token -isnot [RedfishConnection]) {
				Write-Error "Input object was not of type [RedfishConnection]!"
				continue
			}
			Invoke-RedfishAPIRequest $Token "Get" "/redfish/v1/Chassis" | Foreach-Object {$_.Members."@odata.id"} | Foreach-Object {
				$obj = Invoke-RedfishAPIRequest $Token "Get" $_
				$objChassis = New-Object PSObject -Property @{
					"BMCController" = "$($Token.BMCController)"
					"ID" = $obj.Id;
					"Name" = $obj.Name;
					"ChassisType" = $obj.ChassisType;
					"Manufacturer" = $obj.Manufacturer;
					"Model" = $obj.Model;
					"SKU" = $obj.SKU;
					"SerialNumber" = $obj.SerialNumber;
					"PartNumber" = $obj.PartNumber;
					"AssetTag" = $obj.AssetTag;
					"IndicatorLED" = $obj.IndicatorLED;
					"State" = $obj.Status.State;
					"Health" = $obj.Status.Health
				} | Select "BMCController","ID","Name","ChassisType","Manufacturer","Model","SKU","SerialNumber","PartNumber","AssetTag","IndicatorLED","State","Health"
				$objChassis
			}
		}
	}
	End {
		
	}
}