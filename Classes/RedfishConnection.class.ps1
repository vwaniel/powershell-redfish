class RedfishConnection {
	[string]$BMCController
	[string]$BaseURL
	[int]$SessionID
	[securestring]$AuthToken
	[datetime]$DateTime = $(Get-Date)
	
	# Constructors
	RedfishConnection () {
	
	}
	
	RedfishConnection ([string]$str1, [string]$str2, [int]$int1, [string]$str3) {
		$this.BMCController = $str1
		$this.BaseURL = $str2
		$this.SessionID = $int1
		$this.AuthToken = $($str3 | ConvertTo-SecureString -AsPlainText -Force)
	}
}