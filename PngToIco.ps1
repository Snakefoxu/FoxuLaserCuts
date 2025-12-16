Add-Type -AssemblyName System.Drawing

$PngPath = "$PSScriptRoot\assets\app_icon.png"
$IcoPath = "$PSScriptRoot\assets\app_icon.ico"

if (-not (Test-Path $PngPath)) {
    Write-Error "PNG no encontrado: $PngPath"
    exit
}

$Bitmap = [System.Drawing.Bitmap]::FromFile($PngPath)

# Crear archivo ICO (Header + Directory + Data)
# Hack simple: Usamos un FileStream y escribimos la estructura ICO cruda
# O mas facil: Usamos el Icon.FromHandle de .NET (Calidad baja, pero funciona)
# O mejor: Redimensionamos a 256x256 y guardamos como PNG dentro de un ICO container.

# Vamos a usar la tecnica de Icon.FromHandle (Simple y nativo)
try {
    # Redimensionar a 64x64 o 128x128 para icono seguro
    $Thumb = $Bitmap.GetThumbnailImage(128, 128, $null, [IntPtr]::Zero)
    $Icon = [System.Drawing.Icon]::FromHandle($Thumb.GetHicon())
    
    $Stream = [System.IO.File]::Open($IcoPath, [System.IO.FileMode]::Create)
    $Icon.Save($Stream)
    $Stream.Close()
    
    $Icon.Dispose()
    $Thumb.Dispose()
    $Bitmap.Dispose()
    
    Write-Host "Generado: $IcoPath" -ForegroundColor Green
}
catch {
    Write-Error "Fallo la conversion: $_"
}
