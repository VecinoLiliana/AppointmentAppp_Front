import 'package:flutter/material.dart';
import 'routes.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 1;

  final avatars = List.generate(6, (i) => "Dr. ${i + 1}");
  
  //Lista dinámica de mensajes (placeholders)
  final List<Map<String, String>> mensajes = [
    {
      "remitente": "Dr. Ramírez",
      "hora": "10:45 AM",
      "mensaje": "Hola, recuerda tu cita mañana temprano."
    },
    {
      "remitente": "Clínica Central",
      "hora": "9:12 AM",
      "mensaje": "Tus resultados están disponibles."
    },
    {
      "remitente": "Nutrióloga Pérez",
      "hora": "Ayer",
      "mensaje": "No olvides enviar tu registro semanal."
    },
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.home);
        break;
      case 1:
        // Ya estás en Mensajes
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: const Text("Mensajes"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Barra de búsqueda
              Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Iconocs horizontales
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) => _AvatarOnline(label: avatars[i]),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: avatars.length,
                ),
              ),
              const SizedBox(height: 12),

              // 💬 Lista de chats
              ListView.separated(
                itemCount: mensajes.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final mensaje = mensajes[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage('lib/assets/doctor_avatar.png'),
                    ),
                    title: Text(
                      mensaje["remitente"]!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      mensaje["mensaje"]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      mensaje["hora"]!,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    // Abrir detalles del mensaje
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(mensaje["remitente"]!),
                          content: Text(mensaje["mensaje"]!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cerrar"),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),

      //Botón flotante para agregar los mensajes
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF297A0), // Rosa BloomBites
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          setState(() {
            mensajes.add({
              "remitente": "Sistema Médico",
              "hora": "Ahora",
              "mensaje": "Nuevo mensaje automático de prueba."
            });
          });
        },
      ),

      //Menú inferior 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFF297A0), // Rosa BloomBites
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: "Mensajes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Config",
          ),
        ],
      ),
    );
  }
}

class _AvatarOnline extends StatelessWidget {
  final String label;
  const _AvatarOnline({required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage('lib/assets/doctor_avatar.png'),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        )
      ],
    );
  }
}