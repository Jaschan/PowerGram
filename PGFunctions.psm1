# Banner
function Show-Banner {
    Write-Host
    Write-Host "  ____                         ____                      " -ForegroundColor Blue
    Write-Host " |  _ \ __ __      __ __ _ __ / ___|_ __ __ _ _ __ ___   " -ForegroundColor Blue
    Write-Host " | |_) / _ \ \ /\ / / _ \ '__| |  _| '__/ _' | '_ ' _ \  " -ForegroundColor Blue
    Write-Host " |  __/ (_) \ V  V /  __/ |  | |_| | | | (_| | | | | | | " -ForegroundColor Blue
    Write-Host " |_|   \___/ \_/\_/ \___|_|   \____|_|  \__,_|_| |_| |_| " -ForegroundColor Blue
    Write-Host "                       Version 2.0                       " -ForegroundColor Blue
    Write-Host
    Write-Host "  ------------- Original code by @JoelGMSec -----------  " -ForegroundColor Blue
    Write-Host "  ---------------- Enhanced by @Jaschan ---------------  " -ForegroundColor Blue
    Write-host
}

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
    Write-Host "        .\PowerGram.ps1 -t <token>" -ForegroundColor Green -NoNewLine
    Write-Host " Stores the given token to use"
    Write-Host " Talk with @BotFather to create it"
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

function Write-InEventLog {
    Param([string]$Who,[string]$What)
    $time = Get-Date -UFormat "%m/%d/%Y %R"
    Write-Host "[$time] " -NoNewLine -ForegroundColor Yellow
    Write-Host "`::" -NoNewLine
    Write-Host " From @$Who " -NoNewLine -ForegroundColor Magenta
    Write-Host "`::" -NoNewLine
    Write-Host " $What" -ForegroundColor Green
}