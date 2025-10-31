import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentService {
  final _col = FirebaseFirestore.instance.collection('citas');

  // CREATE (con validación de solapamiento)
  Future<String> create(Appointment a) async {
    await _ensureNoOverlap(a.doctorId, a.start, a.end, excludeId: null);
    final ref = await _col.add(a.toMap());
    return ref.id;
  }

  // READ (streams para listas)
  Stream<List<Appointment>> streamUpcomingForUser(String uid, {bool isDoctor = false}) {
    final now = DateTime.now();
    final q = _col
        .where(isDoctor ? 'doctorId' : 'patientId', isEqualTo: uid)
        .where('end', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('end');

    return q.snapshots().map((s) => s.docs.map(Appointment.fromDoc).toList());
  }

  Stream<List<Appointment>> streamAllByDoctor(String doctorId, {DateTime? from}) {
    final q = _col
        .where('doctorId', isEqualTo: doctorId)
        .where('start', isGreaterThan: Timestamp.fromDate(from ?? DateTime(2000)))
        .orderBy('start');
    return q.snapshots().map((s) => s.docs.map(Appointment.fromDoc).toList());
  }

  Future<Appointment> getById(String id) async {
    final doc = await _col.doc(id).get();
    return Appointment.fromDoc(doc);
  }

  // UPDATE (con validación)
  Future<void> update(Appointment a) async {
    if (a.id == null) throw Exception('Falta ID de la cita');
    await _ensureNoOverlap(a.doctorId, a.start, a.end, excludeId: a.id);
    await _col.doc(a.id!).update(a.toMap());
  }

  // DELETE
  Future<void> delete(String id) async => _col.doc(id).delete();

  // --- Validación de solapamientos por doctor ---
  // Hay solape si existe una cita con:
  // start < nuevoEnd && end > nuevoStart
  Future<void> _ensureNoOverlap(
    String doctorId,
    DateTime start,
    DateTime end, {
    String? excludeId,
  }) async {
    final q = await _col
        .where('doctorId', isEqualTo: doctorId)
        .where('start', isLessThan: Timestamp.fromDate(end))
        .where('end', isGreaterThan: Timestamp.fromDate(start))
        .get();

    final conflict = q.docs.any((d) => d.id != excludeId);
    if (conflict) {
      throw Exception('El horario seleccionado se sobrepone con otra cita del doctor.');
    }
  }
}
