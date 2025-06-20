import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../providers/auth_provider.dart';
import '../style/my_app_colors.dart';
import '../themes/my_theme_data.dart';
import '../themes/theme_provider.dart';
import 'password/change_password_screen.dart';

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
  bool _isLoadingBSSID = true;
  bool _isSavingBSSID = false;
  static const String _defaultBSSID = ''; // Default value
  String _targetBSSID = '';

  @override
  void initState() {
    super.initState();
    _loadTargetBSSID();
  }

  @override
  void dispose() {
    _bssidController.dispose(); // Dispose controller
    super.dispose();
  }

  Future<void> _loadTargetBSSID() async {
    setState(() => _isLoadingBSSID = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customBSSID = prefs.getString('custom_target_bssid');

      setState(() {
        _bssidController.text = customBSSID ?? _defaultBSSID;
        _targetBSSID = customBSSID ?? _defaultBSSID; // ✅ مهم للتأكيد
      });
    } catch (e) {
      print("Error loading target BSSID: $e");
      setState(() {
        _bssidController.text = _defaultBSSID;
        _targetBSSID = _defaultBSSID; // ✅ fallback
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load custom BSSID setting.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBSSID = false);
      }
    }
  }

  Future<void> _saveTargetBSSID() async {
    if (_isSavingBSSID) return; // Prevent double saving
    setState(() => _isSavingBSSID = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final newBssid = _bssidController.text.trim();
      // Basic validation (optional, could add MAC address format check)
      if (newBssid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Target BSSID cannot be empty.'),
              backgroundColor: Colors.red),
        );
        setState(() => _isSavingBSSID = false);
        return;
      }
      await prefs.setString('custom_target_bssid', newBssid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Target BSSID saved successfully.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error saving target BSSID: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving BSSID: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBSSID = false);
      }
    }
  }

  Future<void> _resetTargetBSSID() async {
    if (_isSavingBSSID) return;
    setState(() => _isSavingBSSID = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_target_bssid'); // Remove the custom setting
      _bssidController.text = _defaultBSSID; // Reset controller to default
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Target BSSID reset to default.'),
              backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      print("Error resetting target BSSID: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error resetting BSSID: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBSSID = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read role directly from provider inside build
    final authProvider = Provider.of<AuthProvider>(context);
    // Use getters from AuthProvider which now correctly compare roles
    final bool isAdmin = authProvider.currentUser?.role?.toUpperCase() ==
        'ADMIN'; // Use normalized role
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get theme provider instance
    return Scaffold(
      appBar: (isAdmin)?
      null
          :AppBar(
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
          icon: const Icon(Icons.arrow_back_ios, color: MyAppColors.whiteColor,),
        ),
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView for smaller screens
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align titles left
          children: [
            // --- Theme Settings ---
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
            )),
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
                    ? MyAppColors.secondaryDarkColor
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
            const SizedBox(height: 24,),
            if(!isAdmin)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Password Settings ---
                  Text('Security', style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: themeProvider.isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                  )),
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
                          ? MyAppColors.secondaryDarkColor
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

           if(isAdmin)
             // --- Target BSSID Setting (for Testing) ---
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Attendance Network',
                     style: Theme.of(context).textTheme.titleMedium!.copyWith(
                       color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                     )),
                 const SizedBox(height: 8),
                 Container(
                   padding: EdgeInsets.all(
                       MediaQuery.of(context).size.width * 0.05), // Adjusted padding
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(
                       color: themeProvider.isDark()
                           ? Colors.blueGrey.shade700
                           : Colors.grey.shade300,
                     ),
                     color: themeProvider.isDark()
                         ? MyAppColors.secondaryDarkColor
                         : Colors.white,
                   ),
                   child: _isLoadingBSSID
                       ? const Center(child: CircularProgressIndicator(
                     color: MyAppColors.primaryColor,
                   ))
                       : Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Enter the target Wi-Fi BSSID (MAC Address) for attendance verification. Use uppercase letters.',
                         style: TextStyle(fontSize: 12, color: Colors.grey),
                       ),
                       const SizedBox(height: 12),
                       TextFormField(
                         cursorColor: MyAppColors.primaryColor,
                         controller: _bssidController,
                         enabled: !_isSavingBSSID, // Disable while saving
                         decoration: InputDecoration(
                             labelText: 'Target BSSID',
                             labelStyle: const TextStyle(
                               color: MyAppColors.primaryColor
                             ),
                             hintText: _defaultBSSID, // Show default as hint
                             focusedBorder: const OutlineInputBorder(
                               borderSide: BorderSide(
                                 color: MyAppColors.primaryColor
                               )
                             ),
                             suffixIcon: IconButton(
                               // Add clear button
                               icon: const Icon(Icons.clear,color: MyAppColors.primaryColor,),
                               onPressed: _isSavingBSSID
                                   ? null
                                   : () => _bssidController.clear(),
                             )),
                         textCapitalization: TextCapitalization.characters,
                         // Optional: Add validation for MAC address format
                       ),
                       const SizedBox(height: 12),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           TextButton(
                             onPressed:
                             _isSavingBSSID ? null : _resetTargetBSSID,
                             child: const Text('Reset to Default',style: TextStyle(
                               color: MyAppColors.primaryColor
                             ),),
                           ),
                           const SizedBox(width: 8),
                           ElevatedButton(
                             onPressed:
                             _isSavingBSSID ? null : _saveTargetBSSID,
                             style: ElevatedButton.styleFrom(
                                 backgroundColor: MyAppColors.primaryColor),
                             child: _isSavingBSSID
                                 ? const SizedBox(
                               width: 16,
                               height: 16,
                               child: CircularProgressIndicator(
                                   strokeWidth: 2, color: Colors.white),
                             )
                                 : const Text('Save BSSID',
                                 style: TextStyle(color: Colors.white)),
                           ),
                         ],
                       ),
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
