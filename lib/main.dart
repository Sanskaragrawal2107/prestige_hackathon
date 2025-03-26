import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'pages/splash_screen.dart';
import 'pages/auth_screen.dart';
import 'pages/home_screen.dart';
import 'pages/cart_screen.dart';
import 'pages/profile_screen.dart';
import 'pages/checkout_screen.dart';

// void main() {
//   runApp(MaterialApp(
//     home: Logininpage(),
//   ));
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dmbyuzxazfqmvqdqegyn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtYnl1enhhemZxbXZxZHFlZ3luIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NzgyODIsImV4cCI6MjA1ODU1NDI4Mn0.YNtpistaMpTP7CajgyrtZyCa5cI3XLjg1nbguP806DQ',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) => MaterialApp(
          title: 'E-Commerce App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.white,
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          home: authProvider.isInitializing 
              ? SplashScreen() 
              : authProvider.isAuthenticated 
                  ? HomeScreen() 
                  : AuthScreen(),
          routes: {
            '/auth': (ctx) => AuthScreen(),
            '/home': (ctx) => HomeScreen(),
            '/cart': (ctx) => CartScreen(),
            '/profile': (ctx) => ProfileScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/checkout') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => CheckoutScreen(
                  cart: args['cart'],
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
