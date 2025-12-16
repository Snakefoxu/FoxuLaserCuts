/**
 * CNC Catalog App Logic
 * Version: Simple Category Filter (Single Level)
 */

// Estado de la aplicación
const AppState = {
    items: [],
    filteredItems: [],
    renderedCount: 0,
    batchSize: 50,
    categories: new Set(),
    activeCategory: null, // null = todos
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

        if (localStorage.getItem('foxu_eco_auto') === 'true') {
            document.body.classList.add('low-spec');
        }

        if (typeof CATALOG_DB === 'undefined') {
            throw new Error('Base de datos no encontrada');
        }

        AppState.items = CATALOG_DB;
        buildCategories();
        renderCategoryButtons();
        applyFilters();

        setupEventListeners();
        setupInfiniteScroll();
        detectPerformance();

        console.log('Catálogo CNC Iniciado 🚀');
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
 * Extraer categorías únicas
 */
function buildCategories() {
    AppState.items.forEach(item => {
        const cat = item.category || 'Otros';
        AppState.categories.add(cat);
    });
}

/**
 * Renderizar botones de categoría
 */
function renderCategoryButtons() {
    dom.filters.innerHTML = '';
    dom.breadcrumb.innerHTML = '<span class="breadcrumb-item active"><i class="fa-solid fa-home"></i> Todos</span>';

    const categories = Array.from(AppState.categories).sort();

    categories.forEach(cat => {
        const btn = document.createElement('button');
        btn.className = 'filter-btn' + (AppState.activeCategory === cat ? ' active' : '');
        btn.textContent = cat;
        btn.onclick = () => {
            if (AppState.activeCategory === cat) {
                // Toggle off
                AppState.activeCategory = null;
            } else {
                AppState.activeCategory = cat;
            }
            renderCategoryButtons();
            applyFilters();
        };
        dom.filters.appendChild(btn);
    });
}

/**
 * Aplica filtros
 */
function applyFilters() {
    const query = AppState.searchQuery.toLowerCase();
    const cat = AppState.activeCategory;

    AppState.filteredItems = AppState.items.filter(item => {
        const matchesCat = !cat || item.category === cat;
        const searchField = item.searchText || '';
        const matchesSearch = query === '' || searchField.includes(query);
        return matchesCat && matchesSearch;
    });

    dom.gallery.innerHTML = '';
    AppState.renderedCount = 0;
    renderNextBatch();
}

/**
 * Renderiza el siguiente lote de items (Lazy Load)
 */
function renderNextBatch() {
    if (AppState.isLoading) return;
    AppState.isLoading = true;

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

    const nextBatch = AppState.filteredItems.slice(AppState.renderedCount, AppState.renderedCount + AppState.batchSize);

    if (nextBatch.length === 0) {
        AppState.isLoading = false;
        return;
    }

    const fragment = document.createDocumentFragment();

    nextBatch.forEach(item => {
        const card = document.createElement('article');
        card.className = 'card';
        card.onclick = () => openModal(item);

        const imgSrc = item.preview ? item.preview : 'https://placehold.co/600x400/13131f/00f0ff?text=No+Preview';

        card.innerHTML = `
            <div class="card-image">
                <img src="${imgSrc}" alt="${item.name}" loading="lazy" onerror="this.src='https://placehold.co/600x400/13131f/00f0ff?text=Error'">
            </div>
            <div class="card-content">
                <span class="card-category">${item.category || 'Sin categoría'}</span>
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
 * Configurar Infinite Scroll
 */
function setupInfiniteScroll() {
    let ticking = false;

    window.addEventListener('scroll', () => {
        if (!ticking) {
            window.requestAnimationFrame(() => {
                const { scrollTop, scrollHeight, clientHeight } = document.documentElement;
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
    dom.search.addEventListener('input', (e) => {
        AppState.searchQuery = e.target.value;
        applyFilters();
    });

    dom.modal.close.onclick = closeModal;
    dom.modal.backdrop.onclick = (e) => {
        if (e.target === dom.modal.backdrop) closeModal();
    };

    // Escape key & Kiosk Lockdown
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeModal();

        // Block DevTools shortcuts
        if (e.key === 'F12' ||
            (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'i' || e.key === 'J' || e.key === 'j')) ||
            (e.ctrlKey && (e.key === 'U' || e.key === 'u'))) {
            e.preventDefault();
            return false;
        }

        // Eco Mode toggle
        if (e.key === 'F9') {
            document.body.classList.toggle('low-spec');
            const isEco = document.body.classList.contains('low-spec');
            localStorage.setItem('foxu_eco_auto', isEco);
        }
    });

    // Disable Right Click
    document.addEventListener('contextmenu', (e) => {
        e.preventDefault();
    });

    // Back to Top Button
    const backToTopBtn = document.getElementById('backToTop');
    if (backToTopBtn) {
        backToTopBtn.addEventListener('click', () => {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }
}

/**
 * Modal
 */
function openModal(item) {
    dom.modal.img.src = item.preview;
    dom.modal.img.onerror = () => dom.modal.img.src = 'https://placehold.co/800x600/13131f/00f0ff?text=Preview+Not+Found';

    dom.modal.title.textContent = item.name;
    dom.modal.category.textContent = item.category;
    dom.modal.desc.textContent = item.description;
    dom.modal.download.href = item.downloadUrl;

    dom.modal.backdrop.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    dom.modal.backdrop.classList.remove('active');
    document.body.style.overflow = '';
}

// Arrancar App
document.addEventListener('DOMContentLoaded', init);
