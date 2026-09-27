$ErrorActionPreference = 'Stop'
$metadataPath = Join-Path $PSScriptRoot '..\AppStore\metadata.json'
$metadata = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
$failures = @()

foreach ($property in $metadata.localizations.PSObject.Properties) {
    $locale = $property.Name
    $entry = $property.Value
    if ($entry.name.Length -gt $metadata.limits.name) { $failures += "$locale name exceeds limit" }
    if ($entry.subtitle.Length -gt $metadata.limits.subtitle) { $failures += "$locale subtitle exceeds limit" }
    if ($entry.promotionalText.Length -gt $metadata.limits.promotionalText) { $failures += "$locale promotional text exceeds limit" }
    if ($entry.description.Length -gt $metadata.limits.description) { $failures += "$locale description exceeds limit" }
    if ($entry.keywords) {
        $bytes = [Text.Encoding]::UTF8.GetByteCount($entry.keywords)
        if ($bytes -gt $metadata.limits.keywordsBytes) { $failures += "$locale keywords exceed byte limit" }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

$localizationCount = @($metadata.localizations.PSObject.Properties).Count
Write-Output "Validated $localizationCount App Store localizations."
