import 'package:fci_edutrack/auth/auth_wrapper.dart'; // Import AuthWrapper
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = 'splash_screen';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available
    // Navigate after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate unconditionally to AuthWrapper
        Navigator.of(context).pushReplacementNamed(AuthWrapper.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build method just shows the splash UI. Navigation is handled in initState.
    return Scaffold(
      backgroundColor: MyAppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.6,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: MyAppColors.primaryColor,
                borderRadius:
                    BorderRadius.circular(MediaQuery.of(context).size.width),
              ),
              child: Lottie.asset('assets/animation/welcome_animation.json'),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            Text(
              'Welcome To\n FCIT Edutrack',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: MyAppColors.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.07),
              textAlign: TextAlign.center,
            ),
            // Optional: Remove loading indicator if splash duration is fixed
            // const SizedBox(height: 20),
            // const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
