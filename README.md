# MatGo

**Materiál na stavbu do hodiny** – zákaznícka mobilná a webová aplikácia (Flutter).

- Prihlásenie / registrácia (Firebase Auth)
- Kategórie produktov (Šróby, Vrtáky, Nity, PVC), zoznam od stavebnín
- Košík s množstvom a stránka platby (checkout)
- Bottom navigácia: Domov, Preskúmať, Košík, Notifikácie, Profil

## Požiadavky

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stabílna verzia)
- Firebase projekt (Auth zapnuté; Firestore voliteľne)
- Pre web deploy: Firebase CLI (`npm i -g firebase-tools`) alebo iný hosting

## Štruktúra projektu

Štyri cesty na hostingu: **client_app**, **shop_app**, **driver_app**, **admin**.

```
MatGo/
├── client_app/            # Zákaznícka Flutter app
│   ├── lib/
│   │   ├── main.dart      # Vstup, AuthGate, Login, HomeScreen s bottom nav
│   │   ├── controllers/   # GetX: navigation_controller, cart_controller
│   │   ├── models/        # product, cart_item
│   │   └── pages/         # main_page, products_page, cart_page, checkout_page, ...
│   ├── android/, ios/, web/
│   └── pubspec.yaml
├── shop_app/              # Shop app (stavebniny) – placeholder, flutter create .
├── driver_app/            # Driver app – placeholder, flutter create .
├── admin_shop_app/        # Admin app (deploy na /admin) – viď ADMIN_CONCEPT.md
├── deploy/                # Výstup: client_app/, shop_app/, driver_app/, admin/, index.html
├── scripts/               # build_web_client.sh, build_web_shop.sh, build_web_driver.sh, build_web_admin.sh
└── firebase.json
```

## Technológie

- Flutter (Android, iOS, Web)
- GetX (navigácia, košík)
- Firebase (Auth; Firestore pripravený na dáta)

## Spustenie

Všetko pre zákaznícku app je v `client_app/`:

```bash
cd client_app
flutter pub get
flutter run
```

Web lokálne:

```bash
cd client_app
flutter run -d chrome --web-hostname localhost --web-port 53404
```

## Deployment (web)

Build sa robí z koreňa repo (skript sám vstúpi do `client_app/`). Aplikácia sa na hostingu servuje pod cestou `/client_app/`.

1. **Build:**
   `./scripts/build_web_client.sh && ./scripts/build_web_admin.sh && ./scripts/build_web_shop.sh && ./scripts/build_web_driver.sh`
   Výstup: `deploy/client_app/`

2. **Firebase Hosting:**
   `firebase use matgo-4c9f9`
   `firebase deploy --only hosting`

3. **Iný hosting:**
   Nahraj obsah priečinka `deploy/client_app/` tak, aby bol dostupný pod URL cestou `/client_app/`.

Úvodná stránka s odkazom na app je v `deploy/index.html`.

## Ďalšia dokumentácia

- **[HOSTING.md](HOSTING.md)** – 4 cesty (client_app, shop_app, driver_app, admin), build skripty, Firebase Hosting
- **admin_shop_app/[ADMIN_CONCEPT.md](admin_shop_app/ADMIN_CONCEPT.md)** – koncept univerzálneho multi-tenant admina

## Odkazy

- [Flutter documentation](https://docs.flutter.dev/)
- [GetX](https://pub.dev/packages/get)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
