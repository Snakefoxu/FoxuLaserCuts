# Implementation Plan - CNC Catalog App

This plan outlines the steps to build a premium, high-performance catalog application for CNC files. Due to the absence of Node.js in the environment, we will straightforwardly implement this using **Modern Vanilla Web Technologies (ES6+, CSS3)**. This ensures the app runs immediately without complex installation scripts while maintaining a "State of the Art" look and feel.

## User Review Required
> [!IMPORTANT]
> **Tech Stack Choice**: We are proceeding with a **No-Build Modern Stack** (HTML/JS/CSS). This fulfills the requirement of "installing what is needed" by embedding all logic directly in the app, removing the need for external runtimes like Node.js.

## Proposed Architecture
*   **Frontend**: HTML5 + CSS3 (Variables, Flexbox/Grid).
*   **Logic**: Vanilla JavaScript (ES Modules).
*   **Data**: `data/catalog.json` serving as the single source of truth.
*   **Assets**: `previews/` directory for optimized WebP images.

## Structure
```text
/
├── index.html          # Main application entry
├── css/
│   └── style.css       # Premium styles (Glassmorphism, Neon)
├── js/
│   ├── app.js          # Controller
│   └── ui.js           # UI Rendering & Interactions
├── data/
│   └── catalog.json    # Database of CNC files
└── previews/           # Folder for thumbnails
```

## Step-by-Step Implementation

### Phase 1: Foundation & Data Structure
- [ ] **Define JSON Schema**: Create `catalog.json` with sample CNC items (Name, Category, HuggingFace URL, Local POreview Path).
- [ ] **Scaffold Files**: Create the directory structure and empty files.

### Phase 2: Premium UI Design (CSS)
- [ ] **Design System**: Define CSS variables for the "CNC/Cyberpunk" aesthetic (Dark background, Neon Cyan/Orange accents).
- [ ] **Layout**: Implement a responsive grid layout for the gallery.
- [ ] **Components**: Design cards with hover effects, glassmorphism modal for details.

### Phase 3: Core Logic (JS)
- [ ] **Data Fetching**: implemented `fetch` logic to load `catalog.json`.
- [ ] **Rendering**: Build dynamic HTML generation for the catalog grid.
- [ ] **Filtering**: Implement category filters and search bar logic (real-time).

### Phase 4: Integration & Polish
- [ ] **Download Linking**: Ensure the "Download" button correctly opens the HuggingFace URL.
- [ ] **Performance**: Add `loading="lazy"` to images.
- [ ] **Mock Data**: Generate a few placeholder preview images using `generate_image` to demonstrate the final look.

## Verification Plan
1.  Open `index.html` via a local server (or direct file access if CORS allows, otherwise setup simple python server).
2.  Verify the gallery loads sample items.
3.  Test Category filtering.
4.  Confirm "Download" links redirect to HuggingFace.
