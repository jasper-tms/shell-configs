---
name: reading-pdfs
description: Read text from PDFs.
---

# Skill: Reading PDFs

Before parsing a PDF, check whether the project already has an extracted
markdown/text version of it (common convention: a sibling directory named
`<pdf-basename>_sections/`) — prefer that when it exists.

Things to try, in order:

1. **pypdf from the base virtual environment**:

   ```bash
   ~/.virtualenvs/base/bin/python -c "
   from pypdf import PdfReader
   reader = PdfReader('path/to/document.pdf')
   for page_number, page in enumerate(reader.pages, start=1):
       print(f'=== page {page_number} ===')
       print(page.extract_text())
   "
   ```

   For a long PDF, slice `reader.pages[start:stop]`, or pipe the output
   through `grep -n` to locate the relevant pages first.

2. **The built-in Read tool** — needs poppler's `pdftoppm` installed. Renders
   pages visually, so it is the better choice for tables and layout-heavy
   pages even when pypdf is available.

3. **`pdftotext document.pdf -`** — if poppler is installed.

4. If none of the above are available, ask the user how they would like to
   provide a PDF reader (for example installing pypdf into a virtual
   environment, or `brew install poppler`) rather than installing things
   unprompted.

Caveats: text extraction flattens layout — multi-column pages and tables can
come out scrambled, so cross-check ambiguous table values against another
source before citing them. Scanned (image-only) PDFs yield no text; if
extraction returns empty pages, say so rather than guessing.
