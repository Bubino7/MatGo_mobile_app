import 'package:get/get.dart';

class NavigationController extends GetxController {
  // Index aktuálnej stránky (0 = Domov, 1 = Obchody, 2 = Košík, 3 = Profil)
  var currentIndex = 0.obs;

  // Zmena stránky
  void changePage(int index) {
    currentIndex.value = index;
  }
}
