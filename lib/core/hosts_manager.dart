import 'dart:io';

class HostsManagerService {
  final String _hostsPath = r'C:\Windows\System32\drivers\etc\hosts';
  final String _domainSuffix = '.test';
  final String _markerStart = '# LUHUT-START';
  final String _markerEnd = '# LUHUT-END';

  /// Reads the current hosts file content
  Future<String> readHosts() async {
    try {
      final file = File(_hostsPath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return "";
    } catch (e) {
      print("Error reading hosts file: $e");
      return "";
    }
  }

  /// Scans 'sites' directory and returns list of potential .test domains
  Future<List<String>> scanSites() async {
    final sitesDir = Directory('sites');
    if (!await sitesDir.exists()) return [];

    final List<String> domains = [];
    await for (final entity in sitesDir.list()) {
      if (entity is Directory) {
        // Extract folder name and append suffix
        final name = entity.uri.pathSegments[entity.uri.pathSegments.length - 2];
        if (name.isNotEmpty) {
           domains.add('$name$_domainSuffix');
        }
      }
    }
    return domains;
  }

  /// Checks which domains are missing from hosts file
  Future<List<String>> getMissingDomains() async {
    final currentHosts = await readHosts();
    final allSites = await scanSites();
    
    return allSites.where((domain) => !currentHosts.contains("127.0.0.1 $domain")).toList();
  }

  /// Batch adds domains to hosts file
  Future<bool> fixMissingDomains(List<String> domains) async {
    if (domains.isEmpty) return true;

    print("Fixing domains: $domains");
    
    // Create specific entries
    final entries = domains.map((d) => "127.0.0.1 $d").join("\r\n");
    
    // Create a temporary script file
    final tempDir = Directory.systemTemp;
    final scriptFile = File('${tempDir.path}\\luhut_hosts_fix.ps1');
    
    // Write the PowerShell script content
    // We use Add-Content with proper formatting
    final scriptContent = '''
\$hostsPath = "$_hostsPath"
\$entries = @"
$entries
"@

Add-Content -Path \$hostsPath -Value "`r`n\$entries" -Force
''';

    await scriptFile.writeAsString(scriptContent);
    
    // Execute the script
    return await _runElevated(scriptFile.path);
  }

  /// Runs a PowerShell script file with Elevation (Admin)
  Future<bool> _runElevated(String scriptPath) async {
    try {
      final result = await Process.run(
        'powershell', 
        [
          '-Command', 
          'Start-Process powershell -Verb RunAs -ArgumentList \'-NoProfile -ExecutionPolicy Bypass -File "$scriptPath"\' -Wait'
        ]
      );
      
      return result.exitCode == 0;
    } catch (e) {
      print("Elevation failed: $e");
      return false;
    }
  }
}
