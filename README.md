<p align="center">
  <img src="assets/repo_banner.png" width="600" alt="FoxuLaserCuts Banner">
</p>

# FoxuLaserCuts 🦊

**Visor de Catálogos CNC** - Aplicación de escritorio portable para explorar y organizar diseños de corte láser.

## ✨ Características

- 🗂️ **Navegación Jerárquica** - Explora categorías y subcategorías
- 🔍 **Búsqueda Instantánea** - Indexado para búsquedas en tiempo real
- ⚡ **Modo Eco** - Optimización automática de GPU (F9 toggle)
- 📦 **Portable** - Un solo EXE, sin instalación
- 💾 **Smart Cache** - Sistema de caché inteligente

## 🚀 Descarga

Descarga la última versión desde [Releases](../../releases).

## 🛠️ Desarrollo

```powershell
# Procesar imágenes (requiere Node.js + Sharp)
npm install sharp
node ingest_sharp.js

# Compilar EXE portable
powershell -ExecutionPolicy Bypass -File Build_EXE.ps1

# Servidor de desarrollo
npx http-server -p 8080 -o
```

## 📊 Stack Técnico

- Frontend: HTML5, CSS3, JavaScript Vanilla
- Imágenes: AVIF (Sharp)
- Empaquetado: C# Self-Extractor

## 📝 Licencia

MIT

---

*🦊 FoxuLabs*
