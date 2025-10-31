import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  // UI state
  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscure = true;

  // Campos comunes
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // Solo registro
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final allergiesCtrl = TextEditingController(); // coma-separado

  // Paleta
  static const kRose = Color(0xFFF297A0);     // principal
  static const kRoseLight = Color(0xFFF9D0CE);
  //static const kCream = Color(0xFFF3EBD8);
  static const kOlive = Color(0xFFB6BB79);    // secundario

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    allergiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isRegister) {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );

        final nombre = nameCtrl.text.trim();
        if (nombre.isNotEmpty) {
          await cred.user!.updateDisplayName(nombre);
        }

        final uid = cred.user!.uid;
        final alergias = allergiesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'uid': uid,
          'nombre': nombre,
          'email': emailCtrl.text.trim(),
          'telefono': phoneCtrl.text.trim(),
          'alergias': alergias,
          'enfermedades': '',
          'rol': 'paciente',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada e inicio de sesión'), backgroundColor: kRose),
        );
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        await _auth.signInWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso'), backgroundColor: kRose),
        );
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          msg = 'No existe una cuenta con ese correo.'; break;
        case 'wrong-password':
          msg = 'La contraseña es incorrecta.'; break;
        case 'email-already-in-use':
          msg = 'Ese correo ya está registrado.'; break;
        case 'invalid-email':
          msg = 'Correo inválido.'; break;
        case 'weak-password':
          msg = 'La contraseña es demasiado débil.'; break;
        default:
          msg = e.message ?? msg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: kRoseLight),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRoseLight),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo para recuperar la contraseña')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviamos un enlace de restablecimiento a $email'), backgroundColor: kRose),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'No fue posible enviar el correo.';
      if (e.code == 'user-not-found') msg = 'No existe una cuenta con ese correo.';
      if (e.code == 'invalid-email') msg = 'El correo no es válido.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: kRoseLight),
        );
      }
    }
  }

  // Cambia fillColor a kRoseLight si prefieres campos rosados:
  // final fill = kRoseLight;
  final Color fill = Colors.white;

  InputDecoration _prettyInput(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: fill, // <--- blanco (o cambia a kRoseLight)
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
    return Scaffold(
      backgroundColor: kRoseLight.withOpacity(0.25),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo + Título
                    Column(
                      children: [
                        Image.asset('lib/assets/appointmentIcon.png', height: 400),
                        const SizedBox(height: 10),
                        Text(
                          _isRegister ? 'Crear cuenta' : 'Iniciar sesión',
                          style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (_isRegister) ...[
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _prettyInput('Nombre completo'),
                        style: GoogleFonts.nunito(fontSize: 16),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _prettyInput('Teléfono'),
                        style: GoogleFonts.nunito(fontSize: 16),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu teléfono';
                          final d = v.replaceAll(RegExp(r'\D'), '');
                          if (d.length < 8) return 'Teléfono inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: allergiesCtrl,
                        decoration: _prettyInput('Alergias (separadas por coma)', hint: 'Penicilina, Mariscos'),
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: emailCtrl,
                      decoration: _prettyInput('Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      style: GoogleFonts.nunito(fontSize: 16),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: passCtrl,
                      decoration: _prettyInput('Contraseña').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      style: GoogleFonts.nunito(fontSize: 16),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Botón principal (rosa)
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: kRose,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isRegister ? 'Crear cuenta' : 'Iniciar sesión',
                                style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: kOlive, // secundario
                          ),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Toggle login/registro (verde secundario como borde/foreground)
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            _isRegister ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?',
                            style: GoogleFonts.nunito(color: Colors.black87),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isRegister = !_isRegister),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: kOlive,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: kOlive),
                              ),
                            ),
                            child: Text(
                              _isRegister ? 'Inicia sesión' : 'Crear cuenta',
                              style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, letterSpacing: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}