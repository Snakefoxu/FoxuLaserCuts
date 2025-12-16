<#
    CNC Nexus - Single EXE Builder (Universal Compatibility)
    Genera un ejecutable C# nativo usando Recursos Embebidos.
    Soporte: Windows 10/11 (x86, x64, ARM via Emulacion)
#>

$AppName = "FoxuLaserCuts"
$OutputPath = "$PSScriptRoot\$AppName.exe"
$SourceDir = $PSScriptRoot
$LogFile = "$PSScriptRoot\build_log.txt"

# Deteccion Inteligente del Compilador
$Compilers = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$CompilerPath = $null
foreach ($c in $Compilers) {
    if (Test-Path $c) {
        $CompilerPath = $c
        break
    }
}

if (-not $CompilerPath) {
    Write-Error "CRITICAL: No se encontro compilador C# (csc.exe)."
    exit 1
}

Write-Host "Iniciando compilacion OMEGA (Universal AnyCPU)..." -ForegroundColor Cyan
Write-Host "  -> Compilador: $CompilerPath" -ForegroundColor DarkGray

# 1. Recolectar Archivos y generar archivo de respuesta (.rsp)
$ExcludedExtensions = @(".exe", ".cs", ".ps1", ".bat", ".tpl", ".md", ".git", ".rsp", ".log", ".manifest")
$RspFile = "$PSScriptRoot\compiler_args.rsp"
$RspContent = @()

# Opciones base - AnyCPU es clave para compatibilidad universal
$RspContent += "/target:winexe"
$RspContent += "/platform:anycpu"
$RspContent += "/out:`"$OutputPath`""
$RspContent += "/optimize+"

# Manifest para compatibilidad Win10/11
$ManifestPath = "$PSScriptRoot\app.manifest"
if (Test-Path $ManifestPath) {
    $RspContent += "/win32manifest:`"$ManifestPath`""
    Write-Host "  + Manifest: app.manifest" -ForegroundColor Cyan
}

$AllFiles = Get-ChildItem -Path $SourceDir -Recurse -File
$FileCount = 0

