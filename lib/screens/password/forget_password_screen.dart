import 'package:fci_edutrack/modules/custom_text_formfield.dart';
import 'package:fci_edutrack/screens/password/pass_confirm_code_screen.dart';
import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../style/my_app_colors.dart';

class ForgetPassword extends StatefulWidget {
  static const String routeName = 'forget_password';

  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success =
          await authProvider.forgotPassword(emailController.text.trim());

      if (success) {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          PasswordConfirmationCode.routeName,
          arguments: {
            'email': emailController.text.trim(),
            'isForVerification': false,
          },
        );
      } else {
        setState(() {
          _errorMessage = "Failed to send reset code. Please try again.";
        });
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.013),
            child: Column(
              children: [
                Text(
                  'Forgot Password',
                  style: MyThemeData.lightModeStyle.textTheme.bodyMedium,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Image.asset(
                  'assets/images/forget_password_photo.png',
                  width: MediaQuery.of(context).size.width * 0.82,
                  height: MediaQuery.of(context).size.height * 0.37,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
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
                  label: 'Enter Your Email',
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyAppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.014,
                      horizontal: MediaQuery.of(context).size.width * 0.02,
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
                      const Icon(Icons.lock_outline),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.007),
                      Text(
                        _isProcessing
                            ? 'Sending Reset Code...'
                            : 'Reset Password',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: MyAppColors.whiteColor),
                      ),
                      if (_isProcessing) ...[
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
