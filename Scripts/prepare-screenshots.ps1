$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourceRoot = 'C:\Users\User\.codex\generated_images\01a0e345-6e80-7631-ac41-9267365270a6'
$outputRoot = Join-Path $PSScriptRoot '..\AppStore\Screenshots\EnglishUK'
$iphoneRoot = Join-Path $outputRoot 'iPhone65'
$ipadRoot = Join-Path $outputRoot 'iPad129'
$subscriptionRoot = Join-Path $outputRoot 'Subscriptions'
New-Item -ItemType Directory -Force -Path $iphoneRoot, $ipadRoot, $subscriptionRoot | Out-Null

$sources = @(
    'exec-90324ea8-dcda-4f5b-941e-2ef794db6ac9.png',
    'exec-5e1b2a1b-ce3b-4a14-8e80-677fe5d64058.png',
    'exec-f14657c1-7569-4220-9e68-421034407d67.png',
    'exec-3983d921-ffa2-4088-aba1-b3a40febb9d5.png',
    'exec-16270b47-a127-4de1-b58e-5e5296409019.png',
    'exec-cc7569b3-8305-47d5-a42f-6db4f58271d8.png',
    'exec-684f48b9-a9b5-4043-9cb0-d7f845685028.png',
    'exec-2ebe3aca-5108-4fd3-aae7-1124a0c86224.png',
    'exec-c8b82c0b-d229-485a-8a79-6398acdcf6ea.png',
    'exec-3ae6d40e-5cf1-4d2e-a0c1-1153669c9a1b.png'
)

for ($index = 0; $index -lt $sources.Count; $index++) {
    $sourcePath = Join-Path $sourceRoot $sources[$index]
    $source = [System.Drawing.Image]::FromFile($sourcePath)
    try {
        $number = ($index + 1).ToString('00')

        $iphone = New-Object System.Drawing.Bitmap 1242, 2688
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($iphone)
            try {
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawImage($source, 0, 0, 1242, 2688)
            } finally { $graphics.Dispose() }
            $iphone.Save((Join-Path $iphoneRoot "$number.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $iphone.Dispose() }

        $ipad = New-Object System.Drawing.Bitmap 2048, 2732
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($ipad)
            try {
                $graphics.Clear([System.Drawing.Color]::FromArgb(12, 16, 16))
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $scaledWidth = [int][Math]::Round(2732 * $source.Width / $source.Height)
                $x = [int](($ipad.Width - $scaledWidth) / 2)
                $graphics.DrawImage($source, $x, 0, $scaledWidth, 2732)
            } finally { $graphics.Dispose() }
            $ipad.Save((Join-Path $ipadRoot "$number.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $ipad.Dispose() }
    } finally { $source.Dispose() }
}

$reviewSource = [System.Drawing.Image]::FromFile((Join-Path $iphoneRoot '01.png'))
try {
    $review = New-Object System.Drawing.Bitmap 640, 920
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($review)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($reviewSource, 0, 0, 640, 920)
        } finally { $graphics.Dispose() }
        $review.Save((Join-Path $subscriptionRoot 'review.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $review.Dispose() }
} finally { $reviewSource.Dispose() }

$promoSource = [System.Drawing.Image]::FromFile((Join-Path $iphoneRoot '01.png'))
try {
    $promo = New-Object System.Drawing.Bitmap 1024, 1024
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($promo)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $sourceCrop = New-Object System.Drawing.Rectangle 0, 0, $promoSource.Width, $promoSource.Width
            $destination = New-Object System.Drawing.Rectangle 0, 0, 1024, 1024
            $graphics.DrawImage($promoSource, $destination, $sourceCrop, [System.Drawing.GraphicsUnit]::Pixel)
        } finally { $graphics.Dispose() }
        $promo.Save((Join-Path $subscriptionRoot 'promotional.jpg'), [System.Drawing.Imaging.ImageFormat]::Jpeg)
    } finally { $promo.Dispose() }
} finally { $promoSource.Dispose() }

Write-Output "Prepared $($sources.Count) iPhone screenshots, $($sources.Count) iPad screenshots, and subscription artwork."
