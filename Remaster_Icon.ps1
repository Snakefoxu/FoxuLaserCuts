Add-Type -AssemblyName System.Drawing

$SourcePng = "$PSScriptRoot\assets\app_icon.png"
$DestIco = "$PSScriptRoot\assets\app_icon.ico"

# Tamaños estandar de iconos de Windows
$Sizes = @(256, 128, 64, 48, 32, 16)

Write-Host "Iniciando Remasterizado de Icono..." -ForegroundColor Cyan

if (-not (Test-Path $SourcePng)) {
    Write-Error "No se encuentra el icono fuente: $SourcePng"
    exit
}

try {
    # 1. Cargar imagen base
    $Original = [System.Drawing.Bitmap]::FromFile($SourcePng)
    
    # 2. Detectar color de fondo (Esquina superior izquierda) y aplicar transparencia
    $CornerColor = $Original.GetPixel(0, 0)
    Write-Host "  -> Detectado color de fondo: $CornerColor" -ForegroundColor Gray
    
    # Crear bitmap temporal con transparencia
    $Transparent = new-object System.Drawing.Bitmap $Original.Width, $Original.Height
    $Graph = [System.Drawing.Graphics]::FromImage($Transparent)
    $Graph.DrawImage($Original, 0, 0, $Original.Width, $Original.Height)
    
    # Aplicar transparencia (MakeTransparent a veces deja halos, pero es lo mas rapido en PS puro)
    # Una alternativa mejor es un FloodFill, pero requiere mas codigo. 
    # Para la IA generativa, "MakeTransparent" suele funcionar si el fondo es solido.
    $Transparent.MakeTransparent($CornerColor)
    
    # 3. Construir ICO multi-tamano
    # PowerShell no tiene encoder ICO nativo multi-size facil.
    # Usaremos un truco: Guardar el PNG de 256px como el Icono Principal.
    # Para un EXE moderno, a menudo basta con un ICO que contenga la imagen grande.
    # El compilador de C# a veces es quisquilloso.
    
    # Vamos a crear el ICO usando un FileStream binario (Escribiendo cabeceras ICO a mano)
    # Esto garantiza soporte PNG dentro de ICO (Vista+ format) que soporta 256x256
    
    $Stream = [System.IO.File]::Open($DestIco, [System.IO.FileMode]::Create)
    $Writer = [System.IO.BinaryWriter]::new($Stream)
    
    # --- ICO HEADER ---
    $Writer.Write([int16]0) # Reserved
    $Writer.Write([int16]1) # Type (1=Icon)
    $Writer.Write([int16]$Sizes.Count) # Count of images
    
    $ImageBuffers = @()
    $ImageOffsets = @()
    
    $CurrentOffset = 6 + ($Sizes.Count * 16) # Header + Directory Entries
    
    # --- ICO DIRECTORY ---
    foreach ($Size in $Sizes) {
        # Redimensionar
        $SmallBmp = new-object System.Drawing.Bitmap $Size, $Size
        $G = [System.Drawing.Graphics]::FromImage($SmallBmp)
        $G.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $G.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $G.DrawImage($Transparent, 0, 0, $Size, $Size)
        $G.Dispose()
        
        # Convertir a PNG Bytes
        $MemStream = [System.IO.MemoryStream]::new()
        $SmallBmp.Save($MemStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $Bytes = $MemStream.ToArray()
        
        $ImageBuffers += , $Bytes # Add as array element
        
        # Escribir entrada de directorio
        $w = if ($Size -eq 256) { 0 } else { $Size }
        $Writer.Write([byte]$w)      # Width
        $Writer.Write([byte]$w)      # Height
        $Writer.Write([byte]0)       # Palette
        $Writer.Write([byte]0)       # Reserved
        $Writer.Write([int16]0)      # Planes
        $Writer.Write([int16]32)     # BPP
        $Writer.Write([int]$Bytes.Length) # Size
        $Writer.Write([int]$CurrentOffset) # Offset
        
        $CurrentOffset += $Bytes.Length
        $SmallBmp.Dispose()
    }
    
    # --- ICO DATA ---
    foreach ($Buffer in $ImageBuffers) {
        $Writer.Write($Buffer)
    }
    
    $Writer.Close()
    $Stream.Close()
    $Transparent.Dispose()
    $Original.Dispose()
    $Graph.Dispose()
    
    Write-Host "EXITO: Icono remasterizado generado en $DestIco" -ForegroundColor Green

}
catch {
    Write-Error "Fallo remasterizando icono: $_"
}
