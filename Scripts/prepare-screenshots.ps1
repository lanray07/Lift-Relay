param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SourceRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$outputRoot = Join-Path $PSScriptRoot '..\AppStore\Screenshots\EnglishUK'
$iphoneRoot = Join-Path $outputRoot 'iPhone65'
$ipadRoot = Join-Path $outputRoot 'iPad129'
$subscriptionRoot = Join-Path $outputRoot 'Subscriptions'
New-Item -ItemType Directory -Force -Path $iphoneRoot, $ipadRoot, $subscriptionRoot | Out-Null

$sources = @(Get-ChildItem -LiteralPath $sourceRoot -File -Filter '*.png' | Sort-Object Name)
if ($sources.Count -ne 10) {
    throw "Expected exactly 10 source PNG files in '$sourceRoot', found $($sources.Count). Name them 01.png through 10.png to control their order."
}

for ($index = 0; $index -lt $sources.Count; $index++) {
    $sourcePath = $sources[$index].FullName
    $source = [System.Drawing.Image]::FromFile($sourcePath)
    try {
        $number = ($index + 1).ToString('00')

        $iphone = New-Object System.Drawing.Bitmap 1242, 2688, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
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
