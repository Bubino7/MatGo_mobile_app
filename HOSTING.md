# MatGo – hostovanie: 4 cesty

Na jednom hostingu sú nasadené štyri aplikácie:

| Cesta           | Aplikácia              | Zdroj v repo      |
|-----------------|------------------------|-------------------|
| `/client_app`   | Zákaznícka app         | `client_app/`     |
| `/shop_app`     | Shop app (stavebniny)  | `shop_app/`       |
| `/driver_app`   | Driver app (vodiči)    | `driver_app/`     |
| `/admin`        | Admin (superuser/správa obchodov) | `admin_shop_app/` |

## Rýchly štart (client app)

### 1. Build pre `/client_app/`

V koreni projektu:

```bash
./scripts/build_web_client.sh   # macOS/Linux
scripts\build_web_client.bat    # Windows
```

Výstup: **`deploy/client_app/`**.

### 2. Nasadenie

- **Firebase Hosting**  
  `firebase use matgo-4c9f9`  
  `firebase deploy --only hosting`  
  Nahrajú sa `deploy/index.html` a všetky `deploy/client_app/`, `deploy/shop_app/`, `deploy/driver_app/`, `deploy/admin/` (čo existujú).

- **Iný hosting**  
  Nahraj obsah každého `deploy/<cesta>/` tak, aby bol dostupný pod URL `/<cesta>/`.

### 3. Kontrola

- Úvod: `https://tvoja-domena.sk/`
- Client: `https://tvoja-domena.sk/client_app/`
- Shop: `https://tvoja-domena.sk/shop_app/`
- Driver: `https://tvoja-domena.sk/driver_app/`
- Admin: `https://tvoja-domena.sk/admin/`

---

## Štruktúra repo a buildy

```
MatGo/
├── client_app/          # Zákaznícka Flutter app
├── shop_app/            # Shop app (stavebniny) – flutter create .
├── driver_app/          # Driver app – flutter create .
├── admin_shop_app/      # Admin app (deployuje sa na /admin)
├── deploy/
│   ├── index.html       # Úvodná stránka s odkazmi na všetky 4 cesty
│   ├── client_app/      # výstup build_web_client.sh
│   ├── shop_app/        # výstup build_web_shop.sh
│   ├── driver_app/      # výstup build_web_driver.sh
│   └── admin/           # výstup build_web_admin.sh
├── scripts/
│   ├── build_web_client.sh
│   ├── build_web_shop.sh
│   ├── build_web_driver.sh
│   └── build_web_admin.sh
└── firebase.json
```

Build skripty (z koreňa repo):

- `./scripts/build_web_client.sh` → `deploy/client_app/` (base-href `/client_app/`)
- `./scripts/build_web_shop.sh` → `deploy/shop_app/` (base-href `/shop_app/`)
- `./scripts/build_web_driver.sh` → `deploy/driver_app/` (base-href `/driver_app/`)
- `./scripts/build_web_admin.sh` → `deploy/admin/` (base-href `/admin/`)

Pre `shop_app`, `driver_app` a `admin_shop_app` najprv v danom priečinku spusti `flutter create ...` (viď README v priečinku).

---

## Dôležité

- Pri builde vždy **`--base-href "/<cesta>/"`** so záverečnou lomkou.
- Na serveri SPA fallback: pre cesty pod prefixom vrátiť `index.html` (v `firebase.json` sú rewrites).
