$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourcePath = 'C:\Users\User\.codex\generated_images\01a0e345-6e80-7631-ac41-9267365270a6\exec-7abc2cf1-d5ef-48c6-9093-abe44df359b5.png'
$outputDirectory = Join-Path $PSScriptRoot '..\Resources\Assets.xcassets\AppIcon.appiconset'
$icons = @(
    @{ File = 'AppIcon-20.png'; Pixels = 20 },
    @{ File = 'AppIcon-20@2x.png'; Pixels = 40 },
    @{ File = 'AppIcon-20@3x.png'; Pixels = 60 },
    @{ File = 'AppIcon-29.png'; Pixels = 29 },
    @{ File = 'AppIcon-29@2x.png'; Pixels = 58 },
    @{ File = 'AppIcon-29@3x.png'; Pixels = 87 },
    @{ File = 'AppIcon-40.png'; Pixels = 40 },
    @{ File = 'AppIcon-40@2x.png'; Pixels = 80 },
    @{ File = 'AppIcon-40@3x.png'; Pixels = 120 },
    @{ File = 'AppIcon-60@2x.png'; Pixels = 120 },
    @{ File = 'AppIcon-60@3x.png'; Pixels = 180 },
    @{ File = 'AppIcon-76.png'; Pixels = 76 },
    @{ File = 'AppIcon-76@2x.png'; Pixels = 152 },
    @{ File = 'AppIcon-83.5@2x.png'; Pixels = 167 },
    @{ File = 'AppIcon-1024.png'; Pixels = 1024 }
)
$source = [System.Drawing.Image]::FromFile($sourcePath)
try {
    foreach ($item in $icons) {
        $pixels = $item.Pixels
        $outputPath = Join-Path $outputDirectory $item.File
        $icon = New-Object System.Drawing.Bitmap $pixels, $pixels, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($icon)
            try {
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawImage($source, 0, 0, $pixels, $pixels)
            } finally { $graphics.Dispose() }
            $icon.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $icon.Dispose() }
    }
} finally { $source.Dispose() }

Write-Output "Prepared complete iPhone, iPad, and App Store icon set without transparency."
