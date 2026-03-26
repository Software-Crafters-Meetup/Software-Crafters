// OST Reveal.js Theme - Initialization Script
// Propagates global meta data and initializes Reveal.js

// Propagate global meta to chapter slides
const reveal = document.querySelector('.reveal');
const org = reveal.dataset.organization || '';
const speaker = reveal.dataset.speaker || '';
const email = reveal.dataset.email || '';
const date = reveal.dataset.date || '';
const module = reveal.dataset.module || '';

// Build footer text for content slides
const contentFooter = [module, email].filter(Boolean).join('  \u00b7  ');

document.querySelectorAll('section[data-slide-type="chapter"]').forEach((s) => {
  if (!s.dataset.organization) s.dataset.organization = org;
  if (!s.dataset.footer) s.dataset.footer = speaker + '  \u00b7  ' + date;
});

// Propagate footer and chapter name to all content slides (no data-slide-type)
let currentChapter = '';
document.querySelectorAll('.slides > section').forEach((s) => {
  if (s.dataset.slideType === 'chapter') {
    const h1 = s.querySelector('h1');
    if (h1) currentChapter = h1.textContent;
  } else if (!s.dataset.slideType) {
    if (!s.dataset.footer) s.dataset.footer = contentFooter;
    if (!s.dataset.date) s.dataset.date = date;
    // Auto-insert chapter name div if the slide doesn't already have one
    const firstChild = s.firstElementChild;
    const hasChapterDiv =
      firstChild &&
      firstChild.tagName === 'DIV' &&
      !firstChild.classList.length &&
      !firstChild.querySelector('*');
    if (currentChapter && !hasChapterDiv) {
      const div = document.createElement('div');
      div.textContent = currentChapter;
      s.insertBefore(div, s.firstChild);
    } else if (currentChapter && hasChapterDiv && !hasChapterDiv.textContent) {
      firstChild.textContent = currentChapter;
    }
  }
});

// Propagate global meta to title slide
const titleSlide = document.querySelector('section[data-slide-type="title"]');
if (titleSlide) {
  const metaItems = [{ text: speaker }, { text: date }, { text: org }];
  metaItems.forEach(({ text }) => {
    if (text) {
      const div = document.createElement('div');
      div.textContent = text;
      titleSlide.appendChild(div);
    }
  });
}

// Detect print mode early
const isPrintPdf = /print-pdf/gi.test(window.location.search);

const deck = new Reveal({
  width: 1920,
  height: 1080,
  margin: 0.04,
  hash: true,
  slideNumber: false,
  plugins: [RevealNotes, RevealHighlight],
});
deck.initialize();

// Create fixed footer bar (skip in print-pdf mode)
const footerBar = document.createElement('div');
footerBar.classList.add('ost-footer-bar');
if (!isPrintPdf) {
  footerBar.innerHTML = `
    <span class="ost-footer-number"></span>
    <span class="ost-footer-divider"></span>
    <span class="ost-footer-text"></span>
    <span class="ost-footer-date"></span>
    <img class="ost-footer-logo" src="brand/ost-logo-simple.png" alt="OST" />
  `;
  document.body.appendChild(footerBar);
}

// Create fixed chapter footer bar (skip in print-pdf mode)
const chapterFooterBar = document.createElement('div');
chapterFooterBar.classList.add('ost-chapter-footer-bar');
if (!isPrintPdf) {
  chapterFooterBar.innerHTML = `
    <span class="chapter-footer-org"></span>
    <span class="chapter-footer-extra">${module || ''}</span>
    <span class="chapter-footer-speaker">${speaker}</span>
    <span class="chapter-footer-date">${date}</span>
    <img class="chapter-footer-logo" src="brand/ost-logo-german.png" alt="OST" />
  `;
  document.body.appendChild(chapterFooterBar);
}

