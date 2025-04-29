import 'package:fci_edutrack/auth/register_screen.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/admin/admin_home_screen.dart'; // Added import
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart'; // Student Home
import 'package:fci_edutrack/screens/password/forget_password_screen.dart';
import 'package:fci_edutrack/screens/professor/professor_home_screen.dart'; // Added import
import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modules/custom_text_formfield.dart';
import '../style/my_app_colors.dart';
import '../themes/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = 'login_screen';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<LoginScreen> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameOrEmailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    bool isdDark = Provider.of<ThemeProvider>(context).isDark();
    bool isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor:
          isdDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_circle_left,
              color: MyAppColors.primaryColor,
              size: MediaQuery.of(context).size.height * 0.04,
            )),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هيا بنا نبدا',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: isdDark
                            ? MyAppColors.whiteColor
                            : MyAppColors.blackColor,
                      ),
                ),
                Text(
                  'قم بالتسجيل لحضور سريع دون الحاجة الي قوائم ورقية',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: MyAppColors.lightBlueColor),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.06,
                ),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                CustomTextFormField(
                  label: 'Username or Email',
                  preIcon: Icons.person_outline,
                  controller: usernameOrEmailController,
                  validator: (text) {
                    if (text == null || text.trim().isEmpty) {
                      return 'Please Enter Username or Email';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  label: 'Password',
                  preIcon: Icons.vpn_key_outlined,
                  sufIcon: Icons.visibility_off_outlined,
                  controller: passwordController,
                  validator: (text) {
                    if (text == null || text.trim().isEmpty) {
                      return 'Please Enter Password';
                    }
                    if (text.length < 6) {
                      return 'Password must be at least 6 chars.';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                        context, ForgetPassword.routeName);
                  },
                  child: const Text('forget password ?'),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: MyAppColors.primaryColor,
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.014,
                          horizontal: MediaQuery.of(context).size.width * 0.02),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.022))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLoading ? 'Logging in...' : 'Login',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: MyAppColors.whiteColor),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.007,
                      ),
                      isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.login),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    'or',
                    style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                        .copyWith(
                      color: MyAppColors.blackColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      width: MediaQuery.of(context).size.width * 0.05,
                      fit: BoxFit.fill,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.04,
                    ),
                    Image.asset(
                      'assets/images/facebook_logo.png',
                      width: MediaQuery.of(context).size.width * 0.05,
                      fit: BoxFit.fill,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                          .copyWith(
                        fontSize: 12,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, RegisterScreen.routeName);
                      },
                      child: Text(
                        ' Register',
                        style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                            .copyWith(
                          fontSize: 12,
                          color: MyAppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      print(
          "Login attempt with username/email: ${usernameOrEmailController.text}");

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        bool success = await authProvider.smartLogin(
          usernameOrEmailController.text.trim(),
          passwordController.text,
        );

        if (success) {
          print("Login successful, checking role...");
          // Get the role directly from the provider after successful login
          final userRole = authProvider.userRole?.toUpperCase();
          print("User role after login: $userRole");

          if (mounted) {
            // Navigate based on role
            String routeName;
            if (userRole == 'ADMIN') {
              routeName = AdminHomeScreen.routeName;
            } else if (userRole == 'PROFESSOR') {
              routeName = ProfessorHomeScreen.routeName;
            } else {
              // Default to Student
              routeName = MyBottomNavBar.routeName;
            }
            print("Navigating to route: $routeName");
            Navigator.of(context)
                .pushNamedAndRemoveUntil(routeName, (route) => false);
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Invalid username or password';
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'An error occurred: ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    }
  }
}
