# MatGo Shop App

App pre stavebniny (obchody) – rozhranie pre konkrétny obchod (tovar, objednávky).  
Nasadené na ceste **`/shop_app`**.

## Vytvorenie projektu

V tomto priečinku:

```bash
flutter create --project-name shop_app --org com.matgoapp --platforms web,android,ios .
```

## Build pre hosting

Z koreňa MatGo:

```bash
./scripts/build_web_shop.sh
```

Výstup: `deploy/shop_app/` (base path `/shop_app/`).
