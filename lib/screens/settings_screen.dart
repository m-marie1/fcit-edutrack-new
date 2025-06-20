import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../style/my_app_colors.dart';
import '../themes/my_theme_data.dart';
import '../themes/theme_provider.dart';
import 'password/change_password_screen.dart';
import 'package:fci_edutrack/providers/allowed_mac_provider.dart';

class SettingsScreen extends StatefulWidget {
  // Changed to StatefulWidget
  static const String routeName = 'settings_screen';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState(); // Create state
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State class
  final TextEditingController _bssidController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch of allowed MACs for admin
    Future.microtask(() {
      final macProvider = context.read<AllowedMacProvider>();
      macProvider.fetchAllowedMacs();
    });
  }

  @override
  void dispose() {
    _bssidController.dispose(); // Dispose controller
    super.dispose();
  }

  Future<void> _addMacAddress(BuildContext context) async {
    final macProvider = context.read<AllowedMacProvider>();
    final newMac = _bssidController.text.trim();
    if (newMac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('MAC address cannot be empty'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isProcessing = true);
    await macProvider.addMac(newMac);
    _bssidController.clear();
    setState(() => _isProcessing = false);
  }

  Future<void> _resetAllMacAddresses(BuildContext context) async {
    setState(() => _isProcessing = true);
    await context.read<AllowedMacProvider>().clearAll();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    // Read role directly from provider inside build
    final authProvider = Provider.of<AuthProvider>(context);
    final macProvider = Provider.of<AllowedMacProvider>(context);
    // Use getters from AuthProvider which now correctly compare roles
    final bool isAdmin = authProvider.currentUser?.role?.toUpperCase() ==
        'ADMIN'; // Use normalized role
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get theme provider instance
    return Scaffold(
      appBar: (isAdmin)
          ? null
          : AppBar(
              title: Text(
                'Settings',
                style: MyThemeData.lightModeStyle.textTheme.titleMedium!
                    .copyWith(color: MyAppColors.whiteColor),
              ),
              elevation: 0,
              centerTitle: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(MediaQuery.of(context).size.width * 0.1),
                  bottomRight:
                      Radius.circular(MediaQuery.of(context).size.width * 0.1),
                ),
              ),
              backgroundColor: MyAppColors.primaryColor,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: MyAppColors.whiteColor,
                ),
              ),
            ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView for smaller screens
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align titles left
          children: [
            // --- Theme Settings ---
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.09),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // Adjusted radius
                border: Border.all(
                  color: themeProvider.isDark() // Use instance
                      ? Colors.blueGrey.shade700 // Adjusted colors
                      : Colors.grey.shade300,
                ),
                color: themeProvider.isDark()
                    ? Colors.grey.shade800
                    : Colors.white, // Background color
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode'),
                  CupertinoSwitch(
                    activeTrackColor: MyAppColors.primaryColor,
                    value: themeProvider.isDark(), // Use instance
                    onChanged: (value) {
                      themeProvider.toggleTheme(); // Use instance
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            if (!isAdmin)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Password Settings ---
                  Text('Security',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.09),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12), // Adjusted radius
                      border: Border.all(
                        color: themeProvider.isDark() // Use instance
                            ? Colors.blueGrey.shade700 // Adjusted colors
                            : Colors.grey.shade300,
                      ),
                      color: themeProvider.isDark()
                          ? Colors.grey.shade800
                          : Colors.white, // Background color
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Password Security'),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, ChangePasswordScreen.routeName);
                              },
                            ),
                          ],
                        ),
                        const Text(
                          'Change your password to keep your account secure',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24), // Increased spacing
            // Increased spacing

            if (isAdmin)
              // --- Target BSSID Setting (for Testing) ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Network',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.isDark()
                            ? Colors.blueGrey.shade700
                            : Colors.grey.shade300,
                      ),
                      color: themeProvider.isDark()
                          ? Colors.grey.shade800
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage allowed Wi-Fi BSSIDs (MAC Addresses). Leave empty to allow attendance from anywhere.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bssidController,
                          cursorColor: MyAppColors.primaryColor,
                          decoration: const InputDecoration(
                            labelText: 'Add MAC Address',
                            labelStyle:
                                TextStyle(color: MyAppColors.primaryColor),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: MyAppColors.primaryColor)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _resetAllMacAddresses(context),
                              child: const Text('Clear All',
                                  style: TextStyle(
                                      color: MyAppColors.primaryColor)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _addMacAddress(context),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: MyAppColors.primaryColor),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Add',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const Divider(),
                        if (macProvider.isLoading)
                          const Center(
                              child: CircularProgressIndicator(
                                  color: MyAppColors.primaryColor))
                        else if (macProvider.allowedMacs.isEmpty)
                          const Text('No MAC addresses configured.'),
                        ...macProvider.allowedMacs.map((mac) => ListTile(
                              title: Text(mac),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: _isProcessing
                                    ? null
                                    : () async {
                                        setState(() => _isProcessing = true);
                                        await macProvider.deleteMac(mac);
                                        setState(() => _isProcessing = false);
                                      },
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
