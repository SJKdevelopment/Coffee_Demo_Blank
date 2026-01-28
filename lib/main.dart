import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_yoco/flutter_yoco.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- YOUR CUSTOM FILES ---
import 'core/services/supabase_service.dart';
import 'core/services/referral_service.dart';
import 'features/referrals/referral_status_card.dart';
import 'features/wallet/wallet_page.dart';
import 'features/orders/order_history.dart';
import 'features/admin/admin_manager_page.dart';
import 'package:flutter/services.dart';
import 'core/services/notifications_service.dart';
import 'core/services/updatePasswordPage.dart';

// ==========================================
// 0. GLOBAL CONFIGURATION (WHITE LABEL)
// ==========================================
// Change these strings to rebrand the app for any client
const String _appName = "The Coffee Shop";
const String _supportEmail = "support@example.com";
const String _supportWhatsapp = "https://wa.me/1234567890";

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ==========================================
// 1. GLOBAL THEME CONTROLLER
// ==========================================
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    notifyListeners();
  }
}

// ==========================================
// 2. MAIN ENTRY POINT
// ==========================================
Future<void> main() async {
  // Required for plugin initialization
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: 'https://wunkujstxrjifcqefiju.supabase.co',
    anonKey: 'sb_publishable_skytJZ8rGKW7oZ2TwjIKIw_SRIOJmHv',
  );

  // 2. Initialize App Services
  await SupabaseService.initialize();
  await ThemeController.instance.loadSettings();

  // 3. Initialize Background Engine
  await NotificationService.initializeService();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) =>
          const CoffeeShopApp(), // Renamed from BlissCoffeeApp
    ),
  );
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, child) {
        return MaterialApp(
          title: _appName,
          scaffoldMessengerKey: messengerKey,
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          themeMode: ThemeController.instance.themeMode,
          // Light Theme - Generic Brown/Black
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6F4E37), // Generic Coffee Brown
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              surfaceTintColor: Color(0xFF121212),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ==========================================
// 2. SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Generic Placeholder Icon instead of branded image
            Icon(
              Icons.coffee,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              _appName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. LOGIN & SIGN UP PAGE
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isBusinessAccount = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();

    // --- PASTE THIS LISTENER ---
    // This waits for the "Password Recovery" event from the email link
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          // Send user to the New Password page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UpdatePasswordPage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _handleRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('saved_email');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  // --- NEW: PASSWORD RESET FUNCTION ---
  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email address first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reset link sent to $email! Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  // ------------------------------------

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate() == false) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    try {
      final supabase = Supabase.instance.client;

      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        await _handleRememberMe(email);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      } else {
        final String myNewCode = ReferralService().generateRandomCode();

        final success = await SupabaseService().registerNewUser(
          email: email,
          password: password,
          myReferralCode: myNewCode,
        );

        if (success) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            await ReferralService().linkReferralOnSignUp(
              userId: user.id,
              friendReferralCode: _referralController.text.trim(),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account Created! Logging you in...")),
          );
          await _handleRememberMe(email);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.message.toLowerCase().contains("already registered") ||
            e.code == 'user_already_exists') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This email already exists! Switching to Login..."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoginMode ? "Welcome Back 👋" : "Create Account 🚀",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoginMode
                        ? "Enter your details to sign in"
                        : "Sign up to start your coffee journey",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _nameController,
                      cursorColor: theme.colorScheme.primary,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Preferred Name (i.e. John)",
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'What should the barista call you?';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: _emailController,
                    cursorColor: theme.colorScheme.primary,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: theme.colorScheme.onSurface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || !_isValidEmail(value))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _phoneController,
                      cursorColor: theme.colorScheme.primary,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(
                          Icons.phone_android_outlined,
                          color: theme.colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 10)
                          ? 'Enter a valid phone'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _referralController,
                      cursorColor: theme.colorScheme.primary,
                      decoration: InputDecoration(
                        labelText: "Referral Email (Optional)",
                        helperText: "Enter a friend's email to get started!",
                        prefixIcon: Icon(
                          Icons.card_giftcard,
                          color: theme.colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.primary.withOpacity(0.05),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    cursorColor: theme.colorScheme.primary,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.colorScheme.onSurface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? 'Password must be 6+ chars'
                        : null,
                  ),

                  // --- NEW: FORGOT PASSWORD BUTTON ---
                  if (_isLoginMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handlePasswordReset,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // -----------------------------------
                  if (!_isLoginMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CheckboxListTile(
                        title: const Text("Register as Business"),
                        subtitle: const Text("Access bulk bean purchasing"),
                        value: _isBusinessAccount,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) =>
                            setState(() => _isBusinessAccount = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                  if (_isLoginMode)
                    Row(
                      children: [
                        Checkbox(
                          activeColor: theme.colorScheme.primary,
                          value: _rememberMe,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val!),
                        ),
                        Text(
                          "Remember Me",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                            )
                          : Text(
                              _isLoginMode ? "SIGN IN" : "SIGN UP",
                              style: const TextStyle(fontSize: 18),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode
                            ? "Don't have an account?"
                            : "Already have an account?",
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isLoginMode = !_isLoginMode),
                        child: Text(
                          _isLoginMode ? "Sign Up" : "Login",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. APP DRAWER (CUSTOMER SUPPORT)
// ==========================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _sendSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Support'},
    );
    if (await canLaunchUrl(emailUri))
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _chatWithSupport() async {
    final whatsapp = Uri.parse(_supportWhatsapp);
    if (await canLaunchUrl(whatsapp))
      await launchUrl(whatsapp, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final bool isBusiness = user?.userMetadata?['is_business'] ?? false;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: const Text(
              "Valued Member",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? "Guest"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(user!.userMetadata!['avatar_url'])
                  : null,
              child: user?.userMetadata?['avatar_url'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.onSurface,
            ),
            title: Text(
              "My Wallet",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: theme.colorScheme.onSurface),
            title: Text(
              "Order History",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryPage(),
                ),
              );
            },
          ),
          // Store Locator
          ListTile(
            leading: Icon(Icons.map, color: theme.colorScheme.onSurface),
            title: Text(
              "Find Stores",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoresPage()),
              );
            },
          ),
          if (isBusiness)
            ListTile(
              leading: Icon(
                Icons.inventory_2,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                "Buy Beans (Bulk)",
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "PRO",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoffeeBeansPage(),
                  ),
                );
              },
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "CUSTOMER SUPPORT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.blue),
            title: Text(
              "Email Support",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: _sendSupportEmail,
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: Colors.green),
            title: Text(
              "WhatsApp Support",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            onTap: _chatWithSupport,
          ),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: Text(
              "Version 1.0.5",
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. DASHBOARD PAGE (Updated with Notifications)
// ==========================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CoffeeMenuPage(),
    const RewardsPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  // Generic Titles
  final List<String> _titles = [
    _appName.toUpperCase(),
    "Rewards",
    "Your Cart",
    "My Profile",
  ];

  @override
  void initState() {
    super.initState();
    // Start the permission check as soon as the user enters the app
    _checkNotificationPermission();
  }

  /// Explicitly requests permission for Android 13+ devices
  Future<void> _checkNotificationPermission() async {
    // Check if notifications are already allowed
    var status = await Permission.notification.status;

    // If permission was previously denied, request it now
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Centralized AppBar that will automatically show the Drawer burger icon
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              ThemeController.instance.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => ThemeController.instance.toggleTheme(
              !ThemeController.instance.isDarkMode,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(), // The drawer is attached to this Scaffold
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.coffee), label: 'Menu'),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. COFFEE MENU PAGE (SDK Compatible Version)
// ==========================================
class CoffeeMenuPage extends StatefulWidget {
  const CoffeeMenuPage({super.key});

  @override
  State<CoffeeMenuPage> createState() => _CoffeeMenuPageState();
}

class _CoffeeMenuPageState extends State<CoffeeMenuPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    try {
      final items = await _supabaseService.fetchProducts();
      if (mounted) {
        setState(() {
          _menuItems = items.where((i) => i['is_bulk'] != true).toList();
          _isLoading = false;
        });
        // Preload images immediately without awaiting for faster perceived performance
        _preloadImages();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Preloads all menu item images in parallel for maximum speed
  void _preloadImages() {
    final futures = <Future>[];
    for (final item in _menuItems) {
      final imageUrl = item['image_url'] ?? "";
      if (imageUrl.isNotEmpty) {
        final optimizedUrl = _optimizeImageUrl(imageUrl);
        futures.add(
          precacheImage(
            CachedNetworkImageProvider(optimizedUrl),
            context,
          ).catchError((_) => null),
        );
      }
    }
    Future.wait(futures).ignore();
  }

  /// Optimize image URL with size and quality parameters
  String _optimizeImageUrl(String url) {
    if (!url.contains('?')) {
      if (url.contains('unsplash.com') || url.contains('images.unsplash.com')) {
        return '$url&q=75&fm=webp&w=500';
      }
      return '$url?w=500&q=75';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ==========================================
          // HERO HEADER
          // ==========================================
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: const ContinuousRectangleBorder(),
            backgroundColor: const Color(0xFF1A1A1A),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                var top = constraints.biggest.height;
                var opacity = ((top - 120) / (300.0 - 120)).clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=75&w=1200&fm=webp',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[800]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                        fadeInDuration: const Duration(milliseconds: 150),
                        useOldImageOnUrlChange: true,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xFF1A1A1A)],
                            stops: [0.4, 0.95],
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: opacity,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 40),
                            Text(
                              "Welcome",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              "Handcrafted Coffee & Fresh Roasts",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // PROMOTIONS SECTION
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -1, 0),
              color: const Color(0xFF1A1A1A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Special Offers",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SpecialsListPage(),
                            ),
                          ),
                          child: Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PromotionsBar(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // MENU SECTION
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 10, 24, 15),
              child: Text(
                "Today's Selection",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _menuItems[index];
                return CoffeeCard(
                  name: item['name'] ?? "Unknown",
                  price: (item['price'] as num).toDouble(),
                  imageUrl: item['image_url'] ?? "",
                  description: item['description'] ?? "",
                );
              }, childCount: _menuItems.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ==========================================
// 7. REWARDS PAGE (Complete Premium Suite)
// ==========================================
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  /// Show redemption code (generate new if needed, show existing if available)
  Future<void> _showRedemptionCode(String userId) async {
    try {
      // Check if user already has an active code
      final existingCode = await SupabaseService().getCurrentRedemptionCode(userId);
      
      if (existingCode != null) {
        // Show existing code
        _showCodeDialog(existingCode, isNew: false);
        return;
      }

      // Generate new code if user has 10+ stamps
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('stamps_count')
          .eq('id', userId)
          .single();

      final int currentStamps = profile['stamps_count'] ?? 0;

      if (currentStamps >= 10) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generating your code..."),
              ],
            ),
          ),
        );

        // Generate new code
        final String redemptionCode = await SupabaseService().generateRedemptionCode(userId);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show new code
        if (mounted) {
          _showCodeDialog(redemptionCode, isNew: true);
        }
      } else {
        // Not enough stamps
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You need ${10 - currentStamps} more stamps!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCodeDialog(String code, {required bool isNew}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? "🎉 Code Generated!" : "🎫 Your Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNew ? "Show this code to the barista:" : "Your redemption code:",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Present this code at the counter to claim your free coffee!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "Please log in to view rewards",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: FutureBuilder<Map<String, dynamic>>(
        future: SupabaseService().fetchUserReferralProfile(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final data = snapshot.data ?? {};
          final String myCode = data['referral_code'] ?? "N/A";

          // Schema Logic
          final int stamps = data['stamps_count'] ?? 0;
          final int successfulReferrals = data['referral_count'] ?? 0;
          final String? loyaltyCode = data['loyalty_redemption_code'];
          final bool isRedeemed = data['is_redeemed'] ?? true;
          final bool hasActiveCode = loyaltyCode != null && isRedeemed == false;
          final bool canGenerateCode = stamps >= 10 && !hasActiveCode;
          final double referralProgress = (successfulReferrals / 10).clamp(
            0.0,
            1.0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PREMIUM MEMBERSHIP CARD
                Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3E2723), Color(0xFF1B1B1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Icon(
                          Icons.star_rounded,
                          size: 80,
                          color: Colors.amber.withOpacity(0.05),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "VIP GOLD MEMBER",
                              style: TextStyle(
                                color: Colors.amber,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "YOUR UNIQUE CODE",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      myCode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: myCode),
                                        ).then((_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text("Code copied!"),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                backgroundColor: Colors.amber,
                                              ),
                                            );
                                          }
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Text(
                              "EST. 2025 • VIP EXCLUSIVE",
                              style: TextStyle(
                                color: Colors.white24,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 2. PREMIUM PERSONAL STAMP CARD
                const Text(
                  "Loyalty Rewards",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.07),
                        Colors.white.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                            ),
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          bool isStamped = index < stamps;
                          return Container(
                            decoration: BoxDecoration(
                              color: isStamped
                                  ? Colors.amber.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                              boxShadow: isStamped
                                  ? [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.1),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                              border: Border.all(
                                color: isStamped
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.1),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.coffee,
                              size: 22,
                              color: isStamped ? Colors.amber : Colors.white10,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: (canGenerateCode || hasActiveCode) ? () => _showRedemptionCode(user.id) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: (canGenerateCode || hasActiveCode)
                                ? Colors.amber.withOpacity(0.2) 
                                : Colors.amber.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: (canGenerateCode || hasActiveCode)
                                ? Border.all(color: Colors.amber.withOpacity(0.5))
                                : null,
                          ),
                          child: Text(
                            hasActiveCode
                                ? "SHOW YOUR CODE"
                                : canGenerateCode
                                    ? "GENERATE YOUR CODE"
                                    : "${10 - stamps} STAMPS REMAINING",
                            style: TextStyle(
                              color: (canGenerateCode || hasActiveCode) ? Colors.amber : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3. PREMIUM REFERRAL MILESTONE
                const Text(
                  "Referral Bonus",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.07),
                        Colors.white.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "FRIEND MILESTONE",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Successful Invites",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$successfulReferrals / 10",
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Upgraded Progress Track
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: referralProgress,
                            child: AnimatedContainer(
                              duration: const Duration(seconds: 1),
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3E2723), Colors.amber],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Subtle Milestone Marker at the end
                          Positioned(
                            right: 0,
                            child: Container(
                              height: 14,
                              width: 14,
                              decoration: BoxDecoration(
                                color: referralProgress >= 1.0
                                    ? Colors.amber
                                    : Colors.white10,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white10,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Referrals are valid after your friend completes their first purchase.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 8. PROFILE PAGE (With Image Upload)
// ==========================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables to manage the upload state
  String? _avatarUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 1. Load the user's existing profile picture
  void _loadProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  // 2. The Upload Logic
  Future<void> _uploadImage() async {
    try {
      // Step A: Pick image from gallery
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Step B: Upload to Supabase Storage
      final imageBytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Step C: Get the Public URL
      final imageUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Step D: Update User Profile Metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      // Step E: Update the UI
      setState(() {
        _avatarUrl = imageUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated! 📸")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("")),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // --- NEW AVATAR SECTION START ---
          Center(
            child: GestureDetector(
              onTap:
                  _uploadImage, // <<-- Clicking the picture starts the upload
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  // The Camera Icon Overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 5, color: Colors.black26),
                        ],
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- NEW AVATAR SECTION END ---
          const SizedBox(height: 10),
          Center(
            child: Text(
              user?.email ?? "User Email",
              style: theme.textTheme.titleMedium,
            ),
          ),
          const Divider(height: 40),

          // The rest of your menu items remain the same
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Order History"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text("My Wallet"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: ThemeController.instance.isDarkMode,
              onChanged: (val) => ThemeController.instance.toggleTheme(val),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text(
              "Reset Password",
              style: TextStyle(color: Colors.orange),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UpdatePasswordPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. PRODUCT DETAILS PAGE
// ==========================================
class ProductDetailsPage extends StatefulWidget {
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  const ProductDetailsPage({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.description = '',
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String selectedSize = 'S';
  int quantity = 1;

  @override
  void dispose() {
    messengerKey.currentState?.clearSnackBars();
    super.dispose();
  }

  double get _currentPrice {
    switch (selectedSize) {
      case 'M':
        return widget.price + 5.0;
      case 'L':
        return widget.price + 10.0;
      default:
        return widget.price;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Hero(
              tag: widget.name,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: theme.cardColor,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () {
                  messengerKey.currentState?.clearSnackBars();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "R${_currentPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6F4E37),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 5),
                      Text(
                        "4.8 (230 reviews)",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Size",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSizeChip("S", textColor),
                      _buildSizeChip("M", textColor),
                      _buildSizeChip("L", textColor),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Quantity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          if (quantity > 1) quantity--;
                        }),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.remove, size: 20),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        quantity.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => setState(() => quantity++),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.description.isNotEmpty
                            ? widget.description
                            : "A rich and creamy blend perfect for any time of day.",
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        for (int i = 0; i < quantity; i++) {
                          CartManager().addToCart(
                            widget.name,
                            "R${_currentPrice.toStringAsFixed(2)}",
                            widget.imageUrl,
                            selectedSize,
                          );
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "ADD TO CART",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeChip(String size, Color textColor) {
    bool isSelected = selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => selectedSize = size),
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          size,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 10. CART PAGE (Payment-Validated Stamps & Notifications)
// ==========================================
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = CartManager();
  bool _isProcessing = false;
  DateTime? _scheduledPickupTime;
  String _selectedPaymentMethod = 'auto'; // 'auto', 'wallet', 'yoco'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messengerKey.currentState?.clearSnackBars();
    });
  }

  @override
  void dispose() {
    messengerKey.currentState?.clearSnackBars();
    super.dispose();
  }

  Future<double> _getWalletBalance() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0.0;
      
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();
      
      return (profileData['wallet_balance'] ?? 0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _handleCheckout() async {
    if (cart.items.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Please log in to checkout")),
      );
      return;
    }

    // Get wallet balance for payment method logic
    final profileData = await Supabase.instance.client
        .from('profiles')
        .select('wallet_balance')
        .eq('id', user.id)
        .single();

    double walletBalance = (profileData['wallet_balance'] ?? 0).toDouble();
    double cartTotal = cart.total;
    final hasSufficientWalletFunds = walletBalance >= cartTotal;

    // Show confirmation dialog if user has selected a specific payment method
    if (hasSufficientWalletFunds && _selectedPaymentMethod != 'auto') {
      final confirmed = await _showPaymentConfirmationDialog(_selectedPaymentMethod, cartTotal, walletBalance);
      if (!confirmed) return;
    }

    // Original checkout logic continues...

    setState(() => _isProcessing = true);

    try {
      final client = Supabase.instance.client;
      final preferredName = user.userMetadata?['preferred_name'] ?? 'Guest';
      final orderSummary = cart.getSummaryString();

      // Wallet & Payment Logic
      final profileData = await client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();

      double walletBalance = (profileData['wallet_balance'] ?? 0).toDouble();
      double cartTotal = cart.total;
      double amountToPayYoco = 0.0;
      double amountFromWallet = 0.0;

      // Payment method selection logic
      if (_selectedPaymentMethod == 'wallet') {
        // User chose wallet only
        if (walletBalance >= cartTotal) {
          amountFromWallet = cartTotal;
          amountToPayYoco = 0.0;
        } else {
          // Insufficient wallet funds - show error
          if (mounted) {
            messengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text("Insufficient wallet funds for this payment method"),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else if (_selectedPaymentMethod == 'yoco') {
        // User chose YOCO only
        amountFromWallet = 0.0;
        amountToPayYoco = cartTotal;
      } else {
        // Auto mode (existing logic)
        if (walletBalance >= cartTotal) {
          amountFromWallet = cartTotal;
          amountToPayYoco = 0.0;
        } else {
          amountFromWallet = walletBalance;
          amountToPayYoco = cartTotal - walletBalance;
        }
      }

      // 1. Create the Pending Order
      final orderResponse = await client
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_amount': cartTotal,
            'status': 'pending',
            'customer_name': preferredName,
            'items_summary': orderSummary,
            'scheduled_pickup_time': _scheduledPickupTime?.toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // 2. Insert Order Items
      for (var item in cart.items) {
        await client.from('order_items').insert({
          'order_id': orderId,
          'product_name': item['name'],
          'price': item['price'],
          'size': item['size'],
        });
      }

      // 3. INTERNAL FUNCTION: Only called on payment success
      Future<void> finalizeTransaction() async {
        // Deduct from wallet if used
        if (amountFromWallet > 0) {
          final newBalance = walletBalance - amountFromWallet;
          await client
              .from('profiles')
              .update({'wallet_balance': newBalance})
              .eq('id', user.id);
        }

        // Update Order Status to Paid
        await client
            .from('orders')
            .update({'status': 'paid'})
            .eq('id', orderId);

        // --- THE CRITICAL UPDATE FOR NOTIFICATIONS ---
        // This triggers the background service to watch this specific order
        NotificationService.startMonitoringOrder(orderId.toString());

        // Increment the loyalty stamp because payment is confirmed
        await SupabaseService().incrementUserStamp(user.id);

        // Record for referral system (only triggers on the very first purchase)
        await ReferralService().recordFirstPurchase();

        setState(() => cart.clearCart());

        if (mounted) {
          messengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text("Purchase Successful! Stamp Added ☕"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      }

      // 4. Trigger YOCO or Finalize immediately if paid via Wallet
      if (amountToPayYoco > 0) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlutterYoco(
              amount: amountToPayYoco,
              transactionId: orderId.toString(),
              secretKey: 'sk_test_960bfde0VBrLlpK098e4ffeb53e1',
              // Replaced specific URLs with generic ones
              successUrl: 'https://example.com/success/',
              cancelUrl: 'https://example.com/cancel/',
              failureUrl: 'https://example.com/failure/',
              onComplete: (transaction) async {
                if (transaction.status.toString().contains('success')) {
                  Navigator.pop(context);
                  await finalizeTransaction();
                }
              },
            ),
          ),
        );
      } else {
        await finalizeTransaction();
      }
    } catch (e) {
      if (mounted) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showPaymentConfirmationDialog(String paymentMethod, double cartTotal, double walletBalance) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Payment Method"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Total: R${cartTotal.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (paymentMethod == 'wallet') ...[
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green),
                  SizedBox(width: 8),
                  Text("Payment from Wallet"),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Wallet Balance: R${walletBalance.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "Remaining Balance: R${(walletBalance - cartTotal).toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Payment via Card (YOCO)"),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Your wallet balance will remain unchanged.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Text(
                "Are you sure you want to proceed with this payment method?",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: paymentMethod == 'wallet' ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text("Confirm"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty 🛍️",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final groupedItems = cart.getGroupedItems();
                      return ListView.builder(
                        itemCount: groupedItems.length,
                        itemBuilder: (context, index) {
                          final groupedItem = groupedItems[index];
                          final quantity = groupedItem['quantity'] ?? 1;
                          final itemTotal = groupedItem['price'] * quantity;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                groupedItem['image_url'],
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    const Icon(Icons.coffee),
                              ),
                            ),
                            title: Text(
                              groupedItem['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              "Size: ${groupedItem['size']} | Qty: $quantity",
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "R${itemTotal.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      "@R${groupedItem['price'].toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      String key =
                                          "${groupedItem['name']}_${groupedItem['size']}";
                                      cart._items.removeWhere(
                                        (item) =>
                                            "${item['name']}_${item['size']}" ==
                                            key,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildCheckoutSummary(theme, textColor),
              ],
            ),
    );
  }

  Widget _buildCheckoutSummary(ThemeData theme, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Schedule Pickup Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Schedule Pickup",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectPickupDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scheduledPickupTime == null
                                ? "Tap to schedule pickup time"
                                : _formatPickupTime(_scheduledPickupTime!),
                            style: TextStyle(
                              color: _scheduledPickupTime == null
                                  ? textColor.withOpacity(0.5)
                                  : textColor,
                              fontSize: 14,
                              fontWeight: _scheduledPickupTime == null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_scheduledPickupTime != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => _scheduledPickupTime = null);
                            },
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Payment Method Selection
          FutureBuilder<double>(
            future: _getWalletBalance(),
            builder: (context, snapshot) {
              final walletBalance = snapshot.data ?? 0.0;
              final hasSufficientWalletFunds = walletBalance >= cart.total;
              
              if (!hasSufficientWalletFunds) {
                return const SizedBox.shrink(); // Don't show selection if insufficient funds
              }
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Payment Method",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPaymentMethod = 'wallet'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethod == 'wallet'
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'wallet'
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'wallet',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Wallet",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          "Balance: R${walletBalance.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPaymentMethod = 'yoco'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethod == 'yoco'
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'yoco'
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'yoco',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Card",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          "Credit/Debit Card",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedPaymentMethod != 'auto') ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedPaymentMethod == 'wallet'
                            ? "Payment will be made from your wallet balance"
                            : "Payment will be made via card",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                "R${cart.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F4E37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isProcessing
                  ? CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                    )
                  : const Text(
                      "CHECKOUT",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Schedule Pickup Date & Time Picker
  Future<void> _selectPickupDateTime() async {
    // Show date picker first
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _scheduledPickupTime ??
          DateTime.now().add(const Duration(minutes: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // Show time picker
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledPickupTime ?? DateTime.now().add(const Duration(minutes: 30)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // Combine date and time
    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate: must be at least 30 minutes in future
    if (selectedDateTime.isBefore(
      DateTime.now().add(const Duration(minutes: 30)),
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup time must be at least 30 minutes from now'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _scheduledPickupTime = selectedDateTime;
    });
  }

  // Format pickup time for display
  String _formatPickupTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(time.year, time.month, time.day);

    String dateStr;
    if (selectedDate == today) {
      dateStr = 'Today';
    } else if (selectedDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${time.month}/${time.day}';
    }

    final timeStr =
        time.hour.toString().padLeft(2, '0') +
        ':' +
        time.minute.toString().padLeft(2, '0');

    return '$dateStr at $timeStr';
  }
}

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [];

  void addToCart(String name, String price, String imageUrl, String size) {
    double parsedPrice =
        double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    _items.add({
      'name': name,
      'price': parsedPrice,
      'image_url': imageUrl,
      'size': size,
    });
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  String getSummaryString() {
    return _items.map((item) => "${item['size']} ${item['name']}").join(", ");
  }

  List<Map<String, dynamic>> getGroupedItems() {
    Map<String, Map<String, dynamic>> grouped = {};
    for (var item in _items) {
      String key = "${item['name']}_${item['size']}";
      if (grouped.containsKey(key)) {
        grouped[key]!['quantity'] = (grouped[key]!['quantity'] ?? 1) + 1;
      } else {
        grouped[key] = {...item, 'quantity': 1};
      }
    }
    return grouped.values.toList();
  }

  List<Map<String, dynamic>> get items => _items;
  double get total => _items.fold(0, (sum, item) => sum + item['price']);
  void clearCart() => _items.clear();
}

// ==========================================
// 12. STORES PAGE
// ==========================================
class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMsg = '';

  final List<Map<String, dynamic>> _stores = [
    {
      // Renamed to Generic
      "name": "Main Street Branch",
      "address": "40 Memorial Rd, City Center",
      "lat": -28.749108880870576,
      "lng": 24.77115057783005,
      "image":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQM6AcA38UOhmlA2ThY_-k0UAaMo7SEXket8Q&s",
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _sortStoresByDistance();
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortStoresByDistance() {
    if (_currentPosition == null) return;

    _stores.sort((a, b) {
      double distA = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a['lat'],
        a['lng'],
      );
      double distB = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b['lat'],
        b['lng'],
      );
      return distA.compareTo(distB);
    });
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text("Could not open maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find a Store")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _errorMsg.isNotEmpty
          ? Center(child: Text(_errorMsg))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _stores.length,
              itemBuilder: (context, index) {
                final store = _stores[index];

                double distanceInMeters = 0;
                if (_currentPosition != null) {
                  distanceInMeters = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    store['lat'],
                    store['lng'],
                  );
                }
                String distanceText =
                    "${(distanceInMeters / 1000).toStringAsFixed(1)} km";

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _openMap(store['lat'], store['lng']),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.network(
                            store['image'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    store['address'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      distanceText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// 14. COFFEE BEANS / WHOLESALE PAGE
// ==========================================
class CoffeeBeansPage extends StatefulWidget {
  const CoffeeBeansPage({super.key});

  @override
  State<CoffeeBeansPage> createState() => _CoffeeBeansPageState();
}

class _CoffeeBeansPageState extends State<CoffeeBeansPage> {
  late Future<List<Map<String, dynamic>>> _futureBeans;

  @override
  void initState() {
    super.initState();
    _futureBeans = Supabase.instance.client
        .from('coffee_beans')
        .select()
        .order('name', ascending: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Beans"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF6F4E37),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  "Wholesale & Bulk",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "Premium roasted beans for business & home.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureBeans,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.coffee_maker,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No beans in stock right now.",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  );
                }

                final beans = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: beans.length,
                  itemBuilder: (context, index) {
                    final bean = beans[index];

                    double priceVal = 0.0;
                    if (bean['price'] is num) {
                      priceVal = (bean['price'] as num).toDouble();
                    } else if (bean['price'] is String) {
                      priceVal =
                          double.tryParse(bean['price'].toString()) ?? 0.0;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: theme.cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: Image.network(
                              bean['image_url'] ?? '',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      bean['name'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        bean['weight'] ?? '1kg',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  bean['description'] ??
                                      'Premium roasted beans.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "R${priceVal.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        CartManager().addToCart(
                                          bean['name'],
                                          "R${priceVal.toStringAsFixed(2)}",
                                          bean['image_url'] ?? '',
                                          bean['weight'] ?? '1kg',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Added ${bean['name']} to cart!",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text("Add to Cart"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 15. COFFEE CARD
// ==========================================
class CoffeeCard extends StatelessWidget {
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  const CoffeeCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              name: name,
              price: price,
              imageUrl: imageUrl,
              description: description,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Hero(
                  tag: name,
                  child: imageUrl.isEmpty
                      ? Container(
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          cacheKey: imageUrl.hashCode.toString(),
                          fadeInDuration: const Duration(milliseconds: 100),
                          useOldImageOnUrlChange: true,
                          filterQuality: FilterQuality.medium,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "R${price.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DYNAMIC PROMOTIONS BAR (Supabase Integrated)
// ==========================================
class PromotionsBar extends StatefulWidget {
  const PromotionsBar({super.key});

  @override
  State<PromotionsBar> createState() => _PromotionsBarState();
}

class _PromotionsBarState extends State<PromotionsBar> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  Future<double> _getWalletBalance() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0.0;
      
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();
      
      return (profileData['wallet_balance'] ?? 0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService()
          .fetchActivePromotions(), // Use the new service method
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final promos = snapshot.data ?? [];
        if (promos.isEmpty) return const SizedBox.shrink();

        // Start timer only once data is available
        _timer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
          if (_pageController.hasClients) {
            _currentPage = (_currentPage + 1) % promos.length;
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
        });

        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(
                      promo['image_url'] ?? 'https://via.placeholder.com/500',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        promo['description'] ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ==========================================
// SPECIALS LIST PAGE
// ==========================================
class SpecialsListPage extends StatelessWidget {
  const SpecialsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          "Current Specials",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabaseService.fetchActivePromotions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final promos = snapshot.data ?? [];
          if (promos.isEmpty) {
            return const Center(
              child: Text(
                "Check back soon for new offers!",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        promo['image_url'] ?? '',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 220,
                          color: Colors.brown[900],
                          child: const Icon(
                            Icons.coffee,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo['title']?.toUpperCase() ?? 'SPECIAL OFFER',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            promo['description'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Available for all customers. Limited time only.",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
