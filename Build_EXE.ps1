<#
    CNC Nexus - Single EXE Builder (Massive Resource Support)
    Genera un ejecutable C# nativo usando Recursos Embebidos.
    Soluciona limites de memoria y argumentos de linea de comandos (via .rsp).
#>

$AppName = "FoxuLaserCuts"
$OutputPath = "$PSScriptRoot\$AppName.exe"
$SourceDir = $PSScriptRoot
$CompilerPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

Write-Host "Iniciando compilacion AVANZADA (Modo Masivo)..." -ForegroundColor Cyan

# 1. Recolectar Archivos y generar archivo de respuesta (.rsp)
$ExcludedExtensions = @(".exe", ".cs", ".ps1", ".bat", ".tpl", ".md", ".git", ".rsp", ".log")
$RspFile = "$PSScriptRoot\compiler_args.rsp"
$RspContent = @()

# Opciones base
$RspContent += "/target:winexe"
$RspContent += "/out:`"$OutputPath`""

$AllFiles = Get-ChildItem -Path $SourceDir -Recurse -File
$FileCount = 0

foreach ($Item in $AllFiles) {
    if ($ExcludedExtensions -contains $Item.Extension) { continue }
    if ($Item.FullName -match "\\.git\\") { continue }
    if ($Item.Name -eq "package.json" -or $Item.Name -eq "package-lock.json") { continue }
    if ($Item.Name -eq "compiler_args.rsp") { continue }
    
    # Ruta relativa para usar como identificador de recurso
    $RelPath = $Item.FullName.Substring($SourceDir.Length + 1).Replace("\", "/")
    
    # IMPORTANTE: Reemplazar espacios en rutas si es necesario, aunque .rsp suele manejarlo mejor
    # Formato: /resource:RutaReal,IdentificadorLogico
    $RspContent += "/resource:`"$($Item.FullName)`",$RelPath"
    
    # Progreso visual para no floodear consola
    if ($FileCount % 500 -eq 0) { Write-Host "  ... Procesados $FileCount recursos" -ForegroundColor Gray }
    $FileCount++
}

Write-Host "  -> Total Recursos a incrustar: $FileCount" -ForegroundColor Yellow

# Icono
$IconPath = "$SourceDir\assets\app_icon.ico"
if (Test-Path $IconPath) {
    $RspContent += "/win32icon:`"$IconPath`""
    Write-Host "  + Icono Application: app_icon.ico" -ForegroundColor Cyan
}

# 2. Generar Codigo C# (Extractor de Recursos)
$BuildId = Get-Date -Format "yyyyMMddHHmmss"

$CSharpCode = @"
using System;
using System.IO;
using System.Diagnostics;
using System.Reflection;
using System.Threading;

namespace CNCNexus 
{
    class Program 
    {
        // Build ID unico generado al compilar
        const string BuildId = "$BuildId";
        const string CacheFolder = "FoxuLaserCuts_Data";

        static void Main(string[] args) 
        {
            try 
            {
                // 1. Definir Ruta de Cache Estable (Siempre la misma)
                string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string tempPath = Path.Combine(appData, CacheFolder); 
                string versionFile = Path.Combine(tempPath, "version.txt");

                // 2. Verificar Integridad
                bool needsUpdate = true;

                if (Directory.Exists(tempPath) && File.Exists(versionFile)) 
                {
                    string cachedVersion = File.ReadAllText(versionFile).Trim();
                    if (cachedVersion == BuildId) 
                    {
                        needsUpdate = false; // Version coincide, inicio rapido
                    }
                }

                // 3. Actualizar Cache si es necesario
                if (needsUpdate) 
                {
                    // Intentar limpiar limpia, con retries por si hay locks
                    if (Directory.Exists(tempPath)) 
                    {
                        try { Directory.Delete(tempPath, true); } catch { /* Ignore locks */ }
                    }
                    
                    Directory.CreateDirectory(tempPath);
                    ExtractResources(tempPath);
                    
                    // Marcar version
                    File.WriteAllText(versionFile, BuildId);
                }

                // 4. Buscar Navegador
                string browserPath = FindBrowser();
                if (string.IsNullOrEmpty(browserPath)) 
                {
                    Process.Start(Path.Combine(tempPath, "index.html"));
                    return;
                }

                // 5. Lanzar App
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = browserPath;
                psi.Arguments = "--app=\"file:///" + Path.Combine(tempPath, "index.html").Replace("\\", "/") + "\" --window-size=1200,800 --start-maximized";
                psi.UseShellExecute = false;
                
                Process app = Process.Start(psi);
            }
            catch (Exception ex) 
            {
                File.WriteAllText("error_log.txt", ex.ToString());
            }
        }

        static string FindBrowser() 
        {
            string[] paths = {
                @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Google\Chrome\Application\chrome.exe"
            };

            foreach (var p in paths) if (File.Exists(p)) return p;
            return null;
        }

        static void ExtractResources(string basePath) 
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            string[] resourceNames = assembly.GetManifestResourceNames();

            // OPTIMIZACION: Paralelismo masivo par IO
            System.Threading.Tasks.Parallel.ForEach(resourceNames, resourceName => 
            {
                string relPath = resourceName;
                string targetPath = Path.Combine(basePath, relPath.Replace("/", "\\"));
                
                Directory.CreateDirectory(Path.GetDirectoryName(targetPath));

                using (Stream stream = assembly.GetManifestResourceStream(resourceName)) 
                using (FileStream fileStream = new FileStream(targetPath, FileMode.Create, FileAccess.Write, FileShare.None, 4096, true)) 
                {
                    if (stream != null) stream.CopyTo(fileStream);
                }
            });
        }
    }
}
"@

# 3. Guardar Fuente Temporal
$SourceFile = "$PSScriptRoot\temp_binder.cs"
[System.IO.File]::WriteAllText($SourceFile, $CSharpCode)

# Agregar source file al RSP
$RspContent += "`"$SourceFile`""

# 4. Guardar archivo RSP
[System.IO.File]::WriteAllLines($RspFile, $RspContent)

# 5. Compilar usando RSP
Write-Host "Compilando ejecutable nativo (usando RSP)..." -ForegroundColor Yellow
Start-Process -FilePath $CompilerPath -ArgumentList "@`"$RspFile`"" -Wait -NoNewWindow

# 6. Limpieza
Remove-Item $SourceFile
Remove-Item $RspFile -ErrorAction SilentlyContinue

if (Test-Path $OutputPath) {
    Write-Host "EXITO OMEGA: Generado $OutputPath" -ForegroundColor Green
    $Size = (Get-Item $OutputPath).Length / 1MB
    Write-Host "  -> Tamaño Final: $([math]::Round($Size, 2)) MB" -ForegroundColor Green
}
else {
    Write-Host "ERROR CRITICO: Fallo la compilacion." -ForegroundColor Red
}
