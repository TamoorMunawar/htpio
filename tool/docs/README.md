# Documentation site

`docs/index.html` is generated. Don't edit it by hand.

1. Edit `tool/docs/content.py`.
2. Rebuild the page:

   ```bash
   python3 tool/docs/build.py
   ```

3. Check that every example still compiles:

   ```bash
   python3 tool/docs/build.py --check test/_docs_check.dart
   flutter analyze test/_docs_check*.dart
   rm test/_docs_check*.dart
   ```

The site is published with GitHub Pages (Settings → Pages → Deploy from a branch → `main` / `/docs`).
