import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart'; 

class CitasPage extends StatefulWidget {
  const CitasPage({super.key});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _motivoController = TextEditingController();

  String? _nombreUsuario;
  DateTime? _fechaSeleccionada;
  String? _citaEnEdicion;

  // Paleta 
  static const kRose = Color(0xFFF297A0);
  static const kRoseLight = Color(0xFFF9D0CE);

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _nombreUsuario = doc.data()!['nombre'] ?? 'Usuario sin nombre';
        });
      }
    }
  }

  Future<void> _seleccionarFechaYHora() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_fechaSeleccionada ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _fechaSeleccionada = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _guardarCita() async {
    if (_motivoController.text.isEmpty || _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final data = {
      'nombreUsuario': _nombreUsuario ?? 'Sin nombre',
      'motivo': _motivoController.text.trim(),
      'fechaHora': Timestamp.fromDate(_fechaSeleccionada!),
      'creadoEn': FieldValue.serverTimestamp(),
    };

    if (_citaEnEdicion == null) {
      await _firestore.collection('citas').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Cita creada")));
      }
    } else {
      await _firestore.collection('citas').doc(_citaEnEdicion).update(data);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Cita actualizada")));
      }
    }

    _motivoController.clear();
    setState(() {
      _fechaSeleccionada = null;
      _citaEnEdicion = null;
    });
  }

  Future<void> _eliminarCita(String id) async {
    await _firestore.collection('citas').doc(id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cita eliminada")));
    }
  }

  void _editarCita(String id, Map<String, dynamic> data) {
    setState(() {
      _citaEnEdicion = id;
      _motivoController.text = data['motivo'] ?? '';
      _fechaSeleccionada =
          (data['fechaHora'] as Timestamp?)?.toDate() ?? DateTime.now();
    });
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunito(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kRoseLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kRoseLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kRose, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRoseLight.withOpacity(0.25),
      appBar: AppBar(
        title: Text(
          "Citas",
          style: GoogleFonts.fredoka(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: kRose,
        foregroundColor: Colors.white,
        elevation: 0,
        // 🔙 Flecha que regresa a Home
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, Routes.home);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Imagen arriba del encabezado
            Image.asset(
              'lib/assets/IconPanda.png',
              height: 200,
            ),
            const SizedBox(height: 10),

            // Encabezado con texto en fondo rosa claro
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kRoseLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kRoseLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreUsuario == null
                        ? 'Cargando usuario...'
                        : 'Hola, $_nombreUsuario',
                    style: GoogleFonts.fredoka(
                      color: kRose,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Aquí puedes programar o editar tus citas médicas.",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _motivoController,
              decoration: _inputDecor('Motivo de la cita'),
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kRoseLight),
                    ),
                    child: Text(
                      _fechaSeleccionada == null
                          ? 'No se ha seleccionado fecha y hora'
                          : '${_fechaSeleccionada.toString().substring(0, 16)}',
                      style: GoogleFonts.nunito(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: kRose),
                  onPressed: _seleccionarFechaYHora,
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kRose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _guardarCita,
                child: Text(
                  _citaEnEdicion == null ? 'Programar cita' : 'Guardar cambios',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de citas
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('citas')
                    .orderBy('fechaHora', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: kRose),
                    );
                  }

                  final citas = snapshot.data!.docs;
                  if (citas.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay citas programadas',
                        style: GoogleFonts.nunito(
                            color: Colors.black54, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: citas.length,
                    itemBuilder: (context, index) {
                      final cita = citas[index];
                      final data = cita.data() as Map<String, dynamic>;
                      final fecha =
                          (data['fechaHora'] as Timestamp?)?.toDate() ??
                              DateTime.now();

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: kRoseLight),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          title: Text(
                            data['motivo'] ?? 'Sin motivo',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w700,
                              color: kRose,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 18, color: kRose),
                                  const SizedBox(width: 6),
                                  Text(
                                    data['nombreUsuario'] ?? 'Desconocido',
                                    style: GoogleFonts.nunito(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined,
                                      size: 18, color: kRose),
                                  const SizedBox(width: 6),
                                  Text(
                                    fecha.toString().substring(0, 16),
                                    style: GoogleFonts.nunito(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit, color: kRose),
                                onPressed: () => _editarCita(cita.id, data),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline,
                                    color: kRose),
                                onPressed: () => _eliminarCita(cita.id),
                              ),
                            ],
                          ),
                        ),
                      );
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
}
