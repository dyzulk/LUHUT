import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:luhut/ui/dashboard.dart';
import 'package:luhut/ui/settings.dart';
import 'package:luhut/ui/sites_page.dart';
import 'package:provider/provider.dart';
import 'package:luhut/core/process_manager.dart';
import 'package:luhut/core/hosts_manager.dart';
import 'package:luhut/core/config_manager.dart';
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
        ChangeNotifierProvider(create: (_) => ConfigManager()),
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
      body: Stack(
        children: [
          // -- AMBIENT BACKGROUND GLOW --
          // Top Left Glow (Blue/Purple)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.15),
                    Colors.purpleAccent.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom Right Glow (Cyan/Green)
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.cyanAccent.withOpacity(0.1),
                    Colors.tealAccent.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // -- MAIN GLASS SURFACE --
          Container(
            color: const Color(0xE6050505), // ~90% Opacity (Much simpler/solid)
            child: Column(
              children: [
                const WindowTitleBar(),
                Expanded(
                  child: Row(
                    children: [
                      // --- SIDEBAR ---
                      Container(
                        width: 240, 
                        margin: const EdgeInsets.only(top: 0, bottom: 20, left: 20),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4), // Darker Sidebar
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.2),
                               blurRadius: 20,
                               offset: const Offset(0, 10),
                             )
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // -- APP BRANDING --
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blueAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.2)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Image.asset('assets/logo.png', width: 24, height: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Luhut",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        "Local Universal Handling Utility Tool",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 8,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // -- MENU --
                            Text(
                              "MAIN MENU",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _SidebarItem(
                              icon: Icons.dashboard_rounded,
                              label: "Dashboard",
                              activeColor: Colors.blueAccent,
                              isSelected: _selectedIndex == 0,
                              onTap: () => setState(() => _selectedIndex = 0),
                            ),
                            const SizedBox(height: 8),
                            _SidebarItem(
                              icon: Icons.folder_copy_rounded,
                              label: "My Sites",
                              activeColor: Colors.purpleAccent, // Changed to Purple
                              isSelected: _selectedIndex == 1,
                              onTap: () => setState(() => _selectedIndex = 1),
                            ),
                            
                            const Spacer(),

                            // -- BOTTOM --
                            Divider(color: Colors.white.withOpacity(0.05)),
                            const SizedBox(height: 16),
                             _SidebarItem(
                              icon: Icons.settings_rounded,
                              label: "Settings",
                              activeColor: Colors.grey,
                              isSelected: _selectedIndex == 2,
                              onTap: () => setState(() => _selectedIndex = 2),
                            ),
                          ],
                        ),
                      ),
                      
                      // --- MAIN CONTENT ---
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 10), 
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: const [
                              DashboardPage(),
                              SitesPage(),
                              SettingsPage(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: activeColor.withOpacity(0.2),
        highlightColor: activeColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withOpacity(0.3) : Colors.transparent
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (isSelected) 
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(blurRadius: 5, color: activeColor.withOpacity(0.6))
                    ]
                  ),
                )
            ],
          ),
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
