import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nový import pre Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'controllers/navigation_controller.dart';
import 'pages/shops_page.dart';
import 'pages/cart_page.dart';
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
    // Inicializácia GetX controlleru pre navigáciu
    Get.put(NavigationController());

    return GetMaterialApp(
      title: 'MatGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber), // Stavebná žltá
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme( // Krajšie inputy
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
      // Tu nasadíme "Vrátnika", ktorý rozhodne, kam ísť
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
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Ak je užívateľ prihlásený, ukáž Hlavnú stránku
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Inak ukáž Login
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
  bool isLogin = true; // Prepínač: true = Prihlásenie, false = Registrácia
  bool isLoading = false;

  // Funkcia na vykonanie akcie
  Future<void> _submit() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        // Prihlásenie
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Registrácia
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Zobrazenie chyby (napr. zlé heslo)
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO ---
              const Icon(Icons.construction, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text("MatGo", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text("Materiál na stavbu do hodiny", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // --- FORMULÁR ---
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Heslo', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 24),

              // --- TLAČIDLO ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(isLogin ? "Prihlásiť sa" : "Vytvoriť účet", style: const TextStyle(fontSize: 18)),
                ),
              ),

              // --- PREPÍNAČ REGISTRÁCIE ---
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Nemáš účet? Zaregistruj sa" : "Už máš účet? Prihlás sa"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. MAIN PAGE s Bottom Navigation Bar (GetX)
// ---------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    // Zoznam stránok pre bottom navigation
    final List<Widget> pages = [
      const ShopsPage(), // Index 0 - Obchody
      const CartPage(),  // Index 1 - Košík
      const ProfilePage(), // Index 2 - Profil
    ];

    return Scaffold(
      body: Obx(() => pages[navController.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: navController.currentIndex.value,
          onTap: (index) => navController.changePage(index),
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Obchody',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Košík',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
