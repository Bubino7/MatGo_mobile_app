# shared_models

Spoločné modely a utility pre všetky MatGo aplikácie (admin_shop_app, shop_app, client_app).

## Obsah

- **Collections** – názvy Firestore kolekcií (`shops`, `users`, `products`, `categories`)
- **Shop, User, Product, Category** – modely s `fromMap` / `toMap` (kompatibilné s Firestore, dátumy cez `MatGoUtils.parseDate`)
- **MatGoUtils** – `parseDate(dynamic)` (Timestamp → DateTime), `searchKeywordsFromName(String)` (prefixy pre vyhľadávanie)

## Použitie

V `pubspec.yaml` aplikácie:

```yaml
dependencies:
  shared_models:
    path: ../shared_models
```

V kóde:

```dart
import 'package:shared_models/shared_models.dart';

// názvy kolekcií
firestore.collection(Collections.shops)

// parsovanie z Firestore mapy (s doc.id)
final shop = Shop.fromMap(doc.data(), documentId: doc.id);

// utility
final keywords = MatGoUtils.searchKeywordsFromName('drevoskrutka'); // d, dr, dre, drev, ...
```

Balík je čisto Dart (žiadny Flutter/Firebase), aby ho mohli použiť všetky projekty.
