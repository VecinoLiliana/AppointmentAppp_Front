//import 'package:appointmentapp_lilianavecino/main.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'graphics_page.dart';
import 'login_page.dart';
import 'citas_page.dart';
import 'dashboard_page.dart';
import 'doctor_appointments_page.dart';

class Routes {
  static const String login ='/login';
  static const String home ='/home';
  static const String dashboard = '/dashboard';
  static const String doctorAppointments = '/doctor-appointments';
  static const messages = '/messages';
  static const String profile ='/profile';
  static const settings = '/settings';
  static const String citas = '/citas';
  static const createAppointment = '/appointments/create';
  static const appointmentsList = '/appointments';
  static const appointmentForm = '/appointments/form';
  static const graphics = '/graphics';


  static Route<dynamic> generateRoute(RouteSettings settings){
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case doctorAppointments:
        return MaterialPageRoute(builder: (_) => const DoctorAppointmentsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case citas:
        return MaterialPageRoute(builder: (_) => const CitasPage());
      case graphics:
        return MaterialPageRoute(builder: (_) => const GraphicsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

