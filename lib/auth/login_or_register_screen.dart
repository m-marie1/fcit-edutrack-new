import 'package:fci_edutrack/auth/login_screen.dart';
import 'package:fci_edutrack/auth/register_screen.dart';
import 'package:flutter/material.dart';

import '../style/my_app_colors.dart';

class LoginOrRegisterScreen extends StatelessWidget {
  static const String routeName = 'login_or_register';

  const LoginOrRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.04,
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                'assets/images/login_logo.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            Expanded(
                child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, LoginScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width * 0.56,
                          MediaQuery.of(context).size.height * 0.06),
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
                        'Login',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: MyAppColors.whiteColor),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.007,
                      ),
                      const Icon(Icons.login),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RegisterScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width * 0.56,
                          MediaQuery.of(context).size.height * 0.06),
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
                        'Create Account',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: MyAppColors.whiteColor),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.007,
                      ),
                      const Icon(Icons.add_card_outlined),
                    ],
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
