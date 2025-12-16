# CNC File Catalog Web App

## Context
Web-based catalog application to manage and organize CNC files. The application should run locally in the current workspace.

## Goals
1.  **Catalog System**: Organize CNC files by categories.
2.  **Hybrid Storage**:
    *   **Local**: Lightweight preview images (thumbnails) and metadata database.
    *   **Cloud (HuggingFace)**: Actual heavy CNC files stored in the cloud.
3.  **Performance**: The app must handle previews efficiently ("que pesen muy poco").
4.  **Aesthetics**: Premium, modern design (Dark mode, Vibrant colors).
5.  **Tech Stack**: Zero-dependency Web App (HTML/CSS/JS) to ensure instant compatibility without needing complex system installations (Node.js was found missing).

## Requirements
*   **Search & Filter**: [x] Find files by specific categories or names.
*   **Download Flow**:
    - [x] **Preparar Entorno**: Instalar nodejs, crear `task.md`, configurar `.gitignore`
    - [x] **Desarrollo**: Crear estructura base (HTML/JS/CSS)
    - [x] **Ingesta**: Script PowerShell para indexar archivos CNC
    - [x] **Compilación**: Generar EXE nativo con C# (No Electron)
    - [x] **Branding**: Renombrar a "FoxuLaserCuts" y remasterizar icono
    - [x] **Optimización de Rendimiento (V6-V11)**
        - [x] Infinite Scroll (Paginación JS).
        - [x] Ingesta Masiva (List<T> PowerShell).
        - [x] **Smart Auto-Clean Cache** (BuildID único).
        - [x] **Modo Eco Automático** (Detección GPU).
    - [x] **Limpieza del Sistema**
        - [x] Eliminar carpetas de caché legacy (V6, V10).
    - [x] **Release Final Candidate** <!-- id: 5 -->Compilar versión portable con dataset masivo (4k+ items)
*   **Visuals**: [x] High-quality UI with animations and glassmorphism effects.
*   **Branding**: [x] Custom Mascot Icon (Fox) & Banner integrated into EXE.
*   **Data Structure**: [x] JSON-based catalog system for easy manual or automated updates.
*   **Portable EXE**: [x] Native Windows Executable with embedded resources.
