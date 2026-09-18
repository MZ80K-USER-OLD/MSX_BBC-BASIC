param(
    [Parameter(Mandatory = $true)]
    [string]$CounterFile,
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$count = 0
if (Test-Path -LiteralPath $CounterFile) {
    $value = (Get-Content -LiteralPath $CounterFile -Raw).Trim()
    if ($value -match '^[0-9]+$') {
        $count = [int]$value
    }
}

$count++
Set-Content -LiteralPath $CounterFile -Value $count -Encoding ascii
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputFile) | Out-Null
$display = $count.ToString('0000')
@"
BUILDMSG: DEFM "MSX-DOS2 BUILD $display"
DEFB 0DH,0AH,0
"@ | Set-Content -LiteralPath $OutputFile -Encoding ascii