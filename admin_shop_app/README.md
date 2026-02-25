# MatGo Admin (admin_shop_app)

Univerzálny **multi-tenant admin** pre všetky stavebniny, ktoré s MatGo spolupracujú.

- **Superuser (developer):** pridáva nové stavebniny (tenant s id/slug), spravuje všetko cez jednu admin app.
- **Stavebnina (obchod):** prihlási sa a spravuje len svoj tovar, objednávky a nastavenia na ceste typu `/shop/nazov_stavebniny_ID`.

Jedna codebase, deploy na cestu **`/admin`**. Detaily sú v **[ADMIN_CONCEPT.md](ADMIN_CONCEPT.md)** (roly, routy, návrh Firestore).

## Projekt

Flutter web (admin je primárne web app).

```bash
cd admin_shop_app
flutter pub get
flutter run -d chrome
```

## Build pre hosting

Z koreňa MatGo:

```bash
./scripts/build_web_admin.sh
```

Výstup: `deploy/admin/` (URL: `https://tvoja-domena/admin/`).
