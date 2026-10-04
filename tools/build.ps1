param([string]$OutputDirectory = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDirectory) { $OutputDirectory = $projectRoot }
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $projectRoot 'module.json') | ConvertFrom-Json
$properties = Get-Content -Raw -Encoding UTF8 (Join-Path $projectRoot 'module.prop')
if ($properties -notmatch "(?m)^version=$([regex]::Escape($metadata.version))$" -or
    $properties -notmatch "(?m)^versionCode=$($metadata.versionCode)$") {
    throw 'module.prop 与 module.json 的版本不一致'
}
$packagePath = Join-Path $OutputDirectory "gms_$($metadata.version).zip"
if (Test-Path -LiteralPath $packagePath) { throw "文件已存在：$packagePath，请使用新的输出目录" }
$packageFiles = @(
    'module.prop','module.json','customize.sh','common.sh','xml-patch.awk',
    'service.sh','post-fs-data.sh','uninstall.sh','restore.sh','action.sh','gmsc',
    'README.md','changelog.md','LICENSE',
    'META-INF/com/google/android/update-binary','META-INF/com/google/android/updater-script'
)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($packagePath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relativePath in $packageFiles) {
        $sourcePath = Join-Path $projectRoot $relativePath
        $bytes = [System.IO.File]::ReadAllBytes($sourcePath)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
            throw "文件不应带 UTF-8 BOM：$relativePath"
        }
        if ([System.Text.Encoding]::UTF8.GetString($bytes).Contains([char]13)) {
            throw "文件必须使用 LF 换行：$relativePath"
        }
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $sourcePath, $relativePath, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
Write-Output ("安装包：" + $packagePath)
Write-Output ("大小：" + (Get-Item -LiteralPath $packagePath).Length + " 字节")
Write-Output ("SHA-256：" + (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash)
