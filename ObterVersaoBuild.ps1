param(
    [ValidateSet('Max', 'Keys')]
    [string]$Mode,
    [string]$ProjectPath,
    [string]$FileVersion
)

function Get-ReleaseVersion([string]$Path) {
    [xml]$project = Get-Content -Raw -LiteralPath $Path
    $group = @($project.Project.PropertyGroup | Where-Object {
        [string]$_.Condition -like '*Cfg_1_Win32*' -and [string]$_.VerInfo_Keys
    })[0]

    if ($null -eq $group) {
        throw "Configuracao Release/Win32 nao encontrada: $Path"
    }

    $match = [regex]::Match([string]$group.VerInfo_Keys, 'FileVersion=([^;]+)')
    if (-not $match.Success) {
        throw "FileVersion nao encontrada: $Path"
    }

    return [version]$match.Groups[1].Value
}

if ($Mode -eq 'Max') {
    $versions = @(
        Get-ReleaseVersion 'D:\sistemas\novatec\cliente\NovatecCliente.dproj'
        Get-ReleaseVersion 'D:\sistemas\novatec\NovoServidor\NovatecServidor.dproj'
    )

    ($versions | Sort-Object -Descending | Select-Object -First 1).ToString()
    exit 0
}

if (-not $ProjectPath -or -not $FileVersion) {
    throw 'ProjectPath e FileVersion sao obrigatorios no modo Keys.'
}

[xml]$project = Get-Content -Raw -LiteralPath $ProjectPath
$group = @($project.Project.PropertyGroup | Where-Object {
    [string]$_.Condition -like '*Cfg_1_Win32*' -and [string]$_.VerInfo_Keys
})[0]

if ($null -eq $group) {
    throw "Configuracao Release/Win32 nao encontrada: $ProjectPath"
}

$keys = [string]$group.VerInfo_Keys
$keys = $keys -replace 'FileVersion=[^;]*', "FileVersion=$FileVersion"
$keys = $keys -replace 'CompileDate=[^;]*', 'CompileDate='
$keys -replace ';', '%3B'
$keys
