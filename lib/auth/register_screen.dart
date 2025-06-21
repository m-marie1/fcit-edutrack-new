import 'package:fci_edutrack/auth/login_screen.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/password/pass_confirm_code_screen.dart';
import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modules/custom_text_formfield.dart';
import '../style/my_app_colors.dart';
import '../themes/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = 'register_screen';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    bool isdDark = Provider.of<ThemeProvider>(context).isDark();
    bool isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
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
                  "Let's get started",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: isdDark
                            ? MyAppColors.whiteColor
                            : MyAppColors.blackColor,
                      ),
                ),
                Text(
                  'Register attendance quickly without paper forms',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: MyAppColors.primaryColor),
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
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                CustomTextFormField(
                  label: 'Full Name',
                  preIcon: Icons.person_outline,
                  controller: fullNameController,
                  validator: (text) {
                    if (text == null || text.trim().isEmpty) {
                      return 'Please Enter Full Name';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  label: 'Username',
                  preIcon: Icons.account_circle_outlined,
                  controller: usernameController,
                  validator: (text) {
                    if (text == null || text.trim().isEmpty) {
                      return 'Please Enter Username';
                    }
                    if (text.contains(' ')) {
                      return 'Username cannot contain spaces';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  label: 'Email',
                  preIcon: Icons.email_outlined,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (text) {
                    if (text == null || text.trim().isEmpty) {
                      return 'Please Enter Email';
                    }
                    final bool emailValid = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(text);
                    if (!emailValid) {
                      return 'Please Enter Valid Email';
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : register,
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
                        isLoading ? 'Registering...' : 'Register',
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
                          : const Icon(Icons.app_registration),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                          .copyWith(
                        fontSize: 12,
                        color:isdDark?MyAppColors.whiteColor:MyAppColors.blackColor
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, LoginScreen.routeName);
                      },
                      child: Text(
                        ' Login',
                        style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                            .copyWith(
                          fontSize: 12,
                          color: MyAppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Professor account request row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Need a professor account?",
                      style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                          .copyWith(
                        fontSize: 12,
                        color: isdDark?MyAppColors.whiteColor:MyAppColors.blackColor
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                            context, 'professor_request_screen');
                      },
                      child: Text(
                        ' Request access',
                        style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                            .copyWith(
                          fontSize: 12,
                          color: MyAppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void register() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (_formKey.currentState?.validate() == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.register(
        usernameController.text.trim(),
        passwordController.text,
        fullNameController.text.trim(),
        emailController.text.trim(),
      );

      if (response['success']) {
        setState(() {
          _successMessage =
              "Registration successful! Please check your email for verification code.";
        });

        if (!mounted) return;
        // Navigate to email verification screen
        Navigator.pushNamed(
          context,
          PasswordConfirmationCode.routeName,
          arguments: {
            'email': emailController.text.trim(),
            'isForVerification': true,
          },
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? "Registration failed. Please try again.";
        });
      }
    }
  }
}
