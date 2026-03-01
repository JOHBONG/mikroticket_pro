import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MikroTicketApp());

class MikroTicketApp extends StatelessWidget {
  const MikroTicketApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text("MIKROTICKET PRO")),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Share.share("Your WiFi PIN: 8821"),
            child: const Text("GENERATE & SHARE"),
          ),
        ),
      ),
    );
  }
}
