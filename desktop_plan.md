# Implementación de Versión de Escritorio (Desktop App)

## Problema Detectado
El usuario percibe el producto actual como una "Página Web" porque se abre en el navegador con pestañas y barras de navegación.

## Solución Técnica: Wrapper Nativo
Sin reescribir todo el código visual (que ya es premium), encapsularemos la interfaz en un proceso de ventana independiente usando el flag `--app` de Edge/Chrome (disponible en todo Windows moderno).

### Componentes Nuevos
1.  **`Lanzador_Catalogo.bat`**: Script ejecutable de doble clic.
2.  **Lógica**:
    *   Detecta la ruta absoluta actual.
    *   Ejecuta `msedge` (Motor Chromium nativo de Windows) en modo `--app`.
    *   Abre la ventana con tamaño específico y sin bordes de navegador.

## Resultado Final
*   El usuario hace doble clic en el archivo.
*   Se abre una ventana oscura, limpia, sin barras de URL.
*   Icono propio en la barra de tareas.
*   Comportamiento 100% de App de Escritorio.

