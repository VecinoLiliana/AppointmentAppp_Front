import 'package:flutter/material.dart';
import 'models/appointment.dart';
import 'services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _svc = AppointmentService();

  DateTime? _date;        // solo fecha
  TimeOfDay? _startTime;  // hora inicio
  TimeOfDay? _endTime;    // hora fin

  String? _doctorId;
  String? _patientId;

  //reemplaza por consultas a Firestore 
  final _doctors = const [
    {'id': 'd1', 'name': 'Dra. Martínez'},
    {'id': 'd2', 'name': 'Dr. López'},
    {'id': 'd3', 'name': 'Dra. Pérez'},
  ];
  final _patients = const [
    {'id': 'p1', 'name': 'Alex García'},
    {'id': 'p2', 'name': 'Lili Vecino'},
    {'id': 'p3', 'name': 'Anita Pérez'},
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? now,
    );
    if (res != null) setState(() => _date = res);
  }

  Future<void> _pickStartTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (res != null) setState(() => _startTime = res);
  }

  Future<void> _pickEndTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (res != null) setState(() => _endTime = res);
  }

  DateTime _combine(DateTime date, TimeOfDay tod) =>
      DateTime(date.year, date.month, date.day, tod.hour, tod.minute);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_date == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y horas de la cita')),
      );
      return;
    }
    if (_doctorId == null || _patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona médico y paciente')),
      );
      return;
    }

    final start = _combine(_date!, _startTime!);
    final end = _combine(_date!, _endTime!);
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser posterior al inicio')),
      );
      return;
    }

    final doctor = _doctors.firstWhere((e) => e['id'] == _doctorId);
    final patient = _patients.firstWhere((e) => e['id'] == _patientId);
    final uid = FirebaseAuth.instance.currentUser!.uid;


    final appt = Appointment(
      id: null,
      ownerUid: uid,   
      patientId: patient['id']!,
      patientName: patient['name']!,
      doctorId: doctor['id']!,
      doctorName: doctor['name']!,
      reason: _reasonCtrl.text.trim(),
      start: start,
      end: end,
      status: 'scheduled',
    );

    try {
      await _svc.create(appt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita creada correctamente'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // regresar al listado/home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la cita: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cita')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Doctor
                DropdownButtonFormField<String>(
                  value: _doctorId,
                  items: _doctors
                      .map((d) => DropdownMenuItem(
                            value: d['id']!,
                            child: Text(d['name']!),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Médico',
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _doctorId = v),
                  validator: (v) => v == null ? 'Selecciona un médico' : null,
                ),
                const SizedBox(height: 12),

                // Paciente
                DropdownButtonFormField<String>(
                  value: _patientId,
                  items: _patients
                      .map((p) => DropdownMenuItem(
                            value: p['id']!,
                            child: Text(p['name']!),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Paciente',
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _patientId = v),
                  validator: (v) => v == null ? 'Selecciona un paciente' : null,
                ),
                const SizedBox(height: 12),

                // Motivo
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Motivo de la consulta',
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el motivo' : null,
                ),
                const SizedBox(height: 12),

                // Fecha
                _DateField(
                  label: 'Fecha',
                  value: _date == null
                      ? 'Selecciona fecha'
                      : '${_date!.day}/${_date!.month}/${_date!.year}',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),

                // Horas
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Hora inicio',
                        value: _startTime == null
                            ? 'Selecciona'
                            : _startTime!.format(context),
                        onTap: _pickStartTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Hora fin',
                        value:
                            _endTime == null ? 'Selecciona' : _endTime!.format(context),
                        onTap: _pickEndTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Crear cita'),
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: const OutlineInputBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(value),
        ),
      ),
    );
  }
}
