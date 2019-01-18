$logfile = "C:\scripts\logme.txt"

function logme( $message ) {
    Write-Output "$(Get-TimeStamp): $message" | Out-file $logfile -append
}

$type = Get-Random -InputObject "DEV", "PROD", "QA"
$num  = Get-Random 5
$hostname = ConvertTo-Json @{hostname="$type$num"}
Write-Output $hostname

logme "Assigning ServerName $hostname"
