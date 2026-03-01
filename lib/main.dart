import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const JohbongApp());

class JohbongApp extends StatelessWidget {
  const JohbongApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const JohbongShell(),
    );
  }
}

class JohbongShell extends StatefulWidget {
  const JohbongShell({super.key});
  @override
  State<JohbongShell> createState() => _JohbongShellState();
}

class _JohbongShellState extends State<JohbongShell> {
  int _index = 0;
  String brandName = "JOHBONG"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [Color(0xFF0A1E3D), Color(0xFF020B18)],
                ),
              ),
            ),
          ),
          IndexedStack(
            index: _index,
            children: [
              HomeTab(brand: brandName),
              const Center(child: Text("Plans")),
              const Center(child: Text("Vouchers")),
              const Center(child: Text("Reports")),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildModernNav(),
    );
  }

  Widget _buildModernNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navBtn(Icons.dashboard_rounded, 0),
          _navBtn(Icons.bolt_rounded, 1),
          _navBtn(Icons.confirmation_num_rounded, 2),
          _navBtn(Icons.bar_chart_rounded, 3),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, int i) {
    bool active = _index == i;
    return IconButton(
      icon: Icon(icon, color: active ? const Color(0xFF2196F3) : Colors.white30, size: 28),
      onPressed: () => setState(() => _index = i),
    );
  }
}

class HomeTab extends StatelessWidget {
  final String brand;
  const HomeTab({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // BRANDING HEADER
            Row(
              children: [
                Image.asset('logo.png', height: 45, errorBuilder: (c, e, s) => 
                  const Icon(Icons.public, color: Colors.blue, size: 40)), // Fallback if image not found
                const SizedBox(width: 12),
                Text(brand, style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 40),
            // STATUS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      CircleAvatar(radius: 5, backgroundColor: Colors.cyanAccent),
                      SizedBox(width: 10),
                      Text("SYSTEM ONLINE", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.cyanAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("1.2 GB/s", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const Text("Current Network Load", style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
            const SizedBox(height: 50),
            // MAIN ACTION
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF0052D4)]),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20)],
              ),
              child: const Center(
                child: Text("GENERATE VOUCHER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
