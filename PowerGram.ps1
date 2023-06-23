#================================#
#    PowerGram by @JoelGMSec     #
#      https://darkbyte.net      #
#================================#

# Design
$os = [Environment]::OSVersion.Platform
if ($os -ne "Unix") {
    $Host.UI.RawUI.WindowTitle = "PowerGram - by @JoelGMSec"
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
}
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"
#Set-StrictMode -Off

# Token & ChatID
$token = "5931392898:AAFlCiZSoy4wFWQlFQt9jEdeVznQHnG9c5w" # Talk with @BotFather and create it first
$AllowedChats = @("155419747") # Talk with your Bot and send /getid to get it
$baseurl = "https://api.telegram.org/bot{0}" -f $token
# Banner
Write-Host
Write-Host "  ____                         ____                      " -ForegroundColor Blue
Write-Host " |  _ \ __ __      __ __ _ __ / ___|_ __ __ _ _ __ ___   " -ForegroundColor Blue
Write-Host " | |_) / _ \ \ /\ / / _ \ '__| |  _| '__/ _' | '_ ' _ \  " -ForegroundColor Blue
Write-Host " |  __/ (_) \ V  V /  __/ |  | |_| | | | (_| | | | | | | " -ForegroundColor Blue
Write-Host " |_|   \___/ \_/\_/ \___|_|   \____|_|  \__,_|_| |_| |_| " -ForegroundColor Blue                                                        
Write-Host
Write-Host "  ------------------- by @JoelGMSec -------------------  " -ForegroundColor Blue

# Help
function Show-Help {
    Write-host
    Write-Host " Info: " -ForegroundColor Yellow -NoNewLine
    Write-Host " PowerGram is a pure PowerShell Telegram Bot"
    Write-Host "        that can be run on Windows, Linux or Mac OS"
    Write-Host
    Write-Host " Usage: " -ForegroundColor Yellow -NoNewLine
    Write-Host "PowerGram from PowerShell" -ForegroundColor Blue 
    Write-Host "        .\PowerGram.ps1 -h" -ForegroundColor Green -NoNewLine
    Write-Host " Show this help message" 
    Write-Host "        .\PowerGram.ps1" -ForegroundColor Green -NoNewLine 
    Write-Host " Start PowerGram Bot"
    Write-Host 
    Write-Host "        PowerGram from Telegram" -ForegroundColor Blue 
    Write-Host "        /getid" -ForegroundColor Green -NoNewLine
    Write-Host " Get your Chat ID from Bot"
    Write-Host "        /help" -ForegroundColor Green -NoNewLine
    Write-Host " Show all available commands"
    Write-Host
    Write-Host " Warning: " -ForegroundColor Red -NoNewLine
    Write-Host "All commands will be sent using HTTPS GET requests"
    Write-Host "         " -NoNewLine
    Write-Host " You need your Chat ID & Bot Token to run PowerGram"
    Write-Host
}

# Proxy Aware
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

function Send-Message {
    Param([int]$ChatID,[string]$Message,[ValidateSet('HTML', 'Markdown', 'MarkdownV2')][string]$ParseMode='HTML')
    $Uri = "$baseurl/sendMessage?chat_id={0}&text={1}&parse_mode={2}" -f $ChatID, $Message, $ParseMode
    Invoke-WebRequest $Uri | Write-Output
}

# Wake On Lan
if ($os -ne "Unix") {
    function wakeonlan {
        Param ([Parameter(ValueFromPipeline)][String[]]$Mac)
        $MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_" }
        [Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16)
        $ip = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress
        $ip = $ip | select-object -first 1
        $ip = $ip.split(".")
        $ip = $ip[0]+"."+$ip[1]+"."+$ip[2]+".255"
        $UdpClient = New-Object System.Net.Sockets.UdpClient
        $UdpClient.Connect("$ip",7) | Out-Null
        $UdpClient.Send($MagicPacket,$MagicPacket.Length) | Out-Null
        $UdpClient.Close() | Out-Null
    }
}

# Upload Function
function upload {
    Param([string]$uploadfile)
    if ($os -ne "Unix") { $slash = "\" } else { $slash = "/" }
    $BotUpdates = Invoke-WebRequest -Uri "$baseurl/getUpdates?offset=($offset2)"
    $JsonResult = [array]($BotUpdates | ConvertFrom-Json).result
    $documentid = $JsonResult.message.document.file_id | Select-Object -Last 1
    $docuname = $JsonResult.message.document.file_name | Select-Object -Last 1
    $Uri = "$baseurl/getFile"
    $Response = Invoke-WebRequest $Uri -Method Post -ContentType 'application/json' -Body "{`"file_id`":`"$documentid`"}"
    $jsonpath = [array]($Response | ConvertFrom-Json).result
    $uploadpath = $jsonpath.file_path
    $Message = "[>] Uploading [$docuname]"
    $Response = Send-Message $id $Message -ParseMode HTML
    if ($uploadfile -like "*$slash*") {
        Invoke-WebRequest "https://api.telegram.org/file/bot$($token)/$uploadpath" -OutFile $uploadfile$slash$docuname
    } else {
        Invoke-WebRequest "https://api.telegram.org/file/bot$($token)/$uploadpath" -OutFile $docuname
    }
}

