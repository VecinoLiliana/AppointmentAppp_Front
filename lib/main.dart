import 'package:appointmentapp_lilianavecino/create_page.dart';
import 'package:appointmentapp_lilianavecino/home_page.dart';
import 'package:appointmentapp_lilianavecino/messages_page.dart';
import 'package:appointmentapp_lilianavecino/profile_page.dart';
import 'package:appointmentapp_lilianavecino/routes.dart';
import 'package:appointmentapp_lilianavecino/settings_page.dart';
import 'package:appointmentapp_lilianavecino/form_page.dart';
import 'package:appointmentapp_lilianavecino/list_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoctorAppointmentApp',
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      onGenerateRoute: Routes.generateRoute,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      ),
      routes: {
        Routes.home: (_) => const HomePage(),
        Routes.messages: (_) => const MessagesPage(),
        Routes.profile: (_) => const ProfilePage(),
        Routes.settings: (_) => const SettingsPage(),
        Routes.createAppointment: (_) => const CreatePage(),
        Routes.appointmentsList: (_) => ListPage(userId: FirebaseAuth.instance.currentUser!.uid),
        Routes.appointmentForm: (_) => const FormPage(),

      },
      home: const LoginPage(),
    );
  }
}
