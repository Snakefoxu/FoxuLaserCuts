/**
 * CNC Catalog App Logic
 * Maneja la carga de datos, filtrado y renderizado UI.
 * Version: Hierarchical Navigation (L1/L2/L3)
 */

// Estado de la aplicación
const AppState = {
    items: [],
    filteredItems: [],
    renderedCount: 0,
    batchSize: 50,

    // Navegación Jerárquica
    currentPath: [], // ['Animals', 'Dragon'] = L1 > L2
    categoriesL1: new Set(),
    categoriesL2: new Map(), // L2 por cada L1
    categoriesL3: new Map(), // L3 por cada L1>L2

    searchQuery: '',
    isLoading: false
};

// Referencias DOM
const dom = {
    gallery: document.getElementById('galleryGrid'),
    filters: document.getElementById('categoryFilters'),
    breadcrumb: document.getElementById('breadcrumb'),
    search: document.getElementById('searchInput'),
    modal: {
        backdrop: document.getElementById('detailModal'),
        close: document.getElementById('closeModal'),
        img: document.getElementById('modalImg'),
        title: document.getElementById('modalTitle'),
        category: document.getElementById('modalCategory'),
        desc: document.getElementById('modalDesc'),
        download: document.getElementById('downloadBtn')
    }
};

/**
 * Inicialización
 */
async function init() {
    try {
        console.log('Iniciando Sistema...');

        // Cargar Preferencia Eco
        if (localStorage.getItem('foxu_eco_auto') === 'true') {
            document.body.classList.add('low-spec');
        }

        if (typeof CATALOG_DB === 'undefined') {
            throw new Error('Base de datos no encontrada');
        }

        AppState.items = CATALOG_DB;

        // Extraer jerarquía de categorías
        buildCategoryHierarchy();

        // Render inicial (L1)
        navigateTo([]);

        setupEventListeners();
        setupInfiniteScroll();
        detectPerformance();

        console.log('Catálogo CNC Iniciado 🚀 [Navegación Jerárquica]');
    } catch (err) {
        console.error(err);
        dom.gallery.innerHTML = `<div style="color:var(--accent); grid-column:1/-1; text-align:center; padding-top: 50px;">
            <i class="fa-solid fa-triangle-exclamation" style="font-size: 3rem; margin-bottom: 20px;"></i><br>
            <strong>Error:</strong><br>${err.message}
        </div>`;
    }
}

/**
 * Benchmark Silencioso de Rendimiento
 */
function detectPerformance() {
    if (localStorage.getItem('foxu_eco_auto') === 'true') {
        document.body.classList.add('low-spec');
        return;
    }

    let frames = 0;
    let start = performance.now();

    function checkFreq() {
        frames++;
        const now = performance.now();
        if (now - start >= 500) {
            const fps = (frames / (now - start)) * 1000;
            if (fps < 45) {
                document.body.classList.add('low-spec');
                localStorage.setItem('foxu_eco_auto', 'true');
            }
        } else {
            requestAnimationFrame(checkFreq);
        }
    }
    requestAnimationFrame(checkFreq);
}

/**
 * Construir jerarquía de categorías desde los items
 */
function buildCategoryHierarchy() {
    AppState.items.forEach(item => {
        const l1 = item.categoryL1 || 'Otros';
        const l2 = item.categoryL2 || '';
        const l3 = item.categoryL3 || '';

        // L1
        AppState.categoriesL1.add(l1);

        // L2
        if (l2) {
            if (!AppState.categoriesL2.has(l1)) {
                AppState.categoriesL2.set(l1, new Set());
            }
            AppState.categoriesL2.get(l1).add(l2);
        }

        // L3
        if (l3) {
            const key = `${l1}/${l2}`;
            if (!AppState.categoriesL3.has(key)) {
                AppState.categoriesL3.set(key, new Set());
            }
            AppState.categoriesL3.get(key).add(l3);
        }
    });
}

/**
 * Navegar a un path específico
 * @param {Array} path - Ej: [] = root, ['Animals'] = L1, ['Animals', 'Dragon'] = L2
 */
function navigateTo(path) {
    AppState.currentPath = path;
    renderBreadcrumb();
    renderCategoryButtons();
    applyFilters();
}

/**
 * Renderizar Breadcrumb
 */
function renderBreadcrumb() {
    dom.breadcrumb.innerHTML = '';

    // Home
    const home = document.createElement('span');
    home.className = 'breadcrumb-item' + (AppState.currentPath.length === 0 ? ' active' : '');
    home.innerHTML = '<i class="fa-solid fa-home"></i> Todos';
    home.onclick = () => navigateTo([]);
    dom.breadcrumb.appendChild(home);

    // Path items
    AppState.currentPath.forEach((segment, index) => {
        // Separator
        const sep = document.createElement('span');
        sep.className = 'breadcrumb-separator';
        sep.textContent = ' > ';
        dom.breadcrumb.appendChild(sep);

        // Segment
        const item = document.createElement('span');
        item.className = 'breadcrumb-item' + (index === AppState.currentPath.length - 1 ? ' active' : '');
        item.textContent = segment;
        item.onclick = () => navigateTo(AppState.currentPath.slice(0, index + 1));
        dom.breadcrumb.appendChild(item);
    });
}

/**
 * Renderizar botones de categoría según el nivel actual
 */
