/**
 * Benchmark de Compresión AVIF con Sharp
 * Prueba diferentes niveles de calidad en 5 imágenes grandes
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SOURCE_DIR = 'C:\\Users\\snake\\Documents\\Descargas MEGA\\Geek Madness - CNC Laser Cut Pack';
const OUTPUT_DIR = './benchmark_results';
const QUALITIES = [30, 40, 50, 60, 70];
const TARGET_WIDTH = 400; // Igual que las previews actuales

async function findLargestImages(dir, count = 5) {
    const files = [];

    function scanDir(currentDir) {
        const items = fs.readdirSync(currentDir);
        for (const item of items) {
            const fullPath = path.join(currentDir, item);
            const stat = fs.statSync(fullPath);
            if (stat.isDirectory()) {
                scanDir(fullPath);
            } else if (/\.(jpg|jpeg|png|webp)$/i.test(item)) {
                files.push({ path: fullPath, size: stat.size });
            }
        }
    }

    scanDir(dir);
    return files.sort((a, b) => b.size - a.size).slice(0, count);
}

async function benchmark() {
    console.log('🔍 Buscando las 5 imágenes más grandes...\n');

    if (!fs.existsSync(OUTPUT_DIR)) {
        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    }

    const largestImages = await findLargestImages(SOURCE_DIR, 5);

    console.log('📊 Imágenes seleccionadas:');
    largestImages.forEach((img, i) => {
        console.log(`  ${i + 1}. ${path.basename(img.path)} (${(img.size / 1024).toFixed(1)} KB)`);
    });
    console.log('\n');

    const results = [];

    for (const imageInfo of largestImages) {
        const imageName = path.basename(imageInfo.path, path.extname(imageInfo.path));
        console.log(`\n🖼️  Procesando: ${imageName}`);

        const imageResults = {
            name: imageName,
            originalSize: imageInfo.size,
            compressions: []
        };

        for (const quality of QUALITIES) {
            const outputPath = path.join(OUTPUT_DIR, `${imageName}_q${quality}.avif`);

            try {
                await sharp(imageInfo.path)
                    .resize(TARGET_WIDTH)
                    .avif({
                        quality: quality,
                        effort: 9,
                        chromaSubsampling: '4:2:0'
                    })
                    .toFile(outputPath);

                const outputStat = fs.statSync(outputPath);
                const ratio = ((1 - outputStat.size / imageInfo.size) * 100).toFixed(1);

                imageResults.compressions.push({
                    quality,
                    size: outputStat.size,
                    ratio: ratio
                });

                console.log(`    Q${quality}: ${(outputStat.size / 1024).toFixed(1)} KB (-${ratio}%)`);
            } catch (err) {
                console.log(`    Q${quality}: ERROR - ${err.message}`);
            }
        }

        results.push(imageResults);
    }

    // Resumen final
    console.log('\n\n📈 RESUMEN FINAL:');
    console.log('═══════════════════════════════════════════════════════════');
    console.log('Quality | Tamaño Promedio | Reducción Promedio');
    console.log('───────────────────────────────────────────────────────────');

    for (const quality of QUALITIES) {
        const sizes = results.map(r => r.compressions.find(c => c.quality === quality)?.size || 0);
        const avgSize = sizes.reduce((a, b) => a + b, 0) / sizes.length;
        const avgRatio = results.map(r => parseFloat(r.compressions.find(c => c.quality === quality)?.ratio || 0))
            .reduce((a, b) => a + b, 0) / results.length;

        console.log(`  Q${quality}   |   ${(avgSize / 1024).toFixed(1)} KB       |   -${avgRatio.toFixed(1)}%`);
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('\n✅ Resultados guardados en:', OUTPUT_DIR);
    console.log('👁️  Revisa visualmente los archivos para elegir la calidad óptima.');
}

benchmark().catch(console.error);
