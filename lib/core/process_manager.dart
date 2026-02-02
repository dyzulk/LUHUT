import 'dart:io';

class ProcessManagerService {
  Process? _nginxProcess;
  Process? _phpProcess;
  Process? _mysqlProcess;

  bool get isNginxRunning => _nginxProcess != null;
  bool get isPhpRunning => _phpProcess != null;
  bool get isMysqlRunning => _mysqlProcess != null;

  final String _binPath = 'bin';

  Future<void> startNginx() async {
    if (isNginxRunning) return;

    print("Starting Nginx...");
    try {
      _nginxProcess = await Process.start(
        '$_binPath/nginx/nginx.exe',
        [],
        workingDirectory: '$_binPath/nginx',
        runInShell: false,
      );
      print("Nginx started. PID: ${_nginxProcess?.pid}");
      
      _nginxProcess?.exitCode.then((code) {
        print("Nginx exited with code: $code");
        _nginxProcess = null;
      });
    } catch (e) {
      print("Failed to start Nginx: $e");
    }
  }

  Future<void> stopNginx() async {
    if (_nginxProcess != null) {
      print("Stopping Nginx...");
      // Nginx on Windows often needs forced kill or specific stop command
      // Trying gracious kill first
      _nginxProcess?.kill();
      // Also run taskkill to be sure, as nginx spawns worker processes
      await Process.run('taskkill', ['/IM', 'nginx.exe', '/F']);
      _nginxProcess = null;
    }
  }

  Future<void> startPHP(String version, int port) async {
    if (isPhpRunning) return;

    print("Starting PHP $version...");
    // Example path: bin/php/8.4/php-cgi.exe
    // Adjust based on actual folder structure extracted
    final phpExe = '$_binPath/php/8.4/php-cgi.exe'; 
    
    try {
      _phpProcess = await Process.start(
        phpExe,
        ['-b', '127.0.0.1:$port'], 
        runInShell: false,
      );
      print("PHP started. PID: ${_phpProcess?.pid}");

      _phpProcess?.exitCode.then((code) {
        print("PHP exited with code: $code");
        _phpProcess = null;
      });
    } catch (e) {
      print("Failed to start PHP: $e");
    }
  }

  Future<void> stopPHP() async {
    if (_phpProcess != null) {
      print("Stopping PHP...");
      _phpProcess?.kill();
      _phpProcess = null;
    }
  }

  Future<void> startMySQL() async {
    if (isMysqlRunning) return;

    print("Starting MySQL...");
    try {
      _mysqlProcess = await Process.start(
        '$_binPath/mysql/bin/mysqld.exe',
        ['--console'], // Output to stdout
        workingDirectory: '$_binPath/mysql',
      );
      print("MySQL started. PID: ${_mysqlProcess?.pid}");

      _mysqlProcess?.exitCode.then((code) {
        print("MySQL exited with code: $code");
        _mysqlProcess = null;
      });
    } catch (e) {
      print("Failed to start MySQL: $e");
    }
  }

  Future<void> stopMySQL() async {
    if (_mysqlProcess != null) {
      print("Stopping MySQL...");
      _mysqlProcess?.kill();
       // Also run taskkill for mysqld 
      await Process.run('taskkill', ['/IM', 'mysqld.exe', '/F']);
      _mysqlProcess = null;
    }
  }

  void stopAll() {
    stopNginx();
    stopPHP();
    stopMySQL();
  }
}
