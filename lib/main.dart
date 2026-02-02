import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:luhut/ui/dashboard.dart';
import 'package:luhut/ui/settings.dart';
import 'package:luhut/ui/sites_page.dart';
import 'package:provider/provider.dart';
import 'package:luhut/core/process_manager.dart';
import 'package:luhut/core/hosts_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await Window.initialize();
  
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: const Color(0xF2222222), // More opaque (was 0xCC)
  );

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 650),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ProcessManagerService()),
        Provider(create: (_) => HostsManagerService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Luhut',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.dark().textTheme,
          ),
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        home: const MainWindowScaffold(),
      ),
    );
  }
}

class MainWindowScaffold extends StatefulWidget {
  const MainWindowScaffold({super.key});

  @override
  State<MainWindowScaffold> createState() => _MainWindowScaffoldState();
}

class _MainWindowScaffoldState extends State<MainWindowScaffold> with WindowListener {
  final SystemTray _systemTray = SystemTray();
  final Menu _menuMain = Menu();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true); // Prevent app from closing on X
    _initSystemTray();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initSystemTray() async {
    String iconPath = Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    await _systemTray.initSystemTray(
      title: "Luhut Manager",
      iconPath: iconPath,
    );

    await _menuMain.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => windowManager.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => windowManager.hide()),
      MenuSeparator(),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => _closeApp()),
    ]);

    await _systemTray.setContextMenu(_menuMain);

    // Handle Left Click on Tray Icon
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
        windowManager.focus();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }
  
  void _closeApp() async {
     await windowManager.destroy(); // Actually close the app
     // Perform any cleanup here if needed
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = true;
    if (_isPreventClose) {
      await windowManager.hide();
    }
    // To close: windowManager.destroy()
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color(0xAA000000), // Semi-transparent background
        child: Column(
          children: [
            const WindowTitleBar(),
            Expanded(
              child: Row(
                children: [
                  // --- SIDEBAR ---
                  Container(
                    width: 70, // Compact Sidebar width
                    margin: const EdgeInsets.only(top: 0, bottom: 20, left: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard_rounded,
                          label: "Home",
                          isSelected: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        const SizedBox(height: 16),
                        _SidebarItem(
                          icon: Icons.folder_copy_rounded,
                          label: "Sites",
                          isSelected: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                        const SizedBox(height: 16),
                        _SidebarItem(
                          icon: Icons.settings_rounded,
                          label: "Config",
                          isSelected: _selectedIndex == 2,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- MAIN CONTENT ---
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: const [
                        DashboardPage(),
                        SitesPage(),
                        SettingsPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blueAccent : Colors.white54,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: Container(
        height: 32,
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(child: Container()), // Draggable area
            const WindowButtons(),
          ],
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowButton(
          icon: Icons.minimize,
          onPressed: () => windowManager.minimize(),
          hoverColor: const Color(0xFF404040),
        ),
        _WindowButton(
          icon: Icons.check_box_outline_blank, // Custom square icon often better, but using standard for now
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          hoverColor: const Color(0xFF404040),
        ),
        _WindowButton(
          icon: Icons.close,
          onPressed: () => windowManager.close(),
          hoverColor: const Color(0xFFD32F2F),
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero, // Important for tight fit
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return hoverColor;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return Colors.white;
            return const Color(0xFFEEEEEE);
          }),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );
  }
}
