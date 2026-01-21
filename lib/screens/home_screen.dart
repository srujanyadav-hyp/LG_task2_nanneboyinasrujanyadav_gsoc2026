import 'package:flutter/material.dart';
import '../services/lg_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LgService _lgService = LgService();

  // Controllers
  final _ipController = TextEditingController(text: "192.168.56.101");
  final _userController = TextEditingController(text: "lg");
  final _passController = TextEditingController(text: "lg");
  final _portController = TextEditingController(text: "22");
  final _screensController = TextEditingController(text: "3");

  bool isConnected = false;
  bool _showPassword = false; // State to toggle password visibility

  // Helper to show Snackbars
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Connection Logic
  Future<void> _connect() async {
    bool res = await _lgService.connectToLG(
      _ipController.text,
      _userController.text,
      _passController.text,
      int.parse(_portController.text),
    );

    setState(() => isConnected = res);

    if (res) {
      _showSnackbar("Connected to Liquid Galaxy!", Colors.green);
    } else {
      _showSnackbar(
        " Connection Failed. Check Connection information is Correct",
        Colors.red,
      );
    }
  }

  // Wrapper for Actions to show Snackbars
  Future<void> _executeAction(
    String label,
    Future<void> Function() action,
  ) async {
    await action();
    _showSnackbar(" $label Executed", Colors.blueAccent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("GSoC Task 2"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // CONNECTION FORM
            _buildInput(_ipController, "IP Address"),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildInput(_userController, "Username")),
                const SizedBox(width: 10),

                // PASSWORD FIELD WITH TOGGLE
                Expanded(
                  child: TextField(
                    controller: _passController,
                    obscureText: !_showPassword, // Toggles based on state
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildInput(_portController, "Port")),
                const SizedBox(width: 10),
                Expanded(child: _buildInput(_screensController, "Screens")),
              ],
            ),
            const SizedBox(height: 20),

            // CONNECT BUTTON
            ElevatedButton.icon(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green : Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(isConnected ? Icons.check : Icons.power),
              label: Text(isConnected ? "CONNECTED" : "CONNECT"),
            ),

            const Divider(color: Colors.white, height: 40),

            // ACTIONS
            Row(
              children: [
                Expanded(
                  child: _buildBtn(
                    "Send Logo",
                    Colors.purple,
                    () => _executeAction(
                      "Logo Sent",
                      () => _lgService.sendLogo(
                        int.parse(_screensController.text),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBtn(
                    "Clean Logo",
                    Colors.purple.shade200,
                    () => _executeAction(
                      "Logo Cleaned",
                      () => _lgService.cleanLogos(
                        int.parse(_screensController.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildBtn(
                    "Send Pyramid",
                    Colors.orange,
                    () => _executeAction(
                      "Pyramid Sent",
                      () => _lgService.sendPyramid(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBtn(
                    "Clean KML",
                    Colors.orange.shade200,
                    () => _executeAction(
                      "Pyramid Cleaned",
                      () => _lgService.cleanKmls(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildBtn(
              "Fly to Vizag",
              Colors.blue,
              () => _executeAction(
                "Flying to Vizag...",
                () => _lgService.flyToVizag(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Standard Inputs
  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Helper for Buttons
  Widget _buildBtn(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isConnected ? onTap : null, // Disable if not connected
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
