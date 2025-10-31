import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedInitialData() async {
  final db = FirebaseFirestore.instance;

  // Usuarios
  await db.collection('usuarios').add({
    'nombre': 'Liliana Vecino',
    'email': '[email protected]',
    'rol': 'paciente',
    'telefono': '+52 9999999999',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // Cita
  await db.collection('citas').add({
    'pacienteId': 'p1',
    'doctorId': 'd1',
    'motivo': 'Consulta general',
    'fechaHora': Timestamp.now(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Disponibilidad de médico
  await db.collection('disponibilidad_medicos').add({
    'medicoId': 'd1',
    'fecha': DateTime.now(),
    'horaInicio': '09:00',
    'horaFin': '12:00',
    'esta_disponible': true,
  });

  print('Datos iniciales creados correctamente');
}
