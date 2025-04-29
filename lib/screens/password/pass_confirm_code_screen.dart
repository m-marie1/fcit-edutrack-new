import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart';
import 'package:fci_edutrack/screens/password/reset_password_screen.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../themes/theme_provider.dart';

class PasswordConfirmationCode extends StatefulWidget {
  static const String routeName = 'passConfirmCodeScreen';

  const PasswordConfirmationCode({super.key});

  @override
  State<PasswordConfirmationCode> createState() =>
      _PasswordConfirmationCodeState();
}

class _PasswordConfirmationCodeState extends State<PasswordConfirmationCode> {
  TextEditingController controller = TextEditingController();
  String? _email;
  bool _isForVerification = false;
  String? _errorMessage;
  bool _isResendEnabled = true;
  int _remainingSeconds = 0;
  Timer? _resendTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'];
      _isForVerification = args['isForVerification'] ?? false;
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<ThemeProvider>(context).isDark();
    bool isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor:
          isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
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
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03),
          child: Column(
            children: [
              Text(
                _isForVerification ? 'Email Verification' : 'Password Reset',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: isDark
                          ? MyAppColors.whiteColor
                          : MyAppColors.blackColor,
                    ),
              ),
              Text(
                _isForVerification
                    ? 'Enter the verification code sent to your email'
                    : 'Enter the code sent to your email to reset your password',
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
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: TextStyle(
                  color:
                      isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  labelStyle: TextStyle(
                    color: isDark
                        ? MyAppColors.lightBlueColor
                        : MyAppColors.blackColor,
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? MyAppColors.lightBlueColor
                          : MyAppColors.blackColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: MyAppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isResendEnabled ? _resendCode : null,
                child: Text(
                  _isResendEnabled
                      ? 'Resend Code'
                      : 'Wait $_remainingSeconds seconds to resend',
                  style: TextStyle(
                    color: _isResendEnabled
                        ? MyAppColors.primaryColor
                        : MyAppColors.greyColor,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.03,
              ),
              ElevatedButton(
                onPressed: isLoading ? null : verifyCode,
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
                    Text(
                      isLoading ? 'Verifying...' : 'Verify Code',
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
                        : const Icon(Icons.verified_user),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void verifyCode() async {
    setState(() {
      _errorMessage = null;
    });

    if (_email == null) {
      setState(() {
        _errorMessage = "Email is missing. Please go back and try again.";
      });
      return;
    }

    if (controller.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the verification code.";
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isForVerification) {
      // Handle email verification
      final success =
          await authProvider.verifyEmail(_email!, controller.text.trim());

      if (success) {
        if (!mounted) return;
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, MyBottomNavBar.routeName);
      } else {
        setState(() {
          _errorMessage = "Invalid verification code. Please try again.";
        });
      }
    } else {
      // Handle password reset code verification
      final success = await authProvider.verifyPasswordResetCode(
          _email!, controller.text.trim());

      if (success) {
        if (!mounted) return;
        // Only navigate to reset password screen if code is valid
        Navigator.pushReplacementNamed(
          context,
          ResetPasswordScreen.routeName,
          arguments: {
            'email': _email,
            'code': controller.text.trim(),
          },
        );
      } else {
        setState(() {
          _errorMessage = "Invalid reset code. Please try again.";
        });
      }
    }
  }

  void _startResendTimer() {
    _isResendEnabled = false;
    _remainingSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendCode() async {
    if (_email == null) {
      setState(() {
        _errorMessage = "Email is missing. Please go back and try again.";
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = _isForVerification
        ? await authProvider.resendVerificationCode(_email!)
        : await authProvider.resendPasswordResetCode(_email!);

    setState(() {
      if (result['success']) {
        _errorMessage = null;
        _startResendTimer();
      } else {
        _errorMessage = result['message'];
      }
    });
  }
}
