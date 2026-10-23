import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final Function(ThemeMode) updateThemeMode;

  const SettingsPage({Key? key, required this.updateThemeMode}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      setState(() {
        _currentThemeMode = _themeModeFromString(themeModeString);
      });
    }
  }

  ThemeMode _themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      return 'system';
    }
  }

  void _handleThemeChange(ThemeMode? value) async {
    if (value != null) {
      setState(() {
        _currentThemeMode = value;
      });
      widget.updateThemeMode(value);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('themeMode', _themeModeToString(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.grey[900], 
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Light Mode'),
            leading: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: _currentThemeMode,
              onChanged: _handleThemeChange,
            ),
          ),
          ListTile(
            title: const Text('Dark Mode'),
            leading: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: _currentThemeMode,
              onChanged: _handleThemeChange,
            ),
          ),
          ListTile(
            title: const Text('System Default'),
            leading: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: _currentThemeMode,
              onChanged: _handleThemeChange,
            ),
          ),
        ],
      ),
    );
  }
}
