import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const kRose = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFFFF1F1);

  int _selectedIndex = 2; // Settings seleccionado

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Routes.messages);
        break;
      case 2:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombre =
        user?.displayName ?? user?.email?.split('@').first ?? 'Querido usuario';

    return Scaffold(
      backgroundColor: kRoseLight, 
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
        ),
        backgroundColor: kRose,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // perfil
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kRoseLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kRose.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kRose.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundImage:
                          AssetImage('lib/assets/doctor_avatar.png'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kRose,
                          ),
                        ),
                        Text(
                          'Perfil de usuario',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: kRose),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.profile);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // seciones
            _SectionTile(
              icon: Icons.person_outline,
              iconBg: Colors.lightBlue.shade100,
              iconColor: Colors.lightBlue.shade700,
              title: 'Profile',
              onTap: () {
                Navigator.pushNamed(context, Routes.profile);
              },
            ),
            _SectionTile(
              icon: Icons.notifications_outlined,
              iconBg: Colors.deepPurple.shade100,
              iconColor: Colors.deepPurple.shade700,
              title: 'Notifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoPage(
                      title: 'Notifications',
                      text: 'Configuración de notificaciones',
                    ),
                  ),
                );
              },
            ),
            _SectionTile(
              icon: Icons.privacy_tip_outlined,
              iconBg: Colors.purple.shade100,
              iconColor: Colors.purple.shade700,
              title: 'Privacy',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoPage(
                      title: 'Privacy',
                      text: 'Información sobre privacidad',
                    ),
                  ),
                );
              },
            ),
            _SectionTile(
              icon: Icons.settings_suggest_outlined,
              iconBg: Colors.green.shade100,
              iconColor: Colors.green.shade700,
              title: 'General',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoPage(
                      title: 'General',
                      text: 'Ajustes generales',
                    ),
                  ),
                );
              },
            ),
            _SectionTile(
              icon: Icons.info_outline,
              iconBg: Colors.orange.shade100,
              iconColor: Colors.orange.shade700,
              title: 'About Us',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoPage(
                      title: 'About Us',
                      text: 'Acerca de nosotros',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            const SizedBox(height: 12),

            //log out
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Icon(Icons.logout, color: Colors.red.shade700),
              ),
              title: Text(
                'Log Out',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, Routes.login);
              },
            ),
          ],
        ),
      ),

      // menu inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kRose,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: "Mensajes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Config",
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SectionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: iconBg.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconBg,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Página informativa
class InfoPage extends StatelessWidget {
  final String title;
  final String text;
  const InfoPage({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: GoogleFonts.nunito(fontSize: 16),
        ),
      ),
    );
  }
}
