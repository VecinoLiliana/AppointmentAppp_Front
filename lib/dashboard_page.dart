import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Paleta
  static const kRose = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFF9D0CE);
  static const kCream = Color(0xFFF3EBD8);
  static const kOlive = Color(0xFFB6BB79);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kRoseLight.withOpacity(0.15),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Dashboard Médico",
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
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, Routes.login);
              }
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
          onTap: (i) {
            if (i == 0) return;
            if (i == 1) Navigator.pushReplacementNamed(context, Routes.messages);
            if (i == 2) Navigator.pushReplacementNamed(context, Routes.settings);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mensajes'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Config'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final nombre = snapshot.hasData && snapshot.data!.exists
                      ? (snapshot.data!.data() as Map<String, dynamic>)['nombre'] ?? 'Doctor'
                      : 'Doctor';

                  return Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: kRose,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "¡Bienvenido, Dr. $nombre!",
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Panel de control médico",
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Indicadores principales
              Text(
                "Estadísticas Generales",
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // StreamBuilder para las estadísticas
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('citas')
                    .snapshots(),
                builder: (context, citasSnapshot) {
                  if (citasSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: kRose),
                      ),
                    );
                  }

                  if (!citasSnapshot.hasData) {
                    return const Center(child: Text('No hay datos disponibles'));
                  }

                  // Calcular estadísticas
                  final citas = citasSnapshot.data!.docs;
                  final totalCitas = citas.length;
                  
                  // Citas próximas (status = 'scheduled' y fecha futura)
                  final now = DateTime.now();
                  final citasProximas = citas.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? '';
                    final start = (data['start'] as Timestamp?)?.toDate();
                    return status == 'scheduled' && 
                           start != null && 
                           start.isAfter(now);
                  }).length;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .where('rol', isEqualTo: 'paciente')
                        .snapshots(),
                    builder: (context, pacientesSnapshot) {
                      final totalPacientes = pacientesSnapshot.hasData 
                          ? pacientesSnapshot.data!.docs.length 
                          : 0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: "Total de Citas",
                                  value: totalCitas.toString(),
                                  icon: Icons.calendar_month,
                                  color: kRose,
                                  bgColor: kRoseLight,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: "Citas Próximas",
                                  value: citasProximas.toString(),
                                  icon: Icons.schedule,
                                  color: kOlive,
                                  bgColor: kCream,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            title: "Total de Pacientes",
                            value: totalPacientes.toString(),
                            icon: Icons.people,
                            color: kRose,
                            bgColor: kRoseLight,
                            isWide: true,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Lista de próximas citas
              Text(
                "Próximas Citas",
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('citas')
                    .where('status', isEqualTo: 'scheduled')
                    .orderBy('start', descending: false)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: kRose),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hay citas programadas',
                                style: GoogleFonts.nunito(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final citasFuturas = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final start = (data['start'] as Timestamp?)?.toDate();
                    return start != null && start.isAfter(now);
                  }).toList();

                  if (citasFuturas.isEmpty) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hay citas próximas',
                                style: GoogleFonts.nunito(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: citasFuturas.length,
                    itemBuilder: (context, index) {
                      final doc = citasFuturas[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final patientName = data['patientName'] ?? 'Paciente';
                      final reason = data['reason'] ?? 'Sin motivo';
                      final start = (data['start'] as Timestamp).toDate();
                      
                      return _AppointmentCard(
                        patientName: patientName,
                        reason: reason,
                        dateTime: start,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para las tarjetas de estadísticas
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isWide;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para las tarjetas de citas
class _AppointmentCard extends StatelessWidget {
  final String patientName;
  final String reason;
  final DateTime dateTime;

  const _AppointmentCard({
    required this.patientName,
    required this.reason,
    required this.dateTime,
  });

  static const kRose = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFF9D0CE);

  @override
  Widget build(BuildContext context) {
    final formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    final formattedTime = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kRoseLight,
          child: Icon(Icons.person, color: kRose),
        ),
        title: Text(
          patientName,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              reason,
              style: GoogleFonts.nunito(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
