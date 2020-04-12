function Invoke-RedfishAPIRequest {
	[cmdletbinding()]
	param(
		[Parameter(Mandatory=$true,Position=1)][object]$RedfishToken,
		[Parameter(Mandatory=$true,Position=2)][ValidateSet("Get","Delete")][string]$Method,
		[Parameter(Mandatory=$true,Position=3)][string]$URI
	)
	$netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])
	if ($netAssembly) {
		$bindingFlags = [Reflection.BindingFlags]"Static,GetProperty,NonPublic"
		$settingsType = $netAssembly.GetType("System.Net.Configuration.SettingsSectionInternal")
		$instance = $settingsType.InvokeMember("Section",$bindingFlags,$null,$null,@())
		if ($instance) {
			$bindingFlags = "NonPublic","Instance"
			$useUnsafeHeaderParsingField = $settingsType.GetField("useUnsafeHeaderParsing",$bindingFlags)
			if ($useUnsafeHeaderParsingField) {
				$useUnsafeHeaderParsingField.SetValue($instance,$true)
			}
		}
	}
	try {
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::TLS12
		[System.Net.ServicePointManager]::Expect100Continue = $false
		$request = [System.Net.WebRequest]::Create("$($RedfishToken.BaseURL)$($URI)")
		$request.Method = "$($Method.ToUpper())"
		$request.KeepAlive = $false
		$request.Headers.Add("X-Auth-Token","$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($RedfishToken.AuthToken))))")
		$response = ($request.GetResponse()).GetResponseStream()
		$streamReader = New-Object System.IO.StreamReader $response
		$json = $streamReader.ReadToEnd()
		$response.Close()
		Remove-Variable request
		[GC]::Collect()
		[GC]::WaitForPendingFinalizers()
		$obj = ConvertFrom-JSON $json
	}
	catch {
		throw "Unable to process $($Method) request for $($RedfishToken.BaseURL)$($URI).  $($_.Exception.Message)"
	}
	$obj
}