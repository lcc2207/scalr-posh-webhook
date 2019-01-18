param (
       [Parameter(Mandatory=$True)]
       [string]$IPAddress,
       [Parameter(Mandatory=$True)]
       [string]$ServerName
)

$logfile = "C:\scripts\dns_register_log.txt"
$Zone = "test.me"
$DNSServer = "10.0.40.99"

function logme( $message ) {
    Write-Output "$(Get-TimeStamp): $message" | Out-file $logfile -append
}

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

function Get-ARecord($testName) {
    if ($(Resolve-DnsName "$testName" -NoHostsFile -Type A -server $DNSServer -ErrorAction SilentlyContinue)) {
        return $TRUE
    } else {
        return $TRUE
    }
}


function Add-ARecord($NewName, $NewIP) {
    try {
        Add-DnsServerResourceRecordA -Name $NewName -IPv4Address $NewIp -ZoneName $Zone -CreatePtr -AllowUpdateAny -ComputerName $DNSServer -ErrorAction Stop
        if (Get-DnsServerResourceRecord -ZoneName $Zone -Name $ServerName -ComputerName $DNSServer) {
            logme "DNS A record created successfully"
        } else {
            logme "DNS A record creation failure"
        }
    } catch {
        logme "Error while adding record:`n$($Error[0].Exception.Message)"
    }
}

function Get-PTRRecord($testIP) {
    if (Resolve-DnsName $testIP -NoHostsFile -Type PTR -ErrorAction SilentlyContinue) {
        return $TRUE
    } else {
        return $FALSE
    }
}

function Confirm-Unregistered ($testIp, $testName) {
    logme "Params: $testName  $testIp"
    try {
        logme "Checking for $testIp"
        $ptr = Resolve-DnsName  $testIp -NoHostsFile -Type PTR -ErrorAction SilentlyContinue
        logme "Error: PTR for $testIp already in DNS"
        return $FALSE
    } catch {
        # PTR Exception means host not in DNS so check for A record
        logme "$testIp not in DNS"
        logme "Checking for $testName"
        if (Resolve-DnsName $testName -NoHostsFile -Type A) {
            logme "Error: A record for $testName already in DNS"
            return $FALSE
        }
    }
    return $TRUE
}


logme "Running for IP $IPAddress, ServerName $ServerName"

if (Get-ARecord $ServerName) {
   logme "Error: A record for $ServerName already in DNS, skipping registration"
} else {
    logme "$ServerName is free to register"
    Add-ARecord $ServerName $IPAddress

}




#if (Get-PTRRecord $IPAddress) {
#    logme "Error: PTR for $IPAddress already in DNS"
#} else {
#    logme "$IPAddress is free to register in bind PTR"
#}
