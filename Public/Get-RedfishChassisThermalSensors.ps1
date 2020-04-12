<#
	.SYNOPSIS
	Returns temperature sensor information from all of the chassis listed in /redfish/v1/Chassis (/redfish/v1/Chassis/<chassis>/Thermal).
	
	.DESCRIPTION
	Returns temperature sensor information from all of the chassis listed in /redfish/v1/Chassis (/redfish/v1/Chassis/<chassis>/Thermal).
	
	If run without parameters the cmdlet will attempt to get chassis information from all API connections that are stored in memory.
	
	.PARAMETER Tokens
	The connection object(s) created by Connect-RedfishAPI.  Multiple connection objects can be specified as an array.  This parameter accepts pipeline input.
	
	.EXAMPLE
	PS> Get-RedfishChassisThermalSensors
	
	Get thermal sensor information from all chassis in all API connections.
#>
function Get-RedfishChassisThermalSensors {
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
				$obj = Invoke-RedfishAPIRequest $Token "Get" "$($_)/Thermal"
				$objThermal = New-Object PSObject -Property @{
					"BMCController" = $Token.BMCController;
					"Chassis" = $($_ -replace "^\/redfish\/v1\/Chassis\/","");
					"Fans" = [System.Collections.ArrayList]@();
					"Sensors" = [System.Collections.ArrayList]@()
				} | Select "BMCController","Chassis","Fans","Sensors"
				$obj.Fans | Foreach-Object {
					$objThermal.Fans.Add($(
						New-Object PSObject -Property @{
							"Name" = $_.Name;
							"State" = $_.Status.State;
							"Health" = $_.Status.Health;
							"Units" = $_.ReadingUnits;
							"Reading" = $_.Reading
						} | Select "Name","State","Health","Units","Reading"
					)) > $null
				}
				$obj.Temperatures | Foreach-Object {
					$objThermal.Sensors.Add($(
						New-Object PSObject -Property @{
							"Name" = $_.Name;
							"Number" = $_.SensorNumber;
							"State" = $_.Status.State;
							"Health" = $_.Status.Health;
							"DegreesCelsius" = $_.ReadingCelsius
							"DegreesFahrenheit" = [Math]::Round($(($_.ReadingCelsius * (9/5)) + 32),1)
						} | Select "Name","Number","State","Health","DegreesCelsius","DegreesFahrenheit"
					)) > $null
				}
				$objThermal
			}
		}
	}
	End {
		
	}
}