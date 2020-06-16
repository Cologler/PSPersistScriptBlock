$ENCODING = 'utf8'

$profileLocation = [System.IO.Path]::GetDirectoryName($PROFILE)
$scriptBlocksDir = [System.IO.Path]::Combine($profileLocation, "ScriptBlocks")

if (-not (Test-Path $scriptBlocksDir -PathType Container)) {
    New-Item -ItemType Directory $scriptBlocksDir
}

function Get-ScriptBlockPath([string] $name) {
    return [System.IO.Path]::Combine($scriptBlocksDir, "$name.ps1")
}

function Persist-ScriptBlock([string] $name, [scriptblock] $block) {
    $scriptPath = Get-ScriptBlockPath $name
    Set-Content $scriptPath $block.ToString().Trim() -Encoding $ENCODING
}

function List-ScriptBlock {
    return Get-ChildItem $scriptBlocksDir | Where-Object {
        $_.Extension -eq '.ps1'
    } | ForEach-Object {
        Write-Host ''
        Write-Host "  $($_.BaseName) >"
        Write-Host ''

        $ctn = Get-Content $_.FullName -Encoding $ENCODING
        foreach ($line in $ctn) {
            Write-Host "      $line"
        }

        Write-Host ''
    }
}

function Get-ScriptBlock([string] $name) {
    $scriptPath = Get-ScriptBlockPath $name
    if (Test-Path $scriptPath -PathType Leaf) {
        $ctn = Get-Content $scriptPath -Encoding $ENCODING -Raw
        return [scriptblock]::Create($ctn)
    } else {
        Write-Error -Message "Cannot find the script block with name '$Name'." -ErrorAction Stop
    }
}

function Remove-ScriptBlock([string] $name) {
    $scriptPath = Get-ScriptBlockPath $name
    if (Test-Path $scriptPath -PathType Leaf) {
        Remove-Item $scriptPath
        Write-Output "Script block '$name' removed."
    } else {
        Write-Error -Message "Cannot find the script block with name '$Name'." -ErrorAction Stop
    }
}

function Run-ScriptBlock([string] $name) {
    $block = Get-ScriptBlock $name
    Invoke-Command -ScriptBlock $block -NoNewScope
}

function Run-ScriptBlockOnNewScope([string] $name) {
    $block = Get-ScriptBlock $name
    Invoke-Command -ScriptBlock $block
}

Export-ModuleMember -Function `
    Persist-ScriptBlock,
    Get-ScriptBlock,
    List-ScriptBlock,
    Remove-ScriptBlock,
    Run-ScriptBlock,
    Run-ScriptBlockOnNewScope
