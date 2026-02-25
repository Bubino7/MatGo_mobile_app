# MatGo Driver App

Aplikácia pre vodičov (soferov): prihlásenie, domov s uvítaním a tlačidlami „Chcem viezť“ / „Vyvezené objednávky“, spodná navigácia Domov / Notifikácie / Profil.

## Spustenie

```bash
cd driver_app
flutter pub get
flutter run -d ios
# alebo: flutter run -d android
```

## Štruktúra

- **Login** – email/heslo (Firebase Auth, rovnaký projekt ako client_app).
- **Domov** – uvítanie (Dobré ráno / Dobrý deň / Dobrý večer) + meno používateľa, tlačidlá:
  - **Chcem viezť** → placeholder stránka „Dostupné objednávky“
  - **Vyvezené objednávky** → placeholder „História doručení“
- **Spodná navigácia**: Domov | Notifikácie | Profil (Profil obsahuje email a Odhlásiť sa).

## Firebase

Používa sa rovnaký Firebase projekt ako client_app (`firebase_options.dart`). Pre vlastnú iOS/Android app v Firebase Console spusti v `driver_app`: `flutterfire configure`.
