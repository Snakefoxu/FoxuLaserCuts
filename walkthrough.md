# FoxuLaserCuts V1.0 - Manual de Entrega

**Misión**: Convertir >27,000 archivos de diseño CNC en una aplicación de catálogo ultra-rápida, portable, estética y personalizada ("Foxu").

## 🏆 Resultado Final
Has recibido **`FoxuLaserCuts.exe`** (aprox 134 MB).
Este único archivo contiene:
- **~10,000 Diseños** (Todos los JPG/PNG válidos y reparados).
- **Motor Web Moderno**: HTML5/CSS3 con diseño Cyberpunk Neón.
- **Icono Remasterizado**: Alta definición y transparencia.
- **Correcciones OMEGA**: Soporte nativo de "ñ" en descripciones y filtrado automático de imágenes corruptas.

---

## 🚀 Cómo Usar
1.  **Ejecutar**: Doble clic en `FoxuLaserCuts.exe`. No requiere instalación.
2.  **Buscar**: Usa la barra superior. Escribe "Lobo", "Box", "Tree", "Muñeca"...
3.  **Filtrar**: Pulsa los botones de categoría (estilo gafas láser) para filtrar al instante.
4.  **Descargar**:
    - Haz clic en cualquier diseño.
    - Se abre el modal con la imagen gigante.
    - Pulsa el botón **FOXU FIRE** ("Descargar Paquete") para ir a la fuente.

## 🛠️ Cómo Actualizar el Catálogo (Futuro)
Si descargas más archivos y quieres meterlos en la app:

1.  Pon tus carpetas nuevas en la carpeta del proyecto.
2.  Abre PowerShell en esa carpeta.
3.  Ejecuta:
    ```powershell
    .\Ingest_Catalog.ps1
    ```
    *(Esto escaneará todo, ignorará archivos rotos y regenerará el índice)*.
4.  Ejecuta:
    ```powershell
    .\Build_EXE.ps1
    ```
    *(Esto creará un nuevo `FoxuLaserCuts.exe` con el contenido actualizado)*.

## 🎨 Personalización Técnica
El diseño es 100% código (`css/style.css`).
- **Naranja**: Gradiente Foxu (`#ff9d00` a `#ff0055`).
- **Cian**: Gradiente Láser (`#00f0ff` a `#0066ff`).
- **Layout**: Header Flexbox con alineación forzada a la derecha para "Online/Huggingface".

## 🚀 Rendimiento Extremo (V6 + V7 + V12)
Hemos blindado la aplicación para soportar **+100,000 diseños**:
- **OMEGA Core (V12)**: Compatibilidad Universal (Windows 10, 11, x86, x64, ARM).
    - **AnyCPU Global**: Compilado para ejecutarse nativamente en cualquier CPU moderna o antigua.
    - **Robust Ingestion**: El sistema ignora automáticamente imágenes con headers corruptos para asegurar estabilidad.
    - **Manifest AsInvoker**: Evita bloqueos de seguridad de Windows.
- **Infinite Scroll (JS - V6)**: Carga inteligente de elementos (Lotes de 50). El navegador **nunca** se congela.
- **PowerShell List<T> (V6)**: Ingesta ultra-rápida usando listas nativas de .NET.
- **Smart Cleaning Cache (V11)**: El ejecutable se auto-gestiona en `AppData/FoxuLaserCuts_Data`.
    - **Autolimpiable**: Borra versiones antiguas automáticamente al actualizar.
- **Modo Eco Automático (V10)**: Detecta GPUs lentas en <0.5s y activa el modo ahorro.

## 🧠 Lógica de Categorización (V5)
Hemos implementado un sistema de clasificación "Smart Regex" en `Ingest_Catalog.ps1`:
- **Function > Form**: Prioriza la función (Lámpara) sobre la forma (Caballo).
- **Regex Blindado**: Evita falsos positivos.
- **Nuevas Categorías**: Incluye `ARQUITECTURA`, `ORGANIZADORES`, `JUGUETES`.
- **Inteligencia Local (Opcional)**: Se incluye `classify_ai.py` si se desea activar IA.

---
*Created by Snakefoxu + Omega Image Cataloger*
