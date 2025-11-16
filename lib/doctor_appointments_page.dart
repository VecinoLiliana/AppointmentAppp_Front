import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';

/// Página para que los médicos vean y gestionen todas las citas
class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Filtros
  String _selectedFilter = 'all'; // all, scheduled, done, canceled
  String _searchQuery = '';

  // Paleta
  static const kRose = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFF9D0CE);
  static const kOlive = Color(0xFFB6BB79);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRoseLight.withOpacity(0.15),
      appBar: AppBar(
        title: Text(
          "Gestión de Citas",
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
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
            onPressed: () => Navigator.pushReplacementNamed(context, Routes.dashboard),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: kRoseLight,
          highlightColor: kRoseLight.withOpacity(0.4),
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          selectedItemColor: kRose,
          unselectedItemColor: Colors.grey.shade500,
          onTap: (i) {
            if (i == 1) return;
            if (i == 0) Navigator.pushReplacementNamed(context, Routes.dashboard);
            if (i == 2) Navigator.pushReplacementNamed(context, Routes.settings);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Citas'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Config'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda y filtros
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Búsqueda
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por paciente...',
                      hintStyle: GoogleFonts.nunito(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: kRose),
                      filled: true,
                      fillColor: kRoseLight.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.nunito(),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Filtros por estado
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todas', 'all', Icons.list),
                        const SizedBox(width: 8),
                        _buildFilterChip('Programadas', 'scheduled', Icons.schedule),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completadas', 'done', Icons.check_circle),
                        const SizedBox(width: 8),
                        _buildFilterChip('Canceladas', 'canceled', Icons.cancel),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de citas
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAppointmentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kRose),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Filtrar por búsqueda
                  var docs = snapshot.data!.docs;
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final patientName = (data['patientName'] ?? '').toString().toLowerCase();
                      return patientName.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  //Se ordena por fecha (más recientes primero)
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aStart = (aData['start'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final bStart = (bData['start'] as Timestamp?)?.toDate() ?? DateTime.now();
                    return bStart.compareTo(aStart);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildAppointmentCard(doc.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stream de citas según el filtro seleccionado
  Stream<QuerySnapshot> _getAppointmentsStream() {
    if (_selectedFilter == 'all') {
      return _firestore
          .collection('citas')
          .orderBy('start', descending: true)
          .snapshots();
    } else {
      return _firestore
          .collection('citas')
          .where('status', isEqualTo: _selectedFilter)
          .orderBy('start', descending: true)
          .snapshots();
    }
  }

  // Chip de filtro
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : kRose,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: kRose,
      backgroundColor: Colors.white,
      labelStyle: GoogleFonts.nunito(
        color: isSelected ? Colors.white : kRose,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? kRose : kRoseLight),
      ),
    );
  }

  // Tarjeta de cita
  Widget _buildAppointmentCard(String appointmentId, Map<String, dynamic> data) {
    final patientName = data['patientName'] ?? 'Paciente';
    final reason = data['reason'] ?? 'Sin motivo';
    final status = data['status'] ?? 'scheduled';
    final start = (data['start'] as Timestamp?)?.toDate() ?? DateTime.now();
    final end = (data['end'] as Timestamp?)?.toDate() ?? DateTime.now();

    final formattedDate = "${start.day}/${start.month}/${start.year}";
    final formattedTime = "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
    final duration = end.difference(start).inMinutes;

    // Color según estado
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'scheduled':
        statusColor = kOlive;
        statusIcon = Icons.schedule;
        statusText = 'Programada';
        break;
      case 'done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completada';
        break;
      case 'canceled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelada';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Desconocido';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAppointmentDetails(appointmentId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con paciente y estado
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kRoseLight,
                    radius: 24,
                    child: Text(
                      patientName[0].toUpperCase(),
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kRose,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Motivo
              Row(
                children: [
                  const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Fecha y hora
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '$formattedTime ($duration min)',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              // Botones de acción (solo para citas programadas)
              if (status == 'scheduled') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _completeAppointment(appointmentId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(
                          'Completar',
                          style: GoogleFonts.nunito(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelAppointment(appointmentId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(
                          'Cancelar',
                          style: GoogleFonts.nunito(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay citas',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'No se encontraron citas en el sistema'
                  : 'No hay citas con este estado',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar detalles de la cita
  void _showAppointmentDetails(String appointmentId, Map<String, dynamic> data) {
    final patientName = data['patientName'] ?? 'Paciente';
    final doctorName = data['doctorName'] ?? 'Doctor';
    final reason = data['reason'] ?? 'Sin motivo';
    final status = data['status'] ?? 'scheduled';
    final start = (data['start'] as Timestamp?)?.toDate() ?? DateTime.now();
    final end = (data['end'] as Timestamp?)?.toDate() ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Detalles de la Cita',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kRose,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.person, 'Paciente', patientName),
              _buildDetailRow(Icons.medical_services, 'Doctor', doctorName),
              _buildDetailRow(Icons.description, 'Motivo', reason),
              _buildDetailRow(Icons.calendar_today, 'Fecha', 
                "${start.day}/${start.month}/${start.year}"),
              _buildDetailRow(Icons.access_time, 'Hora', 
                "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}"),
              _buildDetailRow(Icons.info, 'Estado', 
                status == 'scheduled' ? 'Programada' : status == 'done' ? 'Completada' : 'Cancelada'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRose,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kRose),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Completar cita
  Future<void> _completeAppointment(String appointmentId) async {
    try {
      await _firestore.collection('citas').doc(appointmentId).update({
        'status': 'done',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cita marcada como completada',
              style: GoogleFonts.nunito(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar la cita: $e',
              style: GoogleFonts.nunito(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cancelar cita
  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Cancelar cita?',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas cancelar esta cita?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.nunito()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sí, cancelar', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('citas').doc(appointmentId).update({
          'status': 'canceled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cita cancelada',
                style: GoogleFonts.nunito(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al cancelar la cita: $e',
                style: GoogleFonts.nunito(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
