import os
import json
import time
import numpy as np

# Intentar importar TensorFlow (el usuario debe instalarlo: pip install tensorflow pillow)
try:
    import tensorflow as tf
    from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
    from tensorflow.keras.preprocessing import image
    HAS_TF = True
except ImportError:
    print("ERROR: Necesitas instalar TensorFlow y Pillow.")
    print("Ejecuta: pip install tensorflow pillow numpy")
    HAS_TF = False

# Configuración
# Ajusta esta ruta a tu carpeta real
SOURCE_PATH = r"C:\Users\snake\Documents\Descargas MEGA\Geek Madness - CNC Laser Cut Pack"
OUTPUT_DB = "ai_categories.json"

def classify_images():
    if not HAS_TF: return

    print("Cargando modelo MobileNetV2... (esto puede tardar la primera vez)")
    model = MobileNetV2(weights='imagenet')
    
    results = {}
    
    # Recorrer archivos
    print(f"Escaneando: {SOURCE_PATH}")
    count = 0
    
    for root, dirs, files in os.walk(SOURCE_PATH):
        for file in files:
            if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                img_path = os.path.join(root, file)
                
                try:
                    # Cargar y preprocesar imagen
                    img = image.load_img(img_path, target_size=(224, 224))
                    x = image.img_to_array(img)
                    x = np.expand_dims(x, axis=0)
                    x = preprocess_input(x)
                    
                    # Predicción
                    preds = model.predict(x, verbose=0)
                    # Decoded: lista de tuplas (class_id, class_name, probability)
                    decoded = decode_predictions(preds, top=3)[0]
                    
                    # Obtener etiquetas
                    tags = [label for (_, label, prob) in decoded if prob > 0.1]
                    
                    results[file] = {"path": img_path, "ai_tags": tags}
                    print(f"[OK] {file} -> {tags} (Top: {decoded[0][1]} {decoded[0][2]:.2f})")
                    
                except Exception as e:
                    print(f"[ERROR] {file}: {e}")
                
                count += 1
                if count % 100 == 0:
                    with open(OUTPUT_DB, 'w') as f:
                        json.dump(results, f, indent=2)

    with open(OUTPUT_DB, 'w') as f:
        json.dump(results, f, indent=2)
    print("Clasificación AI completada. Archivo generado: ai_categories.json")

if __name__ == "__main__":
    if HAS_TF:
        classify_images()
    else:
        input("Presiona ENTER para salir...")
