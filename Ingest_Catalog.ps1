<#
    CNC Nexus - Ingestor Automático (Optimized for Mass Storage)
    Scanea una ruta externa, procesa imagenes a JPG comprimido y genera la DB.
#>

param (
    [string]$SourcePath = "C:\Users\snake\Documents\Descargas MEGA\Geek Madness - CNC Laser Cut Pack"
)

# Configuración
$DestPreviewDir = "$PSScriptRoot\previews"
$DbFile = "$PSScriptRoot\js\db.js"
$ValidExtensions = @(".jpg", ".jpeg", ".png", ".webp")
$MaxPreviewWidth = 350 # Reduced for mass storage optimization
$JpegQuality = 55      # Aggressive compression

# Cargar System.Drawing
Add-Type -AssemblyName System.Drawing

$Items = New-Object System.Collections.Generic.List[object]
$Counter = 1

# --- Función de Optimización JPG (Mejor para fotografías) ---
function Save-OptimizedJpeg {
    param ($Bitmap, $Path, $Quality)
    
    $Codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $EncoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $EncoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
    
    $Bitmap.Save($Path, $Codec, $EncoderParams)
}

# --- Función de Procesamiento ---
function Process-Image {
    param (
        [string]$InputPath,
        [string]$OutputPath
    )
    try {
        if (Test-Path $OutputPath) { return $true } # Skip if exists

        # Validación 1: Tamaño mínimo (evita archivos de 0 bytes o corruptos header-only)
        $ItemInfo = Get-Item $InputPath
        if ($ItemInfo.Length -lt 1024) { throw "Archivo demasiado pequeño ($($ItemInfo.Length) bytes)" }

        $img = [System.Drawing.Image]::FromFile($InputPath)
        
        # Validación 2: Forzar decodificación (Access properties usually triggers decode)
        # Algunos encoders defectuosos fallan aqui
        $dummy = $img.Width 
        
        # Calcular nueva altura manteniendo ratio
        $newHeight = [int]($img.Height * ($MaxPreviewWidth / $img.Width))
        
        $bmp = new-object System.Drawing.Bitmap $MaxPreviewWidth, $newHeight
        $graph = [System.Drawing.Graphics]::FromImage($bmp)
        $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graph.DrawImage($img, 0, 0, $MaxPreviewWidth, $newHeight)
        
        # Guardar
        Save-OptimizedJpeg -Bitmap $bmp -Path $OutputPath -Quality $JpegQuality
        
        # Validación 3: Verificar resultado
        if ((Get-Item $OutputPath).Length -eq 0) { throw "Output generado vacio" }
        
        $img.Dispose()
        $bmp.Dispose()
        $graph.Dispose()
        return $true
    }
    catch {
        Write-Host "    [!] Error procesando/Corrupto: $($InputPath | Split-Path -Leaf)" -ForegroundColor Red
        # Limpieza
        if ($img) { $img.Dispose() }
        if ($bmp) { $bmp.Dispose() }
        if ($graph) { $graph.Dispose() }
        if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
        return $false
    }
}

# --- Función de Mapeo Inteligente ---
function Get-SmartCategory {
    param ($Name, $ParentFolder)
    $Text = "$Name $ParentFolder".ToLower()
    
    # Diccionario Expandido y Refinado (v5 - Jerarquia Funcion > Forma)
    $Categories = [ordered]@{
        "ILUMINACION"   = @("lamp", "lampara", "light", "luz", "candle", "vela", "lantern", "linterna", "shade", "pantalla", "led", "chandelier")
        "RELOJES"       = @("clock", "reloj", "watch", "time")
        "JUGUETES"      = @("puzzle", "3d", "toy", "juguete", "gun", "pistola", "sword", "espada", "knife", "cuchillo", "shield", "escudo", "game", "juego", "chess", "ajedrez", "doll", "muñeca", "miniature")
        "MUEBLES"       = @("chair", "silla", "table", "mesa", "desk\b", "escritorio", "shelf", "estante", "furniture", "mueble", "bench", "banco", "stool", "taburete")
        "CAJAS"         = @("box", "caja", "chest", "cofre", "case", "estuche", "organizer", "joyero", "jewelry", "basket", "cesta", "container", "contenedor", "gift", "regalo", "storage")
        "ARQUITECTURA"  = @("tower", "torre", "building", "edificio", "castle", "castillo", "house\b", "casa\b", "church", "iglesia", "temple", "templo", "pagoda", "bridge", "puente", "monument", "monumento", "eiffel", "pisa", "big ben", "statue", "estatua", "city", "ciudad", "architecture", "arquitectura", "cabin", "cabana", "villa", "mansion")
        "ORGANIZADORES" = @("holder", "soporte", "stand", "dock", "phone", "movil", "pencil", "lapiz", "desk org")
        "DECORACION"    = @("mandala", "wall", "pared", "panel", "art", "sign", "letrero", "mirror", "espejo", "frame", "marco", "tree", "arbol", "flower", "flor", "plant", "planta", "hoja", "leaf", "rose", "rosa", "lotus", "navidad", "christmas", "xmas", "easter", "pascua", "halloween", "calavera", "skull", "skeleton", "esqueleto", "mask", "mascara", "viking", "celtic", "egypt")
        "VEHICULOS"     = @("car\b", "coche", "auto", "truck", "camion", "jeep", "bike", "moto", "plane", "avion", "heli", "train", "tren", "boat", "barco", "ship", "sub", "tank", "tanque", "vehicle", "transporte", "rocket", "cohete", "ufo", "ovni", "wing", "ala", "fly", "vuelo")
        "ANIMALES"      = @("dog", "perro", "cat\b", "gato", "lobo", "wolf", "bear", "oso", "lion", "leon", "tiger", "tigre", "eagle", "aguila", "bird", "ave\b", "owl", "buho", "fish", "pez", "shark", "tiburon", "dolphin", "delfin", "butterfly", "mariposa", "bull", "toro", "cow", "vaca", "horse", "caballo", "elephant", "elefante", "deer", "venado", "ciervo", "rabbit", "conejo", "bunny", "fox", "zorro", "snake", "serpiente", "cobra", "spider", "araña", "insect", "bicho", "frog", "rana", "tortuga", "turtle", "lizard", "lagarto", "gecko", "dragon", "dino", "saurus", "rex", "raptor", "triceratops", "stego", "bronto", "jurassic", "animal", "zoo", "safari", "dimetrodon", "mamut", "mammoth", "ciervo", "elk", "moose", "rhinoceros", "rino", "zebra", "cebra", "giraffe", "jirafa", "hippo", "hipopo")
    }

    foreach ($Cat in $Categories.Keys) {
        foreach ($Key in $Categories[$Cat]) {
            # Regex avanzado: \b para limites de palabra, o coincidencia flexible si no tiene \b
            # Si la keyword tiene \b, la respetamos. Si no, hacemos match laxo pero seguro.
            
            $Pattern = $Key
            if ($Key -notmatch "\\b") { 
                # Si no tiene boundary explicito, añadimos boundaries automáticos para palabras cortas peligrosas
                if ($Key.Length -le 4) { $Pattern = "\b$Key\b" }
            }

            if ($Text -match $Pattern) { return $Cat }
        }
    }
    
    # Intento secundario: Si la carpeta padre tiene nombre util
    if ($ParentFolder -match "box") { return "CAJAS" }
    if ($ParentFolder -match "anim") { return "ANIMALES" }
    
    return "OTROS"
}

