import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
//import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class FormPage extends StatefulWidget {
  final Appointment? initial; 

  const FormPage({super.key, this.initial});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _svc = AppointmentService();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // catalogos ejemplo (no función)
  String? _doctorId;
  String? _patientId;
  final _doctors = const [
    {'id': 'd1', 'name': 'Dra. Martínez'},
    {'id': 'd2', 'name': 'Dr. López'},
  ];
  final _patients = const [
    {'id': 'p1', 'name': 'Alex García'},
    {'id': 'p2', 'name': 'Lili Vecino'},
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    if (a != null) {
      _reasonCtrl.text = a.reason;
      _doctorId = a.doctorId;
      _patientId = a.patientId;
      _date = DateTime(a.start.year, a.start.month, a.start.day);
      _startTime = TimeOfDay(hour: a.start.hour, minute: a.start.minute);
      _endTime = TimeOfDay(hour: a.end.hour, minute: a.end.minute);
    }
  }

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

  DateTime _combine(DateTime date, TimeOfDay t) =>
      DateTime(date.year, date.month, date.day, t.hour, t.minute);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_date == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y horas')),
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
        const SnackBar(content: Text('La hora fin debe ser posterior al inicio')),
      );
      return;
    }

    final doctor = _doctors.firstWhere((e) => e['id'] == _doctorId);
    final patient = _patients.firstWhere((e) => e['id'] == _patientId);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final base = Appointment(
      id: widget.initial?.id,
      ownerUid: uid, 
      patientId: patient['id']!,
      patientName: patient['name']!,
      doctorId: doctor['id']!,
      doctorName: doctor['name']!,
      reason: _reasonCtrl.text.trim(),
      start: start,
      end: end,
      status: widget.initial?.status ?? 'scheduled',
    );

    try {
      if (widget.initial == null) {
        await _svc.create(base); // Create
      } else {
        await _svc.update(base); // Update
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initial == null
              ? 'Cita creada correctamente'
              : 'Cita actualizada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initial == null ? 'Agendar cita' : 'Editar cita';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _doctorId,
                  items: _doctors
                      .map((d) => DropdownMenuItem(
                            value: d['id']!,
                            child: Text(d['name']!),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Médico',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _doctorId = v),
                  validator: (v) => v == null ? 'Selecciona un médico' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _patientId,
                  items: _patients
                      .map((p) => DropdownMenuItem(
                            value: p['id']!,
                            child: Text(p['name']!),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Paciente',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _patientId = v),
                  validator: (v) => v == null ? 'Selecciona un paciente' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la consulta',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el motivo' : null,
                ),
                const SizedBox(height: 12),

                _DateField(
                  label: 'Fecha',
                  value: _date == null
                      ? 'Selecciona fecha'
                      : '${_date!.day}/${_date!.month}/${_date!.year}',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),

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
                        value: _endTime == null
                            ? 'Selecciona'
                            : _endTime!.format(context),
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
                    child: Text(widget.initial == null ? 'Crear cita' : 'Guardar cambios'),
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
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: ' ',
          border: OutlineInputBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value),
          ],
        ),
      ),
    );
  }
}
