Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\icons" | Out-Null
foreach ($size in @(16, 48, 128)) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::FromArgb(109, 40, 217))
  $path = Join-Path $PSScriptRoot "icons\icon$size.png"
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}