# 1. Escanear Directorios (Recursivo)
Write-Host ">>> Escaneando directorio fuente (esto puede tardar)..." -ForegroundColor Cyan
# ... (rest stays same until loop) ...
$Files = Get-ChildItem -Path $SourcePath -Recurse -File | Where-Object { $ValidExtensions -contains $_.Extension.ToLower() }
Write-Host ">>> Encontrados $($Files.Count) archivos. Iniciando procesamiento masivo..." -ForegroundColor Cyan

# Crear directorio previews
if (!(Test-Path $DestPreviewDir)) { New-Item -ItemType Directory -Path $DestPreviewDir | Out-Null }

foreach ($File in $Files) {
    # Branding Foxu
    $Prefix = "foxu_"
    $PreviewFileName = "${Prefix}${Counter}.jpg" # JPG Extension (mejor compresión para fotografías)
    $DestPath = "$DestPreviewDir\$PreviewFileName"
    
    # Progreso visual cada 100 items
    if ($Counter % 100 -eq 0) { 
        $Percent = ($Counter / $Files.Count) * 100
        Write-Progress -Activity "Ingestando Catálogo" -Status "Procesando item $Counter de $($Files.Count)" -PercentComplete $Percent
    }

    # Procesar imagen
    $result = Process-Image -InputPath $File.FullName -OutputPath $DestPath
    
    if ($result) {
        $DesignName = $File.BaseName
        
        # Extraer jerarquía de carpetas (hasta 3 niveles)
        $RelativePath = $File.DirectoryName.Replace($SourcePath, "").TrimStart("\")
        $PathParts = $RelativePath -split "\\"
        
        # Nivel 1: Categoría Madre (limpia "GM - " prefix)
        $CategoryL1 = if ($PathParts.Length -ge 1) { $PathParts[0] -replace "^GM - ", "" } else { "Otros" }
        
        # Pre-compute search text (lowercase for instant search)
        $SearchText = ("$DesignName $CategoryL1").ToLower().Trim()
        
        # Crear Objeto DB
        $Obj = [PSCustomObject]@{
            id          = "foxu-$Counter"
            name        = $DesignName
            category    = $CategoryL1
            description = "Dise\u00f1o CNC: $CategoryL1"
            preview     = "previews/$PreviewFileName"
            downloadUrl = "https://huggingface.co/"
            searchText  = $SearchText
        }
        $Items.Add($Obj)
        
        $Counter++
    }
    
    # NO LIMIT: Loop continues until end
}

# 2. Generar DB.JS
Write-Host ">>> Generando base de datos..." -ForegroundColor Cyan

$JsContent = @"
/**
 * CNC Catalog Database - AUTO GENERATED
 * Source: $SourcePath
 */
const CATALOG_DB = [
"@

foreach ($Item in $Items) {
    $JsContent += @"
    {
        "id": "$($Item.id)",
        "name": "$($Item.name)",
        "category": "$($Item.category)",
        "description": "$($Item.description)",
        "preview": "$($Item.preview)",
        "downloadUrl": "$($Item.downloadUrl)",
        "searchText": "$($Item.searchText)"
    },
"@
}

$JsContent += "];
// Pre-indexed for fast search. Use item.searchText.includes(query) instead of toLowerCase() at runtime."

Set-Content -Path $DbFile -Value $JsContent -Encoding UTF8

Write-Host ">>> COMPLETADO. Items importados: $($Items.Count)" -ForegroundColor Green
Write-Host ">>> Ahora ejecuta 'Lanzar_App.bat' o 'Build_EXE.ps1'." -ForegroundColor Green
