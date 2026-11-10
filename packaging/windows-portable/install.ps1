param(
    [string]$Dir = $PSScriptRoot,
    [switch]$NoStart
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Repo = "horizon-rust/horizon"
$AssetName = "horizon-launcher-windows-x64.zip"

if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    throw "Este pacote portatil requer Windows x64 (AMD64)."
}

$Headers = @{
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent" = "Horizon-Windows-Portable"
}
$Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=100" -Headers $Headers
$Release = $Releases |
    Where-Object { -not $_.draft -and $_.tag_name -like "launcher@*" } |
    Sort-Object -Property published_at -Descending |
    Select-Object -First 1
if (-not $Release) {
    throw "Nenhuma versao do Horizon Launcher foi encontrada."
}

$Asset = $Release.assets | Where-Object name -eq $AssetName | Select-Object -First 1
if (-not $Asset) {
    throw "A versao $($Release.tag_name) nao possui $AssetName."
}
if (-not $Asset.digest -or -not $Asset.digest.StartsWith("sha256:")) {
    throw "A versao $($Release.tag_name) nao publicou o SHA-256 de $AssetName."
}

$Dir = [IO.Path]::GetFullPath($Dir)
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$Temp = Join-Path ([IO.Path]::GetTempPath()) ("horizon-portable-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $Temp | Out-Null

try {
    $Zip = Join-Path $Temp $AssetName
    Write-Host "Baixando Horizon Launcher $($Release.tag_name)..."
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Zip -Headers @{ "User-Agent" = "Horizon-Windows-Portable" }

    $Expected = $Asset.digest.Substring(7).ToLowerInvariant()
    $Actual = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected) {
        throw "O download nao corresponde ao SHA-256 publicado. Nada foi instalado."
    }

    $Extracted = Join-Path $Temp "extracted"
    Expand-Archive -LiteralPath $Zip -DestinationPath $Extracted
    $Launcher = Get-ChildItem -LiteralPath $Extracted -Recurse -File -Filter "horizon-launcher.exe" |
        Select-Object -First 1
    if (-not $Launcher) {
        throw "$AssetName nao contem horizon-launcher.exe."
    }

    Copy-Item -LiteralPath $Launcher.FullName -Destination (Join-Path $Dir "horizon-launcher.exe") -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $Dir "data") | Out-Null
    Write-Host "Horizon Launcher instalado em $Dir"
} finally {
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not $NoStart) {
    & (Join-Path $Dir "Iniciar-Horizon.cmd")
}
