$localAddress = '192.168.178.188'    # the IP address of your openDTU
$username = 'admin'
$password = 'openDTU42'

$powerLimit = 800   # in watts - this is the target output limit

$upperLimit = 100   # in percent - the upper limit
$lowerLimit = 49    # in percent - the lower limit

$reactivityTime = 2 # in seconds

function getInverterData($localAddress) {
    $apiURL = 'http://' + $localAddress + '/api/livedata/status'
    $res = Invoke-WebRequest -Uri $apiURL -Headers @{'Accept' = 'application/json'}

    $content = $res.Content | ConvertFrom-Json

    return @{
        "inverterSerial" = $content.inverters.serial
        "currentPower" = [int]$content.total.Power.v
        "currentLimit" = [int]$content.inverters.limit_relative
    }
}

function setNewLimit($localAddress, $basicAuth, $inverterSerial, $newLimit) {
    Write-Host " | setting limit to $newLimit% " -NoNewline

    $headers = @{
        'Authorization' = "Basic {0}" -f $basicAuth
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    $body = 'data={"serial":"' + $inverterSerial + '", "limit_type":1, "limit_value":' + $newLimit + '}'

    $apiURL = 'http://' + $localAddress + '/api/limit/config'
    $null = Invoke-WebRequest -Uri $apiURL -Headers $headers -Body $body -Method Post

    while ($true) {
        Start-Sleep -Seconds 1  # wait one second between API calls
        Write-Host "." -NoNewline
        
        $checkLimit = (getInverterData -localAddress $localAddress).currentLimit

        if ($checkLimit -eq $newLimit) {
            Write-Host " success"
            return
        }
    }
}

$basicAuth = ([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password))))

while ($true) {
    
    $inverterData = getInverterData -localAddress $localAddress

    $inverterSerial = $inverterData.inverterSerial
    $currentPower = $inverterData.currentPower
    $currentLimit = $inverterData.currentLimit

    #Write-Host "currentPower: $currentPower Watts, currentLimit: $currentLimit%"

    $utilization = [int]($currentPower / $powerLimit * 100)
    Write-Host (Get-Date).ToString('HH:mm:ss') $("█" * ([Math]::Min(100, $utilization))) -NoNewline
    if ($utilization -gt 100) {
        Write-Host "+" -NoNewline
    }
    Write-Host " $utilization%"  -NoNewline
    Write-Progress -Activity "Utilization:" -Status "$utilization% ($currentPower Watts/$powerLimit Watts) | limited to $currentLimit%" -PercentComplete ([Math]::Min(100, $utilization))
    
    $powerDiff = [Math]::Abs($powerLimit - $currentPower)
    $limitStep = [Math]::Max(1, ($powerDiff / $powerLimit * 60))    # 60 is an amplifier to force a quicker response to limit changes

    # determine new power limit
    if ($currentPower -lt $powerLimit) {
        $newLimit = [Math]::Min($upperLimit, ($currentLimit + $limitStep))
    } elseif ($currentPower -gt $powerLimit) {
        $newLimit = [Math]::Max($lowerLimit, ($currentLimit - $limitStep))
    }

    if ($newLimit -ne $currentLimit) {
        setNewLimit -localAddress $localAddress -basicAuth $basicAuth -inverterSerial $inverterSerial -newLimit $newLimit
        continue
    }

    Write-Host
    Start-Sleep -Seconds $reactivityTime
}
