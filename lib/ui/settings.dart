import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:luhut/core/config_manager.dart';
import 'package:luhut/core/process_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _nginxPortCtrl;
  late TextEditingController _mysqlPortCtrl;
  late TextEditingController _phpPortCtrl;
  bool? _enablePrettyUrls;
  bool? _autoStart;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConfigManager>().config;
    _nginxPortCtrl = TextEditingController(text: config.nginxPort.toString());
    _mysqlPortCtrl = TextEditingController(text: config.mysqlPort.toString());
    _phpPortCtrl = TextEditingController(text: config.phpPort.toString());
    _enablePrettyUrls = config.enablePrettyUrls;
    _autoStart = config.autoStart;
  }

  @override
  void dispose() {
    _nginxPortCtrl.dispose();
    _mysqlPortCtrl.dispose();
    _phpPortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes if needed, but we mostly read initial and write
    // final configManager = context.watch<ConfigManager>(); 

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Settings",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Domain Section
          _buildSectionHeader("Domain & Network"),
          _buildSwitchTile(
            title: "Pretty URLs (*.test)",
            subtitle: "Automatically map folder names to .test domains",
            value: _enablePrettyUrls ?? true,
            onChanged: (val) {
              setState(() => _enablePrettyUrls = val);
            },
          ),

          const SizedBox(height: 24),

          // System Section
          _buildSectionHeader("System"),
          _buildSwitchTile(
            title: "Start on Login",
            subtitle: "Automatically start Luhut when Windows starts",
            value: _autoStart ?? false,
            onChanged: (val) {
              setState(() => _autoStart = val);
            },
          ),
          
          const SizedBox(height: 24),

          // Ports Section
          _buildSectionHeader("Service Ports"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPortInput("Nginx (Web)", _nginxPortCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildPortInput("MySQL (DB)", _mysqlPortCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPortInput("PHP FastCGI", _phpPortCtrl)),
              const SizedBox(width: 16),
              Expanded(child: Container()), // Spacer
            ],
          ),

          const Spacer(),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () async {
                final manager = context.read<ConfigManager>();
                
                final newConfig = AppConfig(
                  enablePrettyUrls: _enablePrettyUrls ?? true,
                  nginxPort: int.tryParse(_nginxPortCtrl.text) ?? 80,
                  mysqlPort: int.tryParse(_mysqlPortCtrl.text) ?? 3306,
                  phpPort: int.tryParse(_phpPortCtrl.text) ?? 9000,
                  autoStart: _autoStart ?? false,
                );

                await manager.saveConfig(newConfig);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings Saved & Config Updated")),
                  );
                  
                  // Optional: Trigger Restart of Services if Ports Changed
                  // context.read<ProcessManagerService>().restartAll(); 
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title, 
    required String subtitle, 
    required bool value, 
    required ValueChanged<bool> onChanged
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value, 
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPortInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
      ],
    );
  }
}