foreach ($Item in $AllFiles) {
    if ($ExcludedExtensions -contains $Item.Extension) { continue }
    if ($Item.FullName -match "\\.git\\") { continue }
    if ($Item.Name -eq "package.json" -or $Item.Name -eq "package-lock.json") { continue }
    if ($Item.Name -eq "compiler_args.rsp") { continue }
    if ($Item.Name -eq "build_log.txt") { continue }
    
    # Ruta relativa para usar como identificador de recurso
    $RelPath = $Item.FullName.Substring($SourceDir.Length + 1).Replace("\", "/")
    
    # Formato: /resource:RutaReal,IdentificadorLogico
    $RspContent += "/resource:`"$($Item.FullName)`",$RelPath"
    
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

# 2. Generar Codigo C# (Extractor de Recursos con Splash Screen)
$BuildId = Get-Date -Format "yyyyMMddHHmmss"

$CSharpCode = @"
using System;
using System.IO;
using System.Diagnostics;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing;
using System.Drawing.Drawing2D;

// Assembly Version Info
[assembly: AssemblyTitle("FoxuLaserCuts")]
[assembly: AssemblyDescription("CNC Design Catalog by Snakefoxu")]
[assembly: AssemblyCompany("Snakefoxu + Omega Image Cataloger")]
[assembly: AssemblyProduct("FoxuLaserCuts")]
[assembly: AssemblyCopyright("Copyright Snakefoxu 2025")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace CNCNexus 
{
    // --- Splash Screen Form ---
    public class SplashForm : Form
    {
        private Label lblStatus;
        private ProgressBar progressBar;
        
        public SplashForm()
        {
            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Size = new Size(400, 180);
            this.BackColor = Color.FromArgb(19, 19, 31);
            this.ShowInTaskbar = false;
            this.TopMost = true;
            
            // Title
            Label lblTitle = new Label();
            lblTitle.Text = "FoxuLaserCuts";
            lblTitle.Font = new Font("Segoe UI", 18, FontStyle.Bold);
            lblTitle.ForeColor = Color.FromArgb(0, 240, 255);
            lblTitle.AutoSize = true;
            lblTitle.Location = new Point(120, 25);
            this.Controls.Add(lblTitle);
            
            // Status
            lblStatus = new Label();
            lblStatus.Text = "Preparando cache de recursos...";
            lblStatus.Font = new Font("Segoe UI", 10);
            lblStatus.ForeColor = Color.FromArgb(180, 180, 200);
            lblStatus.AutoSize = true;
            lblStatus.Location = new Point(80, 70);
            this.Controls.Add(lblStatus);
            
            // Progress Bar (Marquee style)
            progressBar = new ProgressBar();
            progressBar.Style = ProgressBarStyle.Marquee;
            progressBar.MarqueeAnimationSpeed = 30;
            progressBar.Size = new Size(320, 20);
            progressBar.Location = new Point(40, 110);
            this.Controls.Add(progressBar);
            
            // Version
            Label lblVer = new Label();
            lblVer.Text = "v1.0 OMEGA";
            lblVer.Font = new Font("Segoe UI", 8);
            lblVer.ForeColor = Color.FromArgb(100, 100, 120);
            lblVer.AutoSize = true;
            lblVer.Location = new Point(165, 145);
            this.Controls.Add(lblVer);
        }
        
        public void UpdateStatus(string text)
        {
            if (this.InvokeRequired) {
                this.Invoke(new Action<string>(UpdateStatus), text);
            } else {
                lblStatus.Text = text;
            }
        }
    }

    class Program 
    {
        const string BuildId = "$BuildId";
        const string CacheFolder = "FoxuLaserCuts_Data";
        static SplashForm splash;

        [STAThread]
        static void Main(string[] args) 
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            
            try 
            {
                // 1. Ruta de Cache
                string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string tempPath = Path.Combine(appData, CacheFolder); 
                string versionFile = Path.Combine(tempPath, "version.txt");

                // 2. Verificar Integridad
                bool needsUpdate = true;
                if (Directory.Exists(tempPath) && File.Exists(versionFile)) 
                {
                    try {
                        string cachedVersion = File.ReadAllText(versionFile).Trim();
                        if (cachedVersion == BuildId) needsUpdate = false;
                    } catch {}
                }

                // 3. Actualizar Cache (con Splash)
                if (needsUpdate) 
                {
                    splash = new SplashForm();
                    splash.Show();
                    Application.DoEvents();
                    
                    if (Directory.Exists(tempPath)) 
                    {
                        splash.UpdateStatus("Limpiando cache anterior...");
                        Application.DoEvents();
                        try { Directory.Delete(tempPath, true); } catch { }
                    }
                    
                    Directory.CreateDirectory(tempPath);
                    splash.UpdateStatus("Extrayendo recursos (~10,000 archivos)...");
                    Application.DoEvents();
                    
                    ExtractResources(tempPath);
                    File.WriteAllText(versionFile, BuildId);
                    
                    splash.UpdateStatus("Iniciando aplicacion...");
                    Application.DoEvents();
                    Thread.Sleep(300); // Brief pause to show final message
                    
                    splash.Close();
                    splash.Dispose();
                }

                // 4. Buscar Navegador
                string browserPath = FindBrowser();
                if (string.IsNullOrEmpty(browserPath)) 
                {
                    MessageBox.Show("No se encontro un navegador compatible (Edge o Chrome).", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    Process.Start(Path.Combine(tempPath, "index.html")); // Fallback
                    return;
                }

                // 5. Lanzar App
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = browserPath;
                psi.Arguments = "--app=\"file:///" + Path.Combine(tempPath, "index.html").Replace("\\", "/") + "\" --window-size=1200,800 --start-maximized";
                psi.UseShellExecute = false;
                
                Process.Start(psi);
            }
            catch (Exception ex) 
            {
                MessageBox.Show("Error fatal:\n" + ex.Message, "Error de Inicio", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        static string FindBrowser() 
        {
            string[] paths = {
                @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Google\Chrome\Application\chrome.exe",
                @"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
            };

            foreach (var p in paths) if (File.Exists(p)) return p;
            return null;
        }

        static void ExtractResources(string basePath) 
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            string[] resourceNames = assembly.GetManifestResourceNames();

            // Paralelismo para velocidad
            Parallel.ForEach(resourceNames, resourceName => 
            {
                if (resourceName.EndsWith(".cs") || resourceName.EndsWith(".rsp")) return;

                string relPath = resourceName;
                string targetPath = Path.Combine(basePath, relPath.Replace("/", "\\"));
                
                Directory.CreateDirectory(Path.GetDirectoryName(targetPath));

                using (Stream stream = assembly.GetManifestResourceStream(resourceName)) 
                {
                    if (stream == null) return;
                    using (FileStream fileStream = new FileStream(targetPath, FileMode.Create, FileAccess.Write, FileShare.None, 4096, true)) 
                    {
                        stream.CopyTo(fileStream);
                    }
                }
            });
        }
    }
}
"@

# 3. Guardar Fuente Temporal
$SourceFile = "$PSScriptRoot\temp_binder.cs"
[System.IO.File]::WriteAllText($SourceFile, $CSharpCode)
$RspContent += "`"$SourceFile`""

# 4. Guardar archivo RSP
[System.IO.File]::WriteAllLines($RspFile, $RspContent)

# 5. Compilar
Write-Host "Ejecutando Compilador (Direct Invoke)..." -ForegroundColor Yellow
$CompArg = "@$RspFile"
try {
    & $CompilerPath $CompArg > $LogFile 2>&1
    $LastExitCode = 0
}
catch {
    $LastExitCode = 1
}

# 6. Validacion
# Check $LASTEXITCODE separately as & updates it
if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputPath)) {
    Write-Host "EXITO OMEGA: Generado $OutputPath" -ForegroundColor Green
    $Size = (Get-Item $OutputPath).Length / 1MB
    Write-Host "  -> Tamaño: $([math]::Round($Size, 2)) MB" -ForegroundColor Green
    Write-Host "  -> Log: $LogFile" -ForegroundColor Gray
}
else {
    Write-Host "ERROR CRITICO: Exit Code $LASTEXITCODE" -ForegroundColor Red
    Get-Content $LogFile | Select-Object -Last 20
}

# Limpieza parcial (dejamos log si fallo)
if ($LASTEXITCODE -eq 0) {
    Remove-Item $SourceFile
    Remove-Item $RspFile
}
