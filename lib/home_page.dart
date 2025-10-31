import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Paleta Bloombites :) sjjsjsj
  static const kRose      = Color(0xFFF297A0); // principal
  static const kRoseLight = Color(0xFFF9D0CE);
  static const kCream     = Color(0xFFF3EBD8);
  static const kOlive     = Color(0xFFB6BB79); // secundario

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final String nombre =
        user?.displayName ?? user?.email?.split('@').first ?? 'Usuario';

    return Scaffold(
      backgroundColor: kRoseLight.withOpacity(0.15),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Menú Principal",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: kRose,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => Navigator.pushNamed(context, Routes.profile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await auth.signOut();
              Navigator.pushReplacementNamed(context, Routes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: kRoseLight,
          highlightColor: kRoseLight.withOpacity(0.4),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: kRose,
          unselectedItemColor: Colors.grey.shade500,
          onTap: (i) async {
            if (i == 0) return;
            if (i == 1) Navigator.pushReplacementNamed(context, Routes.messages);
            if (i == 2) Navigator.pushReplacementNamed(context, Routes.settings);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mensajes'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Config'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kRoseLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kRoseLight),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('lib/assets/IconPink.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "¡Hola, $nombre!",
                          style: GoogleFonts.fredoka(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "¿En qué podemos ayudarte?",
                          style: GoogleFonts.nunito(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tarjetas principales
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: "Agendar una Cita",
                      subtitle: "Programa tu consulta",
                      icon: Icons.add_circle_outline,
                      bg: kRoseLight,
                      iconColor: kRose,
                      onPressed: () => Navigator.pushReplacementNamed(context, Routes.citas),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      title: "Consejos médicos",
                      subtitle: "Alivio inmediato",
                      icon: Icons.health_and_safety_outlined,
                      bg: kRoseLight,
                      iconColor: kRose,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "Especialistas",
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ChipEspecialista(text: "Cardiólogo"),
                  _ChipEspecialista(text: "Dermatólogo"),
                  _ChipEspecialista(text: "Pediatra"),
                  _ChipEspecialista(text: "Ginecólogo"),
                  _ChipEspecialista(text: "Ortopedista"),
                  _ChipEspecialista(text: "Nutriólogo"),
                  _ChipEspecialista(text: "Oftalmólogo"),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                "Noticias",
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              const _NewsTile(
                title: "Nueva clínica en la zona",
                subtitle: "Ahora más cerca de ti con horarios extendidos.",
              ),
              const _NewsTile(
                title: "Campaña de vacunación",
                subtitle: "Consulta fechas y requisitos en tu ciudad.",
              ),
              const _NewsTile(
                title: "Consejos para temporada de lluvias",
                subtitle: "Cuida tu salud respiratoria con estas medidas.",
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

//widgets

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback? onPressed;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipEspecialista extends StatelessWidget {
  final String text;
  const _ChipEspecialista({required this.text});

  static const kRose      = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFF9D0CE);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        text,
        style: GoogleFonts.nunito(
          color: kRose,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: kRoseLight),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _NewsTile({required this.title, required this.subtitle});

  static const kRose = Color(0xFFF297A0);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: kRose,
          child: Icon(Icons.newspaper_outlined, color: Colors.white),
        ),
        title: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: GoogleFonts.nunito()),
        onTap: null,
      ),
    );
  }
}
