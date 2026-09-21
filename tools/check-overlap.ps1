param(
    [Parameter(Mandatory = $true)]
    [string]$MapFile
)

if (-not (Test-Path -LiteralPath $MapFile)) {
    Write-Error "Map file not found: $MapFile"
    exit 1
}

$sections = @{}
foreach ($line in Get-Content -LiteralPath $MapFile) {
    if ($line -match '^__(?<name>.+)_(?<edge>head|tail)\s+=\s+\$(?<address>[0-9A-Fa-f]+)') {
        $name = $matches['name']
        $address = [Convert]::ToInt32($matches['address'], 16)
        if (-not $sections.ContainsKey($name)) {
            $sections[$name] = @{}
        }
        $sections[$name][$matches['edge']] = $address
    }
}

$ranges = @(
    foreach ($section in $sections.GetEnumerator()) {
        if ($section.Value.ContainsKey('head') -and $section.Value.ContainsKey('tail')) {
            [pscustomobject]@{
                Name = $section.Key
                Head = $section.Value['head']
                Tail = $section.Value['tail']
            }
        }
    }
) | Sort-Object Head, Tail

$overlaps = @(
    for ($index = 1; $index -lt $ranges.Count; $index++) {
        $previous = $ranges[$index - 1]
        $current = $ranges[$index]
        if ($current.Head -lt $previous.Tail) {
            [pscustomobject]@{
                First = $previous
                Second = $current
            }
        }
    }
)

if ($overlaps.Count -gt 0) {
    foreach ($overlap in $overlaps) {
        $first = $overlap.First
        $second = $overlap.Second
        Write-Error ("Overlapping sections: {0} [{1:X4}-{2:X4}) and {3} [{4:X4}-{5:X4})" -f `
            $first.Name, $first.Head, $first.Tail, $second.Name, $second.Head, $second.Tail)
        if ($first.Name -eq 'BASICRAM' -or $second.Name -eq 'BASICRAM') {
            $code = if ($first.Name -eq 'BASICRAM') { $second } else { $first }
            $ram = if ($first.Name -eq 'BASICRAM') { $first } else { $second }
            Write-Error ("Program code ({0}) has grown past the BASICRAM origin (`${1:X4} in BBCZ80/DATA.asm) by {2} byte(s). Reduce code size or move BASICRAM." -f `
                $code.Name, $ram.Head, ($code.Tail - $ram.Head))
        }
    }
    exit 1
}

Write-Host ("Section overlap check passed: {0} sections" -f $ranges.Count)