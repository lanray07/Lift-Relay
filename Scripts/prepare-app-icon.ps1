$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourcePath = 'C:\Users\User\.codex\generated_images\01a0e345-6e80-7631-ac41-9267365270a6\exec-7abc2cf1-d5ef-48c6-9093-abe44df359b5.png'
$outputPath = Join-Path $PSScriptRoot '..\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png'
$source = [System.Drawing.Image]::FromFile($sourcePath)
try {
    $icon = New-Object System.Drawing.Bitmap 1024, 1024, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($icon)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($source, 0, 0, 1024, 1024)
        } finally { $graphics.Dispose() }
        $icon.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $icon.Dispose() }
} finally { $source.Dispose() }

Write-Output "Prepared 1024x1024 App Store icon without transparency."