function updateFooter(slide) {
  const slideType = slide.dataset.slideType;
  if (slideType === 'title' || slideType === 'image') {
    footerBar.classList.remove('visible');
    chapterFooterBar.classList.remove('visible');
    return;
  }

  if (slideType === 'chapter') {
    footerBar.classList.remove('visible');
    chapterFooterBar.classList.add('visible');
    chapterFooterBar.querySelector('.chapter-footer-org').textContent =
      slide.dataset.organization || org;
    return;
  }

  chapterFooterBar.classList.remove('visible');
  footerBar.classList.add('visible');
  const indices = deck.getIndices();
  footerBar.querySelector('.ost-footer-number').textContent = indices.h + 1;

  footerBar.querySelector('.ost-footer-text').textContent =
    slide.dataset.footer || '';
  footerBar.querySelector('.ost-footer-date').textContent =
    slide.dataset.date || '';
}

deck.on('ready', (event) => {
  updateFooter(event.currentSlide);

  // ============================================
  // Print footers: inject into .pdf-page wrappers AFTER Reveal.js init
  // Reveal.js wraps each <section> in a <div class="pdf-page"> with
  // position:relative and explicit dimensions. We inject footers as
  // siblings of the section, inside the pdf-page, so they render at
  // the bottom of each page.
  // ============================================
  if (isPrintPdf) {
    let slideIndex = 0;
    document.querySelectorAll('.pdf-page').forEach((page) => {
      const section = page.querySelector('section');
      if (!section) return;
      slideIndex++;
      const slideType = section.dataset.slideType;
      if (slideType === 'title' || slideType === 'image') return;

      const pf = document.createElement('div');

      // Position at bottom of the pdf-page (which has position:relative)
      Object.assign(pf.style, {
        position: 'absolute',
        bottom: '0',
        left: '0',
        right: '0',
        width: '100%',
        boxSizing: 'border-box',
        fontFamily: 'Lato, sans-serif',
        backgroundColor: 'white',
        zIndex: '200',
        alignItems: 'center',
      });

      if (slideType === 'chapter') {
        Object.assign(pf.style, {
          display: 'grid',
          gridTemplateColumns: '1fr 1fr auto',
          gridTemplateRows: '1fr 1fr',
          height: '140px',
          padding: '15px 40px',
        });
        pf.innerHTML = `
          <span style="grid-column:1;grid-row:1;font-size:18px;color:#333;padding-left:10px">${section.dataset.organization || org}</span>
          <span style="grid-column:1;grid-row:2;font-size:18px;color:#333;padding-left:10px">${module || ''}</span>
          <span style="grid-column:2;grid-row:1;font-size:18px;color:#333">${speaker}</span>
          <span style="grid-column:2;grid-row:2;font-size:18px;color:#333">${date}</span>
          <img style="grid-column:3;grid-row:1/3;height:90px;padding:0 15px;align-self:center" src="brand/ost-logo-german.png" alt="OST" />
        `;
      } else {
        Object.assign(pf.style, {
          display: 'flex',
          height: '64px',
          padding: '0 25px',
        });
        pf.innerHTML = `
          <span style="font-size:18px;font-weight:bold;color:#333;padding:0 15px 0 0;flex-shrink:0">${slideIndex}</span>
          <span style="width:3px;height:60%;background-color:rgb(140,25,95);flex-shrink:0"></span>
          <span style="font-size:16px;color:#999;padding:0 20px;flex:1">${section.dataset.footer || ''}</span>
          <span style="font-size:16px;color:#999;padding:0 20px;flex-shrink:0">${section.dataset.date || ''}</span>
          <img style="height:50px;padding:0 15px;flex-shrink:0" src="brand/ost-logo-simple.png" alt="OST" />
        `;
      }

      page.appendChild(pf);
    });
  }

  // ============================================
  // Code block toolbar: Copy + Fullscreen
  // ============================================
  document.querySelectorAll('.reveal pre').forEach((pre) => {
    const codeEl = pre.querySelector('code');
    if (!codeEl) return;

    // Create toolbar
    const toolbar = document.createElement('div');
    toolbar.classList.add('ost-code-toolbar');

    // Copy button
    const copyBtn = document.createElement('button');
    copyBtn.innerHTML = '\u2398 Copy';
    copyBtn.title = 'Copy code';
    copyBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const text = codeEl.textContent;
      navigator.clipboard.writeText(text).then(() => {
        copyBtn.classList.add('copied');
        copyBtn.innerHTML = '\u2713 Copied!';
        setTimeout(() => {
          copyBtn.classList.remove('copied');
          copyBtn.innerHTML = '\u2398 Copy';
        }, 2000);
      });
    });

    // Fullscreen button
    const fsBtn = document.createElement('button');
    fsBtn.innerHTML = '\u26F6 Fullscreen';
    fsBtn.title = 'View fullscreen';
    fsBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const overlay = document.createElement('div');
      overlay.classList.add('ost-code-fullscreen');

      const closeBtn = document.createElement('button');
      closeBtn.classList.add('ost-fullscreen-close');
      closeBtn.textContent = '\u2715 Close (Esc)';
      closeBtn.addEventListener('click', () => overlay.remove());

      const preCopy = pre.cloneNode(true);
      const cloneToolbar = preCopy.querySelector('.ost-code-toolbar');
      if (cloneToolbar) cloneToolbar.remove();

      overlay.appendChild(closeBtn);
      overlay.appendChild(preCopy);
      document.body.appendChild(overlay);

      const onKey = (ev) => {
        if (ev.key === 'Escape') {
          overlay.remove();
          document.removeEventListener('keydown', onKey);
        }
      };
      document.addEventListener('keydown', onKey);
    });

    toolbar.appendChild(copyBtn);
    toolbar.appendChild(fsBtn);
    codeEl.style.position = 'relative';
    codeEl.appendChild(toolbar);
  });

  // ============================================
  // Image: auto-wrap in <figure>, add caption, click-to-fullscreen
  // ============================================
  // Auto-wrap standalone <img> in <figure> and generate <figcaption> from data-caption
  document
    .querySelectorAll(
      '.reveal section:not([data-slide-type]) img:not(.ost-footer-logo):not(.chapter-footer-logo)',
    )
    .forEach((img) => {
      // Skip background images and logos
      if (
        img.closest('.ost-footer-bar') ||
        img.closest('.ost-chapter-footer-bar')
      )
        return;

      // Wrap in <figure> if not already inside one
      if (!img.closest('figure')) {
        const figure = document.createElement('figure');
        img.parentNode.insertBefore(figure, img);
        figure.appendChild(img);
      }

      // Generate <figcaption> from data-caption
      const captionText = img.dataset.caption;
      const figure = img.closest('figure');
      if (captionText && figure && !figure.querySelector('figcaption')) {
        const figcaption = document.createElement('figcaption');
        figcaption.textContent = captionText;
        figure.appendChild(figcaption);
      }

      // Click-to-fullscreen
      img.style.cursor = 'zoom-in';
      img.addEventListener('click', (e) => {
        e.stopPropagation();
        const overlay = document.createElement('div');
        overlay.classList.add('ost-image-fullscreen');

        const fullImg = document.createElement('img');
        fullImg.src = img.src;
        fullImg.alt = img.alt;
        overlay.appendChild(fullImg);

        // Show caption in fullscreen
        const cap = figure ? figure.querySelector('figcaption') : null;
        if (cap) {
          const capEl = document.createElement('figcaption');
          capEl.textContent = cap.textContent;
          overlay.appendChild(capEl);
        }

        overlay.addEventListener('click', () => overlay.remove());
        document.body.appendChild(overlay);

        const onKey = (ev) => {
          if (ev.key === 'Escape') {
            overlay.remove();
            document.removeEventListener('keydown', onKey);
          }
        };
        document.addEventListener('keydown', onKey);
      });
    });
});

// Briefly show controls on slide change
let controlsTimeout;
deck.on('slidechanged', (event) => {
  updateFooter(event.currentSlide);
  const controls = document.querySelector('.reveal .controls');
  if (controls) {
    controls.classList.add('visible');
    clearTimeout(controlsTimeout);
    controlsTimeout = setTimeout(
      () => controls.classList.remove('visible'),
      1500,
    );
  }
});