# Download Function
function download {
    Param([string]$downloadfile)
    if ($os -ne "Unix") {
        if ($downloadfile -like "*.\*") { $downloadfile = $downloadfile.replace(".\","$pwd\") }
        if ($downloadfile -notlike "*:\*") { $downloadfile = "$pwd\$downloadfile" }
        $filename = ($downloadfile).Split('\')[-1]
    }
    if ($os -like "Unix") {
        if ($downloadfile -notlike "*/*") { $downloadfile = "$pwd/$downloadfile" }
        $filename = ($downloadfile).Split('/')[-1]
    }
    $Uri = "$baseurl/sendDocument"
    $fileBytes = [System.IO.File]::ReadAllBytes($downloadfile)
    $fileEncoding = [System.Text.Encoding]::GetEncoding("UTF-8").GetString($fileBytes)
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $bodyLines = ( "--$boundary","Content-Disposition: form-data; name=`"chat_id`"$LF",
        "$chatid$LF","--$boundary","Content-Disposition: form-data; name=`"document`"; filename=`"$filename`"",
        "Content-Type: application/octet-stream$LF","$fileEncoding","--$boundary--$LF" ) -join $LF
    Invoke-WebRequest $Uri -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
}

# Start PowerGram
if ($args[0] -like "-h*") {
    Show-Help
    exit
}
if (!$token) {
    Show-Help
    Write-Host "`n[!] Token not found! Please check before run PowerGram!`n" -ForegroundColor Red
    exit
}
Write-Host "`n[+] Ready! Waiting for new messages`n" -ForegroundColor Green
$Hostname = ([Environment]::MachineName).ToLower()
$User = ([Environment]::UserName).ToLower()
$Interactive = $false

# Main Function
while ($true) {
    $BotUpdates = Invoke-WebRequest -Uri "$baseurl/getUpdates"
    $JsonResult = [array]($BotUpdates | ConvertFrom-Json).result
    $messageid = $JsonResult.message.message_id | Select-Object -Last 1
    $updateid = $JsonResult.update_id | Select-Object -Last 1
    if ($messageid -eq $null) { $messageid = 0 }
    $updateid = [int]$updateid++
    $messageid = [int]$messageid 
    do {
        $BotUpdates = Invoke-WebRequest -Uri "$baseurl/getUpdates?offset=$updateid"
        $JsonResult = [array]($BotUpdates | ConvertFrom-Json).result
        $messageid2 = $JsonResult.message.message_id | Select-Object -Last 1
        $messageid2 = [int]$messageid2
        sleep 1
    }
    until ($messageid -notin $messageid2)

    # Event Log
    if ($JsonResult.message.document -notin $messageid2) {
        $id = $JsonResult.message.from.id | Select-Object -Last 1
        $username = $JsonResult.message.from.username | Select-Object -Last 1
        $text = $JsonResult.message.text | Select-Object -Last 1
        $time = Get-Date -UFormat "%m/%d/%Y %R"
        Write-Host "[$time] " -NoNewLine -ForegroundColor Yellow
        Write-Host "`::" -NoNewLine
        Write-Host " From @$username " -NoNewLine -ForegroundColor Magenta
        Write-Host "`::" -NoNewLine
        Write-Host " $text" -ForegroundColor Green
    }

    # Chat Commands
    $Message = $null
    $cmd = $text.split(' ', 2)[0]
    $arguments = $text.split(' ', 2)[1]
    switch ($cmd) {
        {($Interactive) -and ($cmd -eq "/exit")} {
            $Interactive = $false
            $Message = "[>] Interactive Shell Mode is now disabled!"
            break
        }
        {($Interactive) -and ($id -in $AllowedChats)} {
            $Message = iex $text
            break
        }
        {($_ -eq "/getid") -or ($_ -eq "/start")} {
            $Message = "Your Chat ID is $id"
            break
        }
        {($_ -eq "/help") -and ($id -in $AllowedChats)} {
            $Message  = "<b>----------- PowerGram by @JoelGMSec -----------</b>`n"
            $Message += "`nAvailable Commands:"
            $Message += "`n/help = Show this help message"
            $Message += "`n/wakeonlan = Send wakeonlan command"
            $Message += "`n/shell = Enable Interactive Shell Mode"
            $Message += "`n/exit = Disable Interactive Shell Mode"
            $Message += "`n/upload = Upload file to current folder or specific one"
            $Message += "`n/download = Download file from current folder or specific one"
            $Message += "`n/exec = Execute commands on OS with PowerShell"
            $Message += "`n/getid = Obtain your Chat ID"
            $Message += "`n/kill = Kill PowerGram Bot"
            break
        }
        {($_ -eq "/wakeonlan") -and ($id -in $AllowedChats)} {
            $Mac = $arguments
            # TODO: Validate $Mac format with regex
            wakeonlan $Mac
            if ($?) {
                $Message = "[>] Sending WOL to [$Mac]"
            } else {
                $Message = "[>] WOL Failed"
            }
            break
        }
        {($_ -eq "/shell") -and ($id -in $AllowedChats)} {
            $Interactive = $true
            $Message = "[>] Interactive Shell Mode is now enabled!"
            break
        }
        {($_ -eq "/upload") -and ($id -in $AllowedChats)} {
            $document = $arguments
            $Message = "[>] Waiting for file"
            $Response = Send-Message $id $Message -ParseMode HTML
            upload $document
            $Message = "[>] Upload completed"
            break
        }
        {($_ -eq "/download") -and ($id -in $AllowedChats)} {
            $document = $arguments
            $Message = "[>] Sending [$document]"
            $Response = Send-Message $id $Message -ParseMode HTML
            $Response = download $document
            $Message = $null
            break
        }
        {($_ -eq "/exec") -and ($id -in $AllowedChats)} {
            $Message = iex $arguments
            break
        }
        {($_ -eq "/kill") -and ($id -in $AllowedChats)} {
            $Message = "[>] Killing PowerGram Bot. Bye!"
            $Response = Send-Message $id $Message
            Write-Host "`n[!] Killing PowerGram Bot. Bye!`n" -ForegroundColor Red
            exit
        }
    }
    if ($Message) { $Response = Send-Message $id $Message }
}
