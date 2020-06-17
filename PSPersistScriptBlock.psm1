$ENCODING = 'utf8'

$profileLocation = [System.IO.Path]::GetDirectoryName($PROFILE)
$scriptBlocksDir = [System.IO.Path]::Combine($profileLocation, "ScriptBlocks")

if (-not (Test-Path $scriptBlocksDir -PathType Container)) {
    New-Item -ItemType Directory $scriptBlocksDir
}

function Get-ScriptBlockPath([string] $name) {
    return [System.IO.Path]::Combine($scriptBlocksDir, "$name.ps1")
}

<#
    .Description
    Persist a ScriptBlock on disk.

    .Example
    Persist-ScriptBlock -Name test -ScriptBlock {
        Write-Host 'runing test'
    }
#>
function Persist-ScriptBlock (
    [Parameter(Mandatory=$true)][string] $Name,
    [Parameter(Mandatory=$true)][scriptblock] $ScriptBlock
) {

    $scriptPath = Get-ScriptBlockPath $Name
    Set-Content $scriptPath $ScriptBlock.ToString().Trim() -Encoding $ENCODING
}

function Get-AllScriptBlockFiles() {
    return Get-ChildItem $scriptBlocksDir | Where-Object {
        $_.Extension -eq '.ps1'
    }
}

function List-ScriptBlock {
    return Get-AllScriptBlockFiles | ForEach-Object {
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

function Get-ScriptBlock([Parameter(Mandatory=$true)][string] $Name) {
    $scriptPath = Get-ScriptBlockPath $Name
    if (Test-Path $scriptPath -PathType Leaf) {
        $ctn = Get-Content $scriptPath -Encoding $ENCODING -Raw
        return [scriptblock]::Create($ctn)
    } else {
        Write-Error -Message "Cannot find the script block with name '$Name'." -ErrorAction Stop
    }
}

function Remove-ScriptBlock([Parameter(Mandatory=$true)][string] $Name) {
    $scriptPath = Get-ScriptBlockPath $Name
    if (Test-Path $scriptPath -PathType Leaf) {
        Remove-Item $scriptPath
        Write-Output "Script block '$Name' removed."
    } else {
        Write-Error -Message "Cannot find the script block with name '$Name'." -ErrorAction Stop
    }
}

function Run-ScriptBlock([Parameter(Mandatory=$true)][string] $Name) {
    $block = Get-ScriptBlock $Name
    Invoke-Command -ScriptBlock $block -NoNewScope
}

function Run-ScriptBlockOnNewScope([Parameter(Mandatory=$true)][string] $Name) {
    $block = Get-ScriptBlock $Name
    Invoke-Command -ScriptBlock $block
}

$s = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    return Get-AllScriptBlockFiles |
        ForEach-Object {$_.BaseName}
        Where-Object {$_ -like "$wordToComplete*"} |
        ForEach-Object {
        New-Object -Type System.Management.Automation.CompletionResult -ArgumentList $_,
            $_,
            "ParameterValue",
            $_
    }
}

'Get-ScriptBlock','Run-ScriptBlock','Run-ScriptBlockOnNewScope' |
ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ParameterName Name -ScriptBlock $s
}

Export-ModuleMember -Function `
    Persist-ScriptBlock,
    Get-ScriptBlock,
    List-ScriptBlock,
    Remove-ScriptBlock,
    Run-ScriptBlock,
    Run-ScriptBlockOnNewScope