function renderCategoryButtons() {
    dom.filters.innerHTML = '';

    const level = AppState.currentPath.length;
    let categories = [];

    if (level === 0) {
        // Mostrar L1
        categories = Array.from(AppState.categoriesL1).sort();
    } else if (level === 1) {
        // Mostrar L2 del L1 actual
        const l1 = AppState.currentPath[0];
        categories = AppState.categoriesL2.has(l1)
            ? Array.from(AppState.categoriesL2.get(l1)).sort()
            : [];
    } else if (level === 2) {
        // Mostrar L3 del L1>L2 actual
        const key = AppState.currentPath.join('/');
        categories = AppState.categoriesL3.has(key)
            ? Array.from(AppState.categoriesL3.get(key)).sort()
            : [];
    }

    // Si no hay subcategorías, no mostrar botones
    if (categories.length === 0) {
        dom.filters.innerHTML = '<span style="color: var(--text-muted); font-size: 0.9rem;">No hay subcategorías</span>';
        return;
    }

    categories.forEach(cat => {
        const btn = document.createElement('button');
        btn.className = 'filter-btn';
        btn.textContent = cat;
        btn.onclick = () => navigateTo([...AppState.currentPath, cat]);
        dom.filters.appendChild(btn);
    });
}

/**
 * Aplica filtros según el path actual
 */
function applyFilters() {
    const query = AppState.searchQuery.toLowerCase();
    const path = AppState.currentPath;

    AppState.filteredItems = AppState.items.filter(item => {
        // Match por jerarquía
        let matchesPath = true;
        if (path.length >= 1) matchesPath = matchesPath && item.categoryL1 === path[0];
        if (path.length >= 2) matchesPath = matchesPath && item.categoryL2 === path[1];
        if (path.length >= 3) matchesPath = matchesPath && item.categoryL3 === path[2];

        // Match por búsqueda
        const searchField = item.searchText || '';
        const matchesSearch = query === '' || searchField.includes(query);

        return matchesPath && matchesSearch;
    });

    // Reset DOM y contadores
    dom.gallery.innerHTML = '';
    AppState.renderedCount = 0;

    // Renderizar primer lote
    renderNextBatch();
}

/**
 * Renderiza el siguiente lote de items (Lazy Load)
 */
function renderNextBatch() {
    if (AppState.isLoading) return;
    AppState.isLoading = true;

    // Verificar si hay items
    if (AppState.filteredItems.length === 0) {
        dom.gallery.innerHTML = `
            <div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 4rem;">
                <i class="fa-solid fa-ghost" style="font-size: 3rem; margin-bottom: 1rem;"></i>
                <p>No se encontraron archivos CNC.</p>
            </div>
        `;
        AppState.isLoading = false;
        return;
    }

    // Calcular slice
    const nextBatch = AppState.filteredItems.slice(AppState.renderedCount, AppState.renderedCount + AppState.batchSize);

    if (nextBatch.length === 0) {
        AppState.isLoading = false;
        return; // Fin de la lista
    }

    // Crear fragmento para rendimiento
    const fragment = document.createDocumentFragment();

    nextBatch.forEach(item => {
        const card = document.createElement('article');
        card.className = 'card';
        card.onclick = () => openModal(item);

        // Fallback seguro de imagen
        const imgSrc = item.preview ? item.preview : 'https://placehold.co/600x400/13131f/00f0ff?text=No+Preview';

        card.innerHTML = `
            <div class="card-image">
                <img src="${imgSrc}" alt="${item.name}" loading="lazy" onerror="this.src='https://placehold.co/600x400/13131f/00f0ff?text=Error'">
            </div>
            <div class="card-content">
                <span class="card-category">${item.category}</span>
                <h3>${item.name}</h3>
                <p class="card-desc">${item.description || 'Sin descripción'}</p>
            </div>
        `;
        fragment.appendChild(card);
    });

    dom.gallery.appendChild(fragment);
    AppState.renderedCount += nextBatch.length;
    AppState.isLoading = false;
}

/**
 * Configurar Infinite Scroll (Optimized)
 */
function setupInfiniteScroll() {
    let ticking = false;

    window.addEventListener('scroll', () => {
        if (!ticking) {
            window.requestAnimationFrame(() => {
                const { scrollTop, scrollHeight, clientHeight } = document.documentElement;

                // Si estamos cerca del final (a 300px)
                if (scrollTop + clientHeight >= scrollHeight - 300) {
                    renderNextBatch();
                }

                ticking = false;
            });

            ticking = true;
        }
    });
}

/**
 * Gestión de Eventos
 */
function setupEventListeners() {
    // Búsqueda (Debounce ligero opcional, aqui directo para feedback rapido)
    dom.search.addEventListener('input', (e) => {
        AppState.searchQuery = e.target.value;
        applyFilters();
    });

    // Modal
    dom.modal.close.onclick = closeModal;
    dom.modal.backdrop.onclick = (e) => {
        if (e.target === dom.modal.backdrop) closeModal();
    };

    // Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeModal();

        // Debug: Toggle Eco Mode with F9
        if (e.key === 'F9') {
            document.body.classList.toggle('low-spec');
            const isEco = document.body.classList.contains('low-spec');
            // Guardar preferencia manual
            localStorage.setItem('foxu_eco_auto', isEco);
            console.log(`Eco Mode toggled: ${isEco}`);
        }
    });
}

/**
 * Lógica del Modal
 */
function openModal(item) {
    dom.modal.img.src = item.preview;
    dom.modal.img.onerror = () => dom.modal.img.src = 'https://placehold.co/800x600/13131f/00f0ff?text=Preview+Not+Found';

    dom.modal.title.textContent = item.name;
    dom.modal.category.textContent = item.category;
    dom.modal.desc.textContent = item.description;
    dom.modal.download.href = item.downloadUrl;

    dom.modal.backdrop.classList.add('active');
    document.body.style.overflow = 'hidden'; // Bloquear scroll
}

function closeModal() {
    dom.modal.backdrop.classList.remove('active');
    document.body.style.overflow = ''; // Restaurar scroll
}

// Arrancar App
document.addEventListener('DOMContentLoaded', init);
