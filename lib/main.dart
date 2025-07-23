import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gajatrack/views/admin_view_drivers_view.dart';
import 'firebase_options.dart';

// Views
import 'views/login_view.dart';
import 'views/admin_home_view.dart';
import 'views/admin_create_driver_view.dart';
import 'views/admin_view_drivers_view.dart'; // 👈 NEW
import 'views/driver_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GajaTrackApp());
}

class GajaTrackApp extends StatelessWidget {
  const GajaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GajaTrack',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/admin': (context) => AdminHomeView(),
        '/admin/create_driver': (context) => AdminCreateDriverView(),
        '/admin/all_drivers': (context) => AdminViewDriversView(), // 👈 Use this route name
        '/driver': (context) => DriverHomeView(),
      },
    );
  }
}
