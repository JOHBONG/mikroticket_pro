import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MikroTicketFinal());

class MikroTicketFinal extends StatelessWidget {
  const MikroTicketFinal({super.key});
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
      const Scaffold(body: Center(child: Text("Plans Page"))),
      const Scaffold(body: Center(child: Text("Tickets History"))),
      const Scaffold(body: Center(child: Text("Printer Settings"))),
      isAdmin ? const ReportPage() : AdminLockPage(onSuccess: () => setState(() => isAdmin = true)),
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
            const Text("Generate New Ticket", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Text(brandName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  const Icon(Icons.qr_code, color: Colors.black, size: 50),
                  const Text("PIN: 8821-0092", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.print),
                    label: const Text("PRINT"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Share.share("Jambo! Your WiFi PIN is: 8821-0092. Karibu!");
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("WHATSAPP"),
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

class AdminLockPage extends StatefulWidget {
  final VoidCallback onSuccess;
  const AdminLockPage({super.key, required this.onSuccess});
  @override
  State<AdminLockPage> createState() => _AdminLockPageState();
}
class _AdminLockPageState extends State<AdminLockPage> {
  String pin = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, color: Colors.pinkAccent, size: 50),
        const Text("Admin Access Required"),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Icon(Icons.circle, size: 12, color: i < pin.length ? Colors.pinkAccent : Colors.white12))),
        const SizedBox(height: 20),
        Wrap(spacing: 20, runSpacing: 20, children: List.generate(9, (index) => IconButton(
          onPressed: () {
            setState(() => pin += "${index + 1}");
            if (pin == "1234") widget.onSuccess();
            if (pin.length >= 4 && pin != "1234") setState(() => pin = "");
          },
          icon: CircleAvatar(child: Text("${index + 1}")),
        ))),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onCreateTap;
  const HomePage({super.key, required this.onCreateTap});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Router: 192.168.88.1", style: TextStyle(color: Colors.greenAccent)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), minimumSize: const Size(double.infinity, 70)),
                onPressed: onCreateTap,
                child: const Text("CREATE VOUCHER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Total Revenue: Tsh 0", style: TextStyle(fontSize: 24, color: Colors.greenAccent))));
  }
}
