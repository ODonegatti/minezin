param(
    [string]$PortableRoot = $PSScriptRoot,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$PortableRoot = [IO.Path]::GetFullPath($PortableRoot)
$Data = Join-Path $PortableRoot "data"

function Write-Status([string]$Message) {
    if (-not $Quiet) {
        Write-Host $Message
    }
}

function Update-LiteralFile([string]$Path, [Collections.Specialized.OrderedDictionary]$Replacements) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $Before = [IO.File]::ReadAllText($Path)
    $After = $Before
    foreach ($Old in $Replacements.Keys) {
        $After = $After.Replace([string]$Old, [string]$Replacements[$Old])
    }
    if ($After -eq $Before) {
        return $false
    }

    [IO.File]::WriteAllText($Path, $After, [Text.UTF8Encoding]::new($false))
    return $true
}

$RustRoot = Join-Path $Data "rust"
$Toolchain = Get-ChildItem -LiteralPath $RustRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object Name -Like "*-x86_64-pc-windows-gnu" |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
if ($Toolchain) {
    $Headers = Join-Path $Toolchain.FullName "mingw64\x86_64-w64-mingw32\include"
    $ShortHeaders = Join-Path $env:USERPROFILE ".horizon-build-include"
    $Marker = Join-Path $ShortHeaders ".horizon-toolchain"
    $ExpectedMarker = $Toolchain.Name
    $CurrentMarker = if (Test-Path -LiteralPath $Marker) {
        [IO.File]::ReadAllText($Marker).Trim()
    } else {
        ""
    }

    if ((Test-Path -LiteralPath $Headers) -and $CurrentMarker -ne $ExpectedMarker) {
        New-Item -ItemType Directory -Force -Path $ShortHeaders | Out-Null
        Copy-Item -Path (Join-Path $Headers "*") -Destination $ShortHeaders -Recurse -Force
        [IO.File]::WriteAllText($Marker, $ExpectedMarker, [Text.Encoding]::ASCII)
        Write-Status "Headers MinGW preparados em $ShortHeaders"
    }
}

$TreeFallRoots = @(
    (Join-Path $Data "native\installed.incoming\treefall\mixins\treefall"),
    (Join-Path $Data "native\mods.incoming\treefall")
)
$Patched = 0
foreach ($Root in $TreeFallRoots) {
    $NativeReplacements = [ordered]@{
        "game.dim.min_y()" = "game.world.shape.min_y"
        "p[1] > game.dim.max_y()" = "p[1] >= game.world.shape.max_y()"
        "pub(super) fn treefall_destroy_progress(&self," = "pub(super) fn treefall_destroy_progress(&mut self,"
    }
    if (Update-LiteralFile (Join-Path $Root "native.rs") $NativeReplacements) {
        $Patched++
    }

    $SpeedReplacements = [ordered]@{
        "fn treefall_speed(game: &crate::game::Game<'_>," = "fn treefall_speed(game: &mut crate::game::Game<'_>,"
    }
    if (Update-LiteralFile (Join-Path $Root "speed.rs") $SpeedReplacements) {
        $Patched++
    }

    $MixinReplacements = [ordered]@{
        '{ name = "game", ty = "&crate::game::Game<''_>", value = "self" },' = '{ name = "game", ty = "&mut crate::game::Game<''_>", value = "self" },'
    }
    if (Update-LiteralFile (Join-Path $Root "horizon-mixin.toml") $MixinReplacements) {
        $Patched++
    }
}
if ($Patched -gt 0) {
    Write-Status "TreeFall adaptado para o build nativo ($Patched arquivos)."
}
