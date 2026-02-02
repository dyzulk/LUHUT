import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package later
import 'package:luhut/core/hosts_manager.dart';

class SitesPage extends StatefulWidget {
  const SitesPage({super.key});

  @override
  State<SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<SitesPage> {
  // Using HostsManagerService to get the list since it already scans the directory
  
  @override
  Widget build(BuildContext context) {
    final hostsManager = context.watch<HostsManagerService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                "My Sites",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                   // Refresh logic
                   hostsManager.scanSites(); 
                   setState(() {});
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Refresh"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Grid List
        Expanded(
          child: FutureBuilder<List<String>>(
            future: _getSiteList(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text("No sites found", style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 8),
                      Text("Create a folder in 'sites/' to get started", style: TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                );
              }

              final sites = snapshot.data!;
              
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 columns
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  return _buildSiteCard(sites[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<String>> _getSiteList(BuildContext context) async {
    // We already have logic in HostsManager to scan, but let's reuse/expose it better 
    // or just duplicate the logic slightly for UI purposes (displaying names)
    // Actually, HostsManagerService.scanSites returns Future<List<String>>.
    return context.read<HostsManagerService>().scanSites();
  }

  Widget _buildSiteCard(String domainName) {
    final folderName = domainName.replaceAll('.test', '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHover: (hovering) {}, 
          onTap: () {
            _launchUrl("http://$domainName");
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.language, color: Colors.blueAccent, size: 20),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.folder_open, color: Colors.white38, size: 20),
                      onPressed: () {
                         _openFolder(folderName);
                      },
                      tooltip: "Open Folder",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  folderName, // Display Folder Name (Project Name)
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  domainName, // Display Domain
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri)) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch $url")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _openFolder(String folderName) async {
      String path = "${Directory.current.path}\\sites\\$folderName";
      await Process.run('explorer', [path]);
  }
}
