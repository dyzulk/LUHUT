import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:luhut/core/process_manager.dart';
import 'package:luhut/core/hosts_manager.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Poll process status every 2 seconds to update UI
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pm = context.read<ProcessManagerService>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Removed duplicate header
          const SizedBox(height: 10),
          _buildServiceCard(
            context, 
            "Nginx Web Server", 
            "80", 
            pm.isNginxRunning,
            () async {
              if (pm.isNginxRunning) {
                await pm.stopNginx();
              } else {
                await pm.startNginx();
              }
              setState(() {});
            }
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context, 
            "PHP FastCGI", 
            "9000", 
            pm.isPhpRunning,
            () async {
              if (pm.isPhpRunning) {
                await pm.stopPHP();
              } else {
                await pm.startPHP('8.4', 9000);
              }
              setState(() {});
            }
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context, 
            "MySQL Database", 
            "3306", 
            pm.isMysqlRunning,
             () async {
              if (pm.isMysqlRunning) {
                await pm.stopMySQL();
              } else {
                await pm.startMySQL();
              }
              setState(() {});
            }
          ),

          const SizedBox(height: 30),
          _buildSitesCard(context),
          
          const Spacer(),
          Center(

            child: Text(
              "Luhut v0.1.0 Beta",
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String name, String port, bool isRunning, VoidCallback onToggle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Status Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isRunning ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isRunning ? Colors.greenAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                  blurRadius: 6,
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isRunning ? "Running on port $port" : "Stopped",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Action Button
          FilledButton.tonal(
            onPressed: onToggle,
            style: FilledButton.styleFrom(
              backgroundColor: isRunning ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              foregroundColor: isRunning ? Colors.redAccent : Colors.white,
            ),
            child: Text(isRunning ? "Stop" : "Start"),
          ),
        ],
      ),
    );
  }

  Widget _buildSitesCard(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: context.read<HostsManagerService>().getMissingDomains(),
      builder: (context, snapshot) {
        final missing = snapshot.data ?? [];
        final count = missing.length;
        final hasIssues = count > 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasIssues ? Colors.orange.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasIssues ? Colors.orange.withOpacity(0.3) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasIssues ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: hasIssues ? Colors.orange : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasIssues ? "$count Sites Need Registration" : "All Sites Registered",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hasIssues ? "Click to fix hosts file" : "System is up to date",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasIssues)
                FilledButton.tonal(
                  onPressed: () async {
                    await context.read<HostsManagerService>().fixMissingDomains(missing);
                    setState(() {}); // Refresh UI
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text("Fix All"),
                ),
            ],
          ),
        );
      },
    );
  }
}
