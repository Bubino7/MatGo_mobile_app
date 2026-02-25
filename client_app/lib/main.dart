import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/shops_service.dart';
import 'services/categories_service.dart';
import 'services/products_service.dart';
import 'services/users_service.dart';
import 'services/orders_service.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/cart_controller.dart';
import 'pages/main_page.dart';
import 'pages/explore_page.dart';
import 'pages/cart_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MatGoApp());
}

class MatGoApp extends StatelessWidget {
  const MatGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AuthService());
    Get.put(ShopsService());
    Get.put(CategoriesService());
    Get.put(ProductsService());
    Get.put(UsersService());
    Get.put(OrdersService());
    Get.put(NavigationController());
    Get.put(CartController());

    return GetMaterialApp(
      title: 'MatGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ---------------------------------------------------------
// 1. VRÁTNIK (AuthGate)
// ---------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Get.find<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ---------------------------------------------------------
// 2. LOGIN & REGISTER SCREEN
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    setState(() => isLoading = true);
    try {
      final auth = Get.find<AuthService>();
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Nastala chyba'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 64, color: Colors.amber.shade700),
                const SizedBox(height: 16),
                Text(
                  isLogin ? 'Prihlásenie' : 'Registrácia',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Heslo',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLogin ? 'Prihlásiť sa' : 'Zaregistrovať sa'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? 'Nemáte účet? Registrujte sa' : 'Už máte účet? Prihláste sa',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. HOME SCREEN (s bottom navigation)
// ---------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    final List<Widget> pages = [
      const MainPage(),
      const ExplorePage(),
      const CartPage(),
      const NotificationsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: navController.currentIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: navController.currentIndex.value,
          onDestinationSelected: navController.changePage,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Domov',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Obchody',
            ),
            NavigationDestination(
              icon: Obx(() {
                final CartController cart = Get.find<CartController>();
                return Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  label: Text('${cart.totalItemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              }),
              selectedIcon: Obx(() {
                final CartController cart = Get.find<CartController>();
                return Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  label: Text('${cart.totalItemCount}'),
                  child: const Icon(Icons.shopping_cart),
                );
              }),
              label: 'Košík',
            ),
            const NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Upozornenia',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
