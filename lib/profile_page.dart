import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController enfermedadesController = TextEditingController();
  final TextEditingController alergiasController = TextEditingController();

  bool _loading = false;

  // Paleta Bloombites
  static const kRose      = Color(0xFFF297A0); // principal
  static const kRoseLight = Color(0xFFF9D0CE);
  static const kCream     = Color(0xFFF3EBD8);
  static const kOlive     = Color(0xFFB6BB79); // secundario

  // Cambia a kRoseLight si prefieres inputs rosados
  final Color fill = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    enfermedadesController.dispose();
    alergiasController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      nombreController.text       = (data['nombre'] ?? '') as String;
      telefonoController.text     = (data['telefono'] ?? '') as String;
      enfermedadesController.text = (data['enfermedades'] ?? '') as String;

      final List<dynamic>? alergiasList = data['alergias'] as List<dynamic>?;
      if (alergiasList != null) {
        alergiasController.text = alergiasList.map((e) => e.toString()).join(', ');
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar el perfil: $e')),
        );
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final alergias = alergiasController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': nombreController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'enfermedades': enfermedadesController.text.trim(),
        'alergias': alergias,
        'email': user.email,
        'uid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final nuevoNombre = nombreController.text.trim();
      if (nuevoNombre.isNotEmpty && nuevoNombre != (user.displayName ?? '')) {
        await user.updateDisplayName(nuevoNombre);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Información guardada exitosamente'),
            backgroundColor: kRose,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar: $e'),
            backgroundColor: kRoseLight,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _prettyInput(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: fill,
      labelStyle: GoogleFonts.nunito(color: Colors.black87),
      hintStyle: GoogleFonts.nunito(color: Colors.black54),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: kRoseLight.withOpacity(0.25),
      appBar: AppBar(
        title: Text(
          "Perfil",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: kRose,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRose))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Encabezado con IconPink ----
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kRoseLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icono rosado
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kRoseLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kRoseLight),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                'lib/assets/IconPink.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Texto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hola, ${user?.displayName ?? 'usuario'}",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: kRose, // rosa principal
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Correo: ${user?.email ?? 'No disponible'}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: nombreController,
                        decoration: _prettyInput('Nombre completo'),
                        style: GoogleFonts.nunito(fontSize: 16),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: telefonoController,
                        decoration: _prettyInput('Teléfono'),
                        style: GoogleFonts.nunito(fontSize: 16),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          final d = (v ?? '').trim();
                          if (d.isEmpty) return 'Ingresa tu teléfono';
                          if (d.length < 8) return 'Teléfono inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: alergiasController,
                        decoration: _prettyInput('Alergias (separadas por coma)', hint: 'Penicilina, Mariscos'),
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: enfermedadesController,
                        decoration: _prettyInput('Enfermedades'),
                        style: GoogleFonts.nunito(fontSize: 16),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Guardar (rosa)
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _saveUserData,
                          style: FilledButton.styleFrom(
                            backgroundColor: kRose,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Guardar información",
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      //Cerrar sesión
                      SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  await _auth.signOut();
                                  if (!mounted) return;
                                  Navigator.pushReplacementNamed(context, Routes.login);
                                },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kOlive,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: kOlive),
                            ),
                          ),
                          child: Text(
                            "Cerrar sesión",
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
