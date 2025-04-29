import 'package:fci_edutrack/auth/login_or_register_screen.dart';
import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

import '../modules/explain_page_item.dart';
import '../style/my_app_colors.dart';

class ExplainScreens extends StatefulWidget {
  static const String routeName = 'explain_screens';

  const ExplainScreens({super.key});

  @override
  State<ExplainScreens> createState() => _ExplainScreensState();
}

class _ExplainScreensState extends State<ExplainScreens> {
  final PageController _controller = PageController();
  int _currentPage = 0; // To track the active page

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(width * 0.011),
          child: Column(
            children: [
              // PageView Widget
              SizedBox(
                height: height * 0.6, // Set a specific height for PageView
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index; // Update current page
                    });
                  },
                  children: const [
                    ExplainPageItem(
                      imagePath: "assets/images/explain_logo1.png",
                      title: "نظرة عميقة على الميزات",
                      description:
                          "تصميم تطبيق الحضور البسيط لتسهيل و تبسيط عملية تتبع حضور الطلاب في المحاضرات الجامعية",
                    ),
                    ExplainPageItem(
                      imagePath: "assets/images/explain_logo2.png",
                      title: "فوائد التطبيق",
                      description:
                          "تسجيل الحضور السريع دون الحاجة لقوائم ورقية او تتبع الطلاب سيتم التعرف علي البيانات المفقودة",
                    ),
                    ExplainPageItem(
                      imagePath: "assets/images/explain_logo3.png",
                      title: "هيا بنا نبدأ",
                      description: "فلنبدأ في كيفية التعرف على تطبيقنا...",
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.02), // Add spacing
              // Buttons and indicators
              SizedBox(
                height: height * 0.3,
                // Add height to fit content without Expanded
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == 2) {
                          Navigator.pushReplacementNamed(
                              context, LoginOrRegisterScreen.routeName);
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyAppColors.primaryColor,
                        shape: const CircleBorder(),
                        minimumSize: Size(width * 0.11, height * 0.05),
                      ),
                      child: Icon(
                        Icons.arrow_right_alt,
                        size: MediaQuery.of(context).size.width * 0.08,
                        color: MyAppColors.whiteColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: height * 0.05, top: height * 0.01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: _currentPage == index
                                ? height * 0.004
                                : height * 0.003,
                            width: _currentPage == index
                                ? width * 0.08
                                : width * 0.05,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? MyAppColors.primaryColor
                                  : Colors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, LoginOrRegisterScreen.routeName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyAppColors.whiteColor,
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: MyAppColors.primaryColor,
                                width: width * 0.001,
                              ),
                              borderRadius:
                                  BorderRadius.circular(width * 0.02)),
                        ),
                        child: Text(
                          'skip',
                          style: MyThemeData
                              .lightModeStyle.textTheme.bodyMedium!
                              .copyWith(
                                  color: MyAppColors.primaryColor,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

