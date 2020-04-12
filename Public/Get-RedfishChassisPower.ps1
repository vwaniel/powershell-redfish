<#
	.SYNOPSIS
	Returns power information from all of the chassis listed in /redfish/v1/Chassis (/redfish/v1/Chassis/<chassis>/Power).
	
	.DESCRIPTION
	Returns power information from all of the chassis listed in /redfish/v1/Chassis (/redfish/v1/Chassis/<chassis>/Power).
	
	If run without parameters the cmdlet will attempt to get chassis information from all API connections that are stored in memory.
	
	.PARAMETER Tokens
	The connection object(s) created by Connect-RedfishAPI.  Multiple connection objects can be specified as an array.  This parameter accepts pipeline input.
	
	.EXAMPLE
	PS> Get-RedfishChassisPower
	
	Get power information from all chassis from all API connections.
#>
function Get-RedfishChassisPower {
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
				$obj = Invoke-RedfishAPIRequest $Token "Get" "$($_)/Power"
				$objPower = New-Object PSObject -Property @{
					"BMCController" = $Token.BMCController;
					"Chassis" = $($_ -replace "^\/redfish\/v1\/Chassis\/","");
					"Voltages" = [System.Collections.ArrayList]@();
					"PowerSupplies" = [System.Collections.ArrayList]@();
					"PowerControl" = $(New-Object PSObject -Property @{
						"Name" = $obj.PowerControl.Name;
						"ID" = $obj.PowerControl.MemberID;
						"ConsumedWatts" = $obj.PowerControl.PowerConsumedWatts;
						"State" = $obj.PowerControl.Status.State;
						"Health" = $obj.PowerControl.Status.Health;
						"PowerMetricsIntervalMinutes" = $obj.PowerControl.PowerMetrics.IntervalInMin;
						"MinimumConsumedWatts" = $obj.PowerControl.PowerMetrics.MinConsumedWatts;
						"MaximumConsumedWatts" = $obj.PowerControl.PowerMetrics.MaxConsumedWatts;
						"AverageConsumedWatts" = $obj.PowerControl.PowerMetrics.AverageConsumedWatts;
					}) | Select "Name","ID","ConsumedWatts","State","Health","PowerMetricsIntervalMinutes","MinimumConsumedWatts","MaximumConsumedWatts","AverageConsumedWatts"
				} | Select "BMCController","Chassis","Voltages","PowerSupplies","PowerControl"
				$obj.Voltages | Foreach-Object {
					$objPower.Voltages.Add($(
						New-Object PSObject -Property @{
							"Name" = $_.Name;
							"ID" = $_.MemberID;
							"SensorNumber" = $_.SensorNumber;
							"State" = $_.Status.State;
							"Health" = $_.Status.Health;
							"Reading" = $_.ReadingVolts;
							"UpperThresholdNonCritical" = $_.UpperThresholdNonCritical;
							"UpperThresholdCritical" = $_.UpperThresholdCritical;
							"UpperThresholdFatal" = $_.UpperThresholdFatal;
							"LowerThresholdNonCritical" = $_.LowerThresholdNonCritical;
							"LowerThresholdCritical" = $_.LowerThresholdCritical;
							"LowerThresholdFatal" = $_.LowerThresholdFatal;
							"MinimumReadingRange" = $_.MinReadingRange;
							"MaximumReadingRange" = $_.MaxReadingRange
						} | Select "Name","ID","SensorNumber","State","Health","Reading","UpperThresholdNonCritical","UpperThresholdCritical","UpperThresholdFatal","LowerThresholdNonCritical","LowerThresholdCritical","LowerThresholdFatal","MinimumReadingRange","MaximumReadingRange"
					)) > $null
				}
				$obj.PowerSupplies | Foreach-Object {
					$objPower.PowerSupplies.Add($(
						New-Object PSObject -Property @{
							"Name" = $_.Name;
							"ID" = $_.MemberID;
							"State" = $_.Status.State
						} | Select "Name","ID","State"
					)) > $null
				}
				$objPower
			}
		}
	}
	End {
		
	}
}