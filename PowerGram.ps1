#================================#
#          PowerGram v2.0        #
#   Original code by @JoelGMSec  #
#      https://darkbyte.net      #
#      Enhanced by @Jaschan      #
#================================#
using module '.\PGFunctions.psm1'
Param([Alias('h')][switch]$Help, [Alias('t')][string]$Token)
#$ErrorActionPreference = "SilentlyContinue"
#$ProgressPreference = "SilentlyContinue"
#Set-StrictMode -Off

Show-Banner
<#
if ($PSVersionTable.PSVersion -lt 6.2) {
    Write-Host "`n[!] PowerGram needs Powershell 6.1 or newer to run!`n" -ForegroundColor Red
    exit
}
#>
# Show Help command
if ($Help) {
    Show-Help
    exit
}

# Store Token command
if ($Token) {
    $Token > 'token'
    Write-Host "`n[+] Token saved!`n" -ForegroundColor Green
    exit
}

# Load saved Token
$token = Get-Content -Path "$PSScriptRoot\token"
if (!$token) {
    Show-Help
    Write-Host "`n[!] Token not found! Please check before run PowerGram!`n" -ForegroundColor Red
    exit
}
$baseurl = "https://api.telegram.org/bot{0}" -f $token

# Allowed users unique IDs
$UsersList = Get-Content -Path "$PSScriptRoot\UsersList.json" | ConvertFrom-Json
function Resolve-Access {
    Param([object]$User,[string]$Command)
    if ($User.IsAdmin) {
        return $true
    }
    if (($Command -in @('/exec', '/shell') -and $User.ShellAccess)) {
        return $true
    }
    if ($Command -in $User.AllowedCommands) {
        return $true
    }
    Write-Host "User $User don't have access to $Command"
    return $false
}
# TODO: Add a command to add/remove users

# Design
$Hostname = ([Environment]::MachineName).ToLower()
$User = ([Environment]::UserName).ToLower()
$os = [Environment]::OSVersion.Platform
if ($os -ne "Unix") {
    $Host.UI.RawUI.WindowTitle = "PowerGram"
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
}

# Proxy Aware
<#
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
#>

# Wake On Lan
# TODO: Test, create one for UNIX
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
# TODO: FIX
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
    $Message = "Uploading [$docuname]"
    $Response = Send-Message $AnwsTo $Message -ParseMode HTML
    if ($uploadfile -like "*$slash*") {
        Invoke-WebRequest "https://api.telegram.org/file/bot$($token)/$uploadpath" -OutFile $uploadfile$slash$docuname
    } else {
        Invoke-WebRequest "https://api.telegram.org/file/bot$($token)/$uploadpath" -OutFile $docuname
    }
}

# Download Function
# TODO: FIX
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

