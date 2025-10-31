import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'form_page.dart';

class ListPage extends StatelessWidget {
  final String userId;   // uid del usuario logueado
  final bool isDoctor;   // true = ver citas del médico, false = del paciente
  const ListPage({super.key, required this.userId, this.isDoctor = false});

  @override
  Widget build(BuildContext context) {
    final svc = AppointmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FormPage()));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: svc.streamUpcomingForUser(userId, isDoctor: isDoctor),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No hay citas próximas'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = items[i];
              final range = '${_fmt(a.start)} - ${_fmt(a.end)}';
              return Card(
                child: ListTile(
                  title: Text(a.reason),
                  subtitle: Text('${isDoctor ? a.patientName : a.doctorName}\n$range'),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => FormPage(initial: a)));
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final ok = await _confirm(context, '¿Eliminar esta cita?');
                      if (ok) await svc.delete(a.id!);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} $hh:$mm';
  }

  Future<bool> _confirm(BuildContext ctx, String msg) async {
    final res = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    return res ?? false;
  }
}
