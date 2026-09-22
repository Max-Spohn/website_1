# Generates a 1200x630 Open Graph card for maxspohn.com.
# Colors are sampled from the live site: bg #F2F2F1, accent #516DB0, body #404040.
param(
  [string]$Source = "C:\Users\maxsp\OneDrive\Dokumente\website_1\static\img\_MG_9143.jpg",
  [string]$OutFile,
  # Crop window into the source, as fractions of its dimensions.
  [double]$CropTop    = 0.0,
  [double]$CropHeight = 0.74
)

Add-Type -AssemblyName System.Drawing

$W = 1200; $H = 630
$PanelW = 470                      # photo panel on the right
$Pad = 78

$bg     = [System.Drawing.ColorTranslator]::FromHtml("#F2F2F1")
$accent = [System.Drawing.ColorTranslator]::FromHtml("#516DB0")
$body   = [System.Drawing.ColorTranslator]::FromHtml("#404040")

$src = [System.Drawing.Image]::FromFile($Source)

$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.Clear($bg)

# ---- photo panel (right), cropped to the panel's aspect ratio -----------------
$panelAspect = $PanelW / $H
$cropH = [int]($src.Height * $CropHeight)
$cropW = [int]($cropH * $panelAspect)
if ($cropW -gt $src.Width) { $cropW = $src.Width; $cropH = [int]($cropW / $panelAspect) }
$cropX = [int](($src.Width - $cropW) / 2)
$cropY = [int]($src.Height * $CropTop)
if (($cropY + $cropH) -gt $src.Height) { $cropY = $src.Height - $cropH }

$srcRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)
$dstRect = New-Object System.Drawing.Rectangle(($W - $PanelW), 0, $PanelW, $H)
$g.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

# ---- text block (left) --------------------------------------------------------
$serif = if ([System.Drawing.FontFamily]::Families.Name -contains "Georgia") { "Georgia" } else { "Times New Roman" }
$sans  = if ([System.Drawing.FontFamily]::Families.Name -contains "Segoe UI") { "Segoe UI" } else { "Arial" }

$fName = New-Object System.Drawing.Font($serif, 60, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fRole = New-Object System.Drawing.Font($sans, 23, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fUrl  = New-Object System.Drawing.Font($sans, 21, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

$brAccent = New-Object System.Drawing.SolidBrush($accent)
$brBody   = New-Object System.Drawing.SolidBrush($body)

# GDI+ has no letter-spacing, so the uppercase role lines are drawn per-glyph.
# GenericTypographic gives tight widths (the default format pads each call), but
# it measures a lone space as ~0, so spaces get an explicit width.
$fmt = [System.Drawing.StringFormat]::GenericTypographic
function Draw-Tracked {
  param($gfx, [string]$text, $font, $brush, [single]$x, [single]$y, [single]$track, $fmt)
  $cx = $x
  foreach ($ch in $text.ToCharArray()) {
    if ($ch -eq ' ') { $cx += $font.Size * 0.42 + $track; continue }
    $s = [string]$ch
    $gfx.DrawString($s, $font, $brush, $cx, $y, $fmt)
    $cx += $gfx.MeasureString($s, $font, [System.Drawing.PointF]::Empty, $fmt).Width + $track
  }
  return $cx
}

$y = 196.0
$g.DrawString("Max Spohn", $fName, $brAccent, $Pad, $y, $fmt)
$y += 88

Draw-Tracked $g "PHD CANDIDATE IN PUBLIC POLICY" $fRole $brAccent $Pad $y 1.8 $fmt | Out-Null
$y += 36
Draw-Tracked $g "HARVARD KENNEDY SCHOOL" $fRole $brAccent $Pad $y 1.8 $fmt | Out-Null
$y += 54

# thin accent rule, then the domain
$pen = New-Object System.Drawing.Pen($accent, 2)
$pen.Color = [System.Drawing.Color]::FromArgb(90, $accent.R, $accent.G, $accent.B)
$g.DrawLine($pen, $Pad, $y, ($Pad + 92), $y)
$y += 22
$g.DrawString("maxspohn.com", $fUrl, $brBody, $Pad, $y, $fmt)

# ---- save as JPEG ------------------------------------------------------------
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$prms = New-Object System.Drawing.Imaging.EncoderParameters(1)
$prms.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 90L)
$bmp.Save($OutFile, $codec, $prms)

$g.Dispose(); $bmp.Dispose(); $src.Dispose()
"Wrote $OutFile ({0:N0} bytes)" -f (Get-Item $OutFile).Length
