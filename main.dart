import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // For WhatsApp/Sharing

void main() => runApp(const MikroTicketPro());

class MikroTicketPro extends StatelessWidget {
  const MikroTicketPro({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020D1C),
        primaryColor: const Color(0xFFD81B60),
      ),
      home: const MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});
  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;
  bool isAdmin = false;
  String brandName = "MY WIFI NET";

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onCreateTap: _showCreateTicketSheet),
      const Scaffold(body: Center(child: Text("Plans List"))),
      const Scaffold(body: Center(child: Text("Active Vouchers"))),
      const Scaffold(body: Center(child: Text("Printer Settings"))),
      const Scaffold(body: Center(child: Text("Revenue Report"))),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF041529),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.print), label: 'Printer'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Revenue'),
        ],
      ),
    );
  }

  void _showCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1D33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Generate Voucher", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Preview
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.white,
              child: Column(
                children: [
                  Text(brandName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  const Icon(Icons.qr_code, color: Colors.black, size: 60),
                  const Text("CODE: 8812-9901", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text("PRINT"),
                    onPressed: () {}, 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text("WHATSAPP"),
                    onPressed: () {
                      Share.share("Jambo! Your WiFi Code is: 8812-9901. Valid for 1 Day. Enjoy!");
                    }, 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Simple Home Page structure
class HomePage extends StatelessWidget {
  final VoidCallback onCreateTap;
  const HomePage({super.key, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const ListTile(title: Text("192.168.88.1"), subtitle: Text("Router Online"), trailing: CircleAvatar(backgroundColor: Colors.green, radius: 5)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 60)),
              onPressed: onCreateTap,
              child: const Text("CREATE NEW VOUCHER"),
            ),
          )
        ],
      ),
    );
  }
}
