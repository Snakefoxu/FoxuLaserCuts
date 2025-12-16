# FoxuLaserCuts 🦊

**Visor de Catálogos CNC** - Aplicación de escritorio portable para explorar colecciones de diseños de corte láser/CNC.

## ⚠️ Aviso Legal

Este software es únicamente un **visor/organizador de archivos**. Los diseños CNC mostrados en la aplicación **NO son propiedad del desarrollador** de este software. Cada diseño pertenece a su autor/creador original.

Este software no incluye ni distribuye diseños CNC. El usuario es responsable de usar únicamente archivos de los cuales tenga los derechos correspondientes.

## ✨ Características

- 🗂️ **Navegación Jerárquica** - Explora categorías y subcategorías
- 🔍 **Búsqueda Instantánea** - Indexado pre-computado
- ⚡ **Modo Eco** - Optimización automática de GPU (F9 toggle)
- 📦 **Portable** - Un solo EXE, sin instalación
- 💾 **Smart Cache** - Auto-limpieza inteligente

## 🚀 Uso

1. Descarga `FoxuLaserCuts.exe` desde Releases
2. Ejecuta y navega por tus diseños

## 🛠️ Para Desarrolladores

Si quieres crear tu propio catálogo:

```powershell
# Procesar tus imágenes
node ingest_sharp.js

# Compilar EXE
powershell -ExecutionPolicy Bypass -File Build_EXE.ps1
```

## 📝 Licencia

MIT - El código del visor es libre. Los diseños CNC mostrados pertenecen a sus respectivos autores.

---

*Software desarrollado como herramienta de organización personal.*
