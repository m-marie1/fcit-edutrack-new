import 'package:fci_edutrack/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../modules/custom_text_formfield.dart';
import '../../style/my_app_colors.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  static const String routeName = 'reset_password';

  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _email;
  String? _code;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'];
      _code = args['code'];
    }
  }

  void updatePassword() async {
    if (_formKey.currentState?.validate() == true) {
      if (_email == null || _code == null) {
        setState(() {
          _errorMessage = "Missing required information. Please try again.";
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        _email!,
        _code!,
        _passwordController.text,
      );

      if (success) {
        if (!mounted) return;
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successful')),
        );
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else {
        setState(() {
          _errorMessage = "Failed to reset password. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text(
                'Reset Password',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Image.asset(
                'assets/images/reset_password_logo.png',
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.41,
              ),
              Text(
                'Set a New Password',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
              ),
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
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
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      CustomTextFormField(
                        label: 'New Password',
                        preIcon: Icons.vpn_key_outlined,
                        sufIcon: Icons.visibility_off_outlined,
                        controller: _passwordController,
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
                      CustomTextFormField(
                        label: 'Confirm Password',
                        preIcon: Icons.vpn_key_outlined,
                        sufIcon: Icons.visibility_off_outlined,
                        controller: _confirmPasswordController,
                        validator: (text) {
                          if (text == null || text.trim().isEmpty) {
                            return 'Please Enter Confirm Password';
                          }
                          if (text != _passwordController.text) {
                            return "The Confirm password doesn't match Password";
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      ElevatedButton(
                        onPressed: isLoading ? null : updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyAppColors.primaryColor,
                          padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.014,
                            horizontal:
                                MediaQuery.of(context).size.width * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.022,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLoading
                                  ? 'Resetting Password...'
                                  : 'Reset Password',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    color: MyAppColors.whiteColor,
                                  ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.007),
                            isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_reset),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
