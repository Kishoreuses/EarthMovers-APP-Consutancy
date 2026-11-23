import 'package:earthmovers_app/firebase_options.dart';
import 'package:earthmovers_app/screens/customer/home_screen.dart';
import 'package:earthmovers_app/screens/auth/logo_screen.dart';
import 'package:earthmovers_app/screens/admin/admin_home_screen.dart';
import 'package:earthmovers_app/screens/driver/driver_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optional: Firebase Messaging initialization
  // FirebaseMessaging.instance;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await prefs.remove('userRole');
      return const Logo();
    }

    // Try cached role first
    String? role = prefs.getString('userRole');

    if (role == null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          role = userDoc.data()?['role'];
          if (role != null) {
            await prefs.setString('userRole', role);
          }
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }

    // Navigate based on role
    switch (role) {
      case 'admin':
        return AdminHome();
      case 'driver':
        return DriverHome();
      case 'user':
        return Home();
      default:
        return const Logo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      onGenerateRoute: RouteManager.generateRoute,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<Widget>(
            future: _determineStartScreen(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return userSnapshot.data ?? const Logo();
            },
          );
        },
      ),
    );
  }
}
