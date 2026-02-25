# MatGo Admin – koncept: univerzálny multi-tenant admin

## Myšlienka

**Jedna admin web app** pre všetky stavebniny, ktoré s nami spolupracujú:

- **Superuser (developer / ty)** v admine spravuje všetko: pridáva nové stavebniny, pripadne nastavenia celého systému.
- **Pridanie novej stavebniny** = vytvorenie nového „tenant-a“ so slugom/id (napr. `stavmat`, `bitumat_xyz`). Tým sa v systéme objaví nová „cesta“ / kontext pre danú stavebninu.
- **Stavebnina (obchod)** sa prihlási do admina a vidí len svoj kontext: svoj tovar, objednávky, ceny. Prístup je viazaný na konkrétny shop (tenant).

Jedna codebase, jeden deploy na `/admin_shop_app`, ľahké pridávanie ďalších partnerov bez nového projektu.

---

## Implementácia (admin_shop_app)

V `lib/main.dart` je jednoduchá admin web app pre superusera:

- **Login** – zatiaľ mock (akýkoľvek email/heslo); neskôr nahradíš Firebase Auth.
- **Dashboard** – zoznam stavebnín (predvyplnené StavMat, BituMat, Izoltrad) + tlačidlo **Pridať stavebninu**.
- **Pridať stavebninu** – dialóg (názov, slug/id); pridá záznam do zoznamu (in-memory). Neskôr zápis do Firestore `shops`.
- Klik na riadok stavebniny zatiaľ len snackbar; neskôr navigácia na `/admin/shop/:slug` (tovar, objednávky).

## Roly

| Rola        | Prístup |
|------------|---------|
| **Superuser** | Zoznam všetkých obchodov, pridanie novej stavebniny (tenant), úpravy všetkých obchodov, systémové nastavenia. |
| **Shop admin** | Len jeden obchod (tenant): tovar, objednávky, ceny, otváracie hodiny, atď. |

Rolu riešiš cez Firebase Auth (custom claims) alebo Firestore dokument `users/{uid}` s polom `role` a `shopId` (pre shop admin).

---

## Routy / cesty v admin app

Admin app je na hostingu nasadená na ceste **`/admin`**. Navrhovaná štruktúra URL (príklad):

- `/admin/` alebo `/admin/login` – prihlásenie.
- `/admin/dashboard` – po prihlásení:
  - **Superuser:** dashboard so zoznamom obchodov + „Pridať stavebninu“.
  - **Shop admin:** presmerovanie na svoj shop (nižšie).
- `/admin/shop/:shopId` (alebo `/admin/shop/:slug`) – kontext jednej stavebniny:
  - tovar (CRUD),
  - objednávky,
  - nastavenia obchodu.
- Superuser môže mať v dashboarde odkazy typu `/admin/shop/stavmat_abc`, `/admin/shop/bitumat_xyz`.

Slug/id stavebniny (`nazov_stavebniny_ID`) môže byť:
- v URL ako path parameter, alebo
- uložený po prihlásení (user → `shopId`) a app vždy pracuje v kontexte tohto obchodu.

---

## Dáta (Firestore) – návrh

- **shops** (kolekcia)  
  Jeden dokument = jedna stavebnina (tenant).  
  Polia napr.: `name`, `slug` (alebo `id`), `address`, `createdAt`, `createdBy` (superuser uid), prípadne `settings`.

- **shops/{shopId}/products** (subkolekcia)  
  Tovar danej stavebniny.

- **shops/{shopId}/orders** (subkolekcia)  
  Objednávky pre danú stavebninu (z client app sem môžu zapisovať objednávky s `shopId`).

- **users** (kolekcia)  
  Rozšírenie údajov užívateľa: `role` (superuser | shop_admin), `shopId` (pre shop_admin).  
  Alternatíva: Firebase Auth custom claims (`role`, `shopId`).

Pridanie novej stavebniny (superuser) = vytvorenie dokumentu v `shops` so `slug`/id a prípadne prvého shop admin účtu naviazaného na tento `shopId`.

---

## Súvis s client app

- V **client_app** zákazník prehliada tovar z viacerých stavebnín; objednávka má priradené `shopId` (prípadne viac položiek z viacerých shopov).
- **Admin app** zobrazuje pre každú stavebninu jej tovar a objednávky; superuser vidí všetky obchody a môže pridávať nové (cesta „/nazov_stavebniny_ID“ = tenant s daným id/slug).

Ak budeš chcieť, môžeme v ďalšom kroku rozpísať konkrétne obrazovky (login, superuser dashboard, shop dashboard, CRUD tovaru) alebo štruktúru Flutter projektu (routy, GetX/Provider, služby pre Firestore).