# Chat Commands
function Invoke-Task {
    Param([string]$Task,
          [string]$RawArgs,
          [object]$User,
          [int]$AnwsTo)
    $Message = $null
    switch ($Task) {
        {($_ -eq "/exit") -and $User.InShellMode} {
            $User.InShellMode = $false
            $Message = "Interactive Shell Mode is now disabled!"
            break
        }
        {$User.InShellMode -and $User.ShellAccess} {
            $Message = iex $RawArgs
            break
        }
        {$User.addanime.wip -and $_ -eq '/abort'} {
            $User.addanime.wip = $false
            $Message = 'Adding aborted'
            break
        }
        {$User.addanime.wip} {
            $Message = Add-Anime -User $User -Data $RawArgs
            break
        }
        {($_ -eq "/getid") -or ($_ -eq "/start")} {
            $Message = "Your Chat ID is {0}" -f $AnwsTo
            break
        }
        # From here you need to have access to the command
        {$true}{ if (!(Resolve-Access $User $_)) { break } }
        '/help' {
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
        '/wakeonlan' {
            $Mac = $RawArgs
            # TODO: Validate $Mac format with regex
            wakeonlan $Mac
            if ($?) {
                $Message = "Sending WOL to [$Mac]"
            } else {
                $Message = "WOL Failed"
            }
            break
        }
        '/shell' {
            $User.InShellMode = $true
            $Message = "Interactive Shell Mode is now enabled!"
            break
        }
        '/upload' {
            $document = $RawArgs
            $Message = "Waiting for file"
            $Response = Send-Message $AnwsTo $Message -ParseMode HTML
            upload $document
            $Message = "Upload completed"
            break
        }
        '/download' {
            $document = $RawArgs
            $Message = "Sending [$document]"
            $Response = Send-Message $AnwsTo $Message -ParseMode HTML
            $Response = download $document
            $Message = $null
            break
        }
        '/exec' {
            $Message = iex $RawArgs
            break
        }
        '/kill' {
            $Message = "Killing PowerGram Bot. Bye!"
            $Response = Send-Message $AnwsTo $Message
            Write-Host "`n[!] Killing PowerGram Bot. Bye!`n" -ForegroundColor Red
            exit
        }
        '/add' {
            $Message = Add-Anime -User $User -Start
        }
    }
    if ($Message) { $Response = Send-Message $AnwsTo $Message }
}

function Add-Anime {
    Param([object]$User,
          [string]$Data,
          [switch]$Start,
          [switch]$Abort)
    $Steps = @('Team', 'SearchName', 'Tags', 'Season', 'FolderName', 'EpisodeName')
    if ($Start) {
        # Start, Init variables
        $Template = @{
            wip = $true
            step = 0
            data = @{}
        }
        $User | Add-Member -MemberType NoteProperty -Name 'addanime' -Value $Template
    } else {
        if ($User.addanime.step -eq 2) {
            $User.addanime.data[$Steps[$User.addanime.step]] = @($Data -Split ',')
        } elseif ($User.addanime.step -eq 3) {
            $User.addanime.data[$Steps[$User.addanime.step]] = [int]$Data
        } else {
            $User.addanime.data[$Steps[$User.addanime.step]] = $Data
        }
        $User.addanime.step++
    }
    if ($User.addanime.step -ge $Steps.Count) {
        # Completed
        $ListPath = '\torrents\scrapper\Config\LocalAnimeList.json'
        $List = Get-Content -Path $ListPath | ConvertFrom-Json
        $List += $User.addanime.data
        $List | ConvertTo-Json -Depth 20 > $ListPath
        $User.addanime.wip = $false
        return ("Adding <b>{0}</b> completed" -f $User.addanime.data.FolderName)
    }
    return ("Input <b>{0}</b>" -f $Steps[$User.addanime.step])
}

# Telegram's API Wrappers
function Send-Message {
    Param([int]$ChatID,
          [string]$Message,
          [ValidateSet('HTML', 'Markdown', 'MarkdownV2')][string]$ParseMode='HTML')
    $Uri = "$baseurl/sendMessage?chat_id={0}&text={1}&parse_mode={2}" -f $ChatID, $Message, $ParseMode
    Invoke-WebRequest $Uri
}

function Get-Updates {
    Param([int]$Offset)
    $GetUpdates = Invoke-WebRequest -Uri "$baseurl/getUpdates?offset=$Offset"
    [array]($GetUpdates | ConvertFrom-Json).result
}

# Start PowerGram (Main Loop)
Write-Host "`n[+] Ready! Waiting for new messages`n" -ForegroundColor Green
$UpdateIdOffset = 0
$idle = 0
$frames = '/-\|'
$SleepAmount = 2000
while ($true) {
    $StartTime = [int](get-date -uformat %s)

    # The meat
    $AllUpdates = Get-Updates $UpdateIdOffset
    foreach ($Update in $AllUpdates) {
        $UpdateIdOffset = [uInt64]$Update.update_id + 1
        # If message is not in the update, it could be an edit, poll, inline_query, etc.
        if (!($Update.message)) { continue }
        Write-InEventLog $Update.message.from.username $Update.message.text
        $User = $UsersList.($Update.message.from.id)
        if ($Update.message.text[0] -eq '/') {
            $Cmd = $Update.message.text.split(' ', 2)[0]
            $RawArgs = $Update.message.text.split(' ', 2)[1]
        } else {
            $Cmd = $null
            $RawArgs = $Update.message.text
        }
        Invoke-Task -Task $Cmd -RawArgs $RawArgs -User $User -AnwsTo $Update.message.chat.id
    }

    # Idling animation
    if ($idle -ge $frames.Length) { $idle = 0 }
    Write-Host -NoNewLine ("[{0}] Frequency: {1}`r" -f $frames[$idle], ($SleepAmount/1000).ToString('0.0'))
    $idle++

    # Timing
    if ($AllUpdates.Count -gt 0) {
        # Fast mode
        $FastModeStartTime = [int](get-date -uformat %s)
        $SleepAmount = 200
    }
    if (([int](get-date -uformat %s) - $FastModeStartTime) -gt 10) {
        # Slow mode
        $SleepAmount = 2000
    }
    $SpentTime = [int](get-date -uformat %s) - $StartTime
    $SleepTime = $SleepAmount - $SpentTime
    if ($SleepTime -gt 0) { Start-Sleep -Milliseconds $SleepTime }
    else { Write-InEventLog 'PowerGram' ("Can't keep up! Running behind by: {0}" -f $SleepTime.ToString('0.0'))}
}