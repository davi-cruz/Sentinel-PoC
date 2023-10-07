param(
    [int]$PRI = 0
)

if($PRI -eq 0){
    $PRI = Read-Host "Enter PRI: (Value between the angle brackets '< >')" -Default 0
}

$Facility = [math]::truncate($PRI/8)
$Severity = $PRI - ($Facility * 8)

$SeverityString = @"
Emergency: system is unusable
Alert: action must be taken immediately
Critical: critical conditions
Error: error conditions
Warning: warning conditions
Notice: normal but significant condition
Informational: informational messages
Debug: debug-level messages
"@.Split("`n")[$Severity]

$FacilityString = @"
kernel messages
user-level messages
mail system
system daemons
security/authorization messages (note 1)
messages generated internally by syslogd
line printer subsystem
network news subsystem
UUCP subsystem
clock daemon (note 2)
security/authorization messages (note 1)
FTP daemon
NTP subsystem
log audit (note 1)
log alert (note 1)
clock daemon (note 2)
local use 0  (local0)
local use 1  (local1)
local use 2  (local2)
local use 3  (local3)
local use 4  (local4)
local use 5  (local5)
local use 6  (local6)
local use 7  (local7)
"@.Split("`n")[$Facility]

Write-Output "Severity: $SeverityString"
Write-Output "Facility: $FacilityString"