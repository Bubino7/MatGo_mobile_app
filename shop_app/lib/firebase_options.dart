// Rovnaký Firebase projekt ako admin_shop_app (matgo-4c9f9).
// Pre vlastnú web app v Firebase Console: flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHtJZBP2dNTzj44l8-X_Q3oPQ4wMUegR4',
    appId: '1:905494334430:android:17f9c70b65cb1585b36b4f',
    messagingSenderId: '905494334430',
    projectId: 'matgo-4c9f9',
    storageBucket: 'matgo-4c9f9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNKoLTcUV2hlS2r7hYEVqArLECH8rZkWo',
    appId: '1:905494334430:ios:39b005881d51e17eb36b4f',
    messagingSenderId: '905494334430',
    projectId: 'matgo-4c9f9',
    storageBucket: 'matgo-4c9f9.firebasestorage.app',
    iosBundleId: 'com.matgoapp.matgo',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD64dM2xFfR_0llssKyx4gOojB7oeMPImY',
    appId: '1:905494334430:web:9fe044c8dc1b0d62b36b4f',
    messagingSenderId: '905494334430',
    projectId: 'matgo-4c9f9',
    authDomain: 'matgo-4c9f9.firebaseapp.com',
    storageBucket: 'matgo-4c9f9.firebasestorage.app',
    measurementId: 'G-HL6S3GZ9HL',
  );
}
