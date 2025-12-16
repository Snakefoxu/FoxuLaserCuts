/**
 * Ingesta Masiva con Sharp - AVIF Ultra-Comprimido
 * Configuración: Q30, effort 9, chromaSubsampling 4:2:0, 300px width
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// Configuración
const SOURCE_DIR = 'C:\\Users\\snake\\Documents\\Descargas MEGA\\Geek Madness - CNC Laser Cut Pack';
const PREVIEW_DIR = './previews';
const DB_FILE = './js/db.js';

const CONFIG = {
    width: 400,           // Previews a 400px (buena calidad)
    quality: 30,          // Ultra-comprimido (imperceptible según benchmark)
    effort: 0,            // Máxima velocidad (archivo ligeramente más grande)
    chromaSubsampling: '4:2:0'  // Reduce info de color sin pérdida visible
};

async function getAllImages(dir) {
    const images = [];

    function scan(currentDir) {
        const items = fs.readdirSync(currentDir);
        for (const item of items) {
            const fullPath = path.join(currentDir, item);
            try {
                const stat = fs.statSync(fullPath);
                if (stat.isDirectory()) {
                    scan(fullPath);
                } else if (/\.(jpg|jpeg|png|webp)$/i.test(item)) {
                    // Extraer jerarquía de carpetas
                    const relativePath = fullPath.replace(SOURCE_DIR, '').replace(/^\\/, '');
                    const parts = relativePath.split('\\');

                    images.push({
                        path: fullPath,
                        name: path.basename(item, path.extname(item)),
                        categoryL1: parts[0] ? parts[0].replace(/^GM - /, '') : 'Otros',
                        categoryL2: parts[1] || '',
                        categoryL3: parts[2] || ''
                    });
                }
            } catch (e) { /* Skip inaccessible files */ }
        }
    }

    scan(dir);
    return images;
}

async function processImages() {
    console.log('🔍 Escaneando imágenes...');
    const images = await getAllImages(SOURCE_DIR);
    console.log(`📊 Encontradas: ${images.length} imágenes\n`);

    // Crear directorio de previews
    if (!fs.existsSync(PREVIEW_DIR)) {
        fs.mkdirSync(PREVIEW_DIR, { recursive: true });
    }

    const dbItems = [];
    let processed = 0;
    let errors = 0;
    let totalOriginalSize = 0;
    let totalCompressedSize = 0;

    for (const img of images) {
        const outputName = `foxu_${processed + 1}.avif`;
        const outputPath = path.join(PREVIEW_DIR, outputName);

        try {
            const originalStat = fs.statSync(img.path);
            totalOriginalSize += originalStat.size;

            await sharp(img.path)
                .resize(CONFIG.width)
                .avif({
                    quality: CONFIG.quality,
                    effort: CONFIG.effort,
                    chromaSubsampling: CONFIG.chromaSubsampling
                })
                .toFile(outputPath);

            const compressedStat = fs.statSync(outputPath);
            totalCompressedSize += compressedStat.size;

            // Crear entrada para DB
            const searchText = `${img.name} ${img.categoryL1} ${img.categoryL2} ${img.categoryL3}`.toLowerCase().trim();

            dbItems.push({
                id: `foxu-${processed + 1}`,
                name: img.name,
                categoryL1: img.categoryL1,
                categoryL2: img.categoryL2,
                categoryL3: img.categoryL3,
                description: `Diseño CNC: ${img.categoryL1}${img.categoryL2 ? ' > ' + img.categoryL2 : ''}`,
                preview: `previews/${outputName}`,
                downloadUrl: 'https://huggingface.co/',
                searchText: searchText
            });

            processed++;

            if (processed % 100 === 0) {
                const ratio = ((1 - totalCompressedSize / totalOriginalSize) * 100).toFixed(1);
                console.log(`  ⏳ Procesadas: ${processed}/${images.length} (-${ratio}% reducción)`);
            }
        } catch (e) {
            errors++;
        }
    }

    // Generar db.js
    console.log('\n📝 Generando base de datos...');
    const dbContent = `/**
 * CNC Catalog Database - AUTO GENERATED (Sharp AVIF Q${CONFIG.quality})
 * Items: ${dbItems.length}
 */
const CATALOG_DB = ${JSON.stringify(dbItems, null, 2)};
`;

    fs.writeFileSync(DB_FILE, dbContent, 'utf8');

    // Resumen final
    const originalMB = (totalOriginalSize / 1024 / 1024).toFixed(1);
    const compressedMB = (totalCompressedSize / 1024 / 1024).toFixed(1);
    const ratio = ((1 - totalCompressedSize / totalOriginalSize) * 100).toFixed(1);

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('✅ INGESTA COMPLETADA');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(`   Imágenes procesadas: ${processed}`);
    console.log(`   Errores: ${errors}`);
    console.log(`   Tamaño Original: ${originalMB} MB`);
    console.log(`   Tamaño Comprimido: ${compressedMB} MB`);
    console.log(`   Reducción: -${ratio}%`);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\n🚀 Ahora ejecuta: powershell -ExecutionPolicy Bypass -File Build_EXE.ps1');
}

processImages().catch(console.error);
