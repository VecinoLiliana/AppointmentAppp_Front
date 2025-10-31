import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;            // null al crear; Firestore lo asigna
  final String ownerUid;       //autenticación de usuario
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String reason;
  final DateTime start;        // inicio
  final DateTime end;          //fin
  final String status;         // scheduled|canceled|done
  final Timestamp? createdAt;

  Appointment({
    this.id,
    required this.patientId,
    required this.ownerUid,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.reason,
    required this.start,
    required this.end,
    this.status = 'scheduled',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'ownerUid': ownerUid,
    'patientId': patientId,
    'patientName': patientName,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'reason': reason,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'status': status,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      ownerUid: d['ownerUid'] as String? ?? '',
      patientId: d['patientId'],
      patientName: d['patientName'],
      doctorId: d['doctorId'],
      doctorName: d['doctorName'],
      reason: d['reason'] ?? '',
      start: (d['start'] as Timestamp).toDate(),
      end: (d['end'] as Timestamp).toDate(),
      status: d['status'] ?? 'scheduled',
      createdAt: d['createdAt'] as Timestamp?,
    );
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? ownerUid,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? reason,
    DateTime? start,
    DateTime? end,
    String? status,
    Timestamp? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      ownerUid: ownerUid ?? this.ownerUid,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      reason: reason ?? this.reason,
      start: start ?? this.start,
      end: end ?? this.end,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
