import 'package:fci_edutrack/screens/help_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// Auth imports
import 'package:fci_edutrack/auth/login_or_register_screen.dart';
import 'package:fci_edutrack/auth/login_screen.dart';
import 'package:fci_edutrack/auth/register_screen.dart';
import 'package:fci_edutrack/auth/auth_wrapper.dart';
// Provider imports
import 'package:fci_edutrack/providers/attendance_provider.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/providers/assignment_provider.dart';
import 'package:fci_edutrack/providers/quiz_provider.dart';
// Theme imports
import 'package:fci_edutrack/themes/theme_provider.dart';
// Screen imports - Admin
import 'package:fci_edutrack/screens/admin/professor_requests_screen.dart';
import 'package:fci_edutrack/screens/admin/course_management_screen.dart';
import 'package:fci_edutrack/screens/admin/admin_home_screen.dart';
// Screen imports - Professor
import 'package:fci_edutrack/screens/professor/quiz_management_screen.dart';
import 'package:fci_edutrack/screens/professor/quiz_creation_screen.dart';
import 'package:fci_edutrack/screens/professor/professor_home_screen.dart';
import 'package:fci_edutrack/screens/professor/quiz_drafts_screen.dart';
// Screen imports - Student
import 'package:fci_edutrack/screens/student/student_quiz_list_screen.dart';
// Screen imports - General
import 'package:fci_edutrack/screens/assignment/assignment_details.dart';
import 'package:fci_edutrack/screens/assignment/assignment_screen.dart';
import 'package:fci_edutrack/screens/assignment/assignment_create_screen.dart';
import 'package:fci_edutrack/screens/assignment/assignment_submission_screen.dart';
import 'package:fci_edutrack/screens/assignment/assignment_submissions_screen.dart';
import 'package:fci_edutrack/screens/assignment/assignment_grading_screen.dart';
import 'package:fci_edutrack/screens/assignment/assignment_drafts_screen.dart';
import 'package:fci_edutrack/models/assignment_model.dart';
import 'package:fci_edutrack/screens/camera_permission_screen.dart';
import 'package:fci_edutrack/screens/explain_screens.dart';
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart';
import 'package:fci_edutrack/screens/home_screen/notifications_screen.dart';
import 'package:fci_edutrack/screens/password/forget_password_screen.dart';
import 'package:fci_edutrack/screens/password/pass_confirm_code_screen.dart';
import 'package:fci_edutrack/screens/password/reset_password_screen.dart';
import 'package:fci_edutrack/screens/password/change_password_screen.dart';
import 'package:fci_edutrack/screens/professor_request_screen.dart';
import 'package:fci_edutrack/screens/register_attendance.dart';
import 'package:fci_edutrack/screens/settings_screen.dart';
import 'package:fci_edutrack/screens/attendance_history_screen.dart';

Future<void> main() async {
  // Make main async
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(
          create:
              (context) =>
                  AuthProvider()..initialize(), // Initialize AuthProvider here
        ),
        ChangeNotifierProvider(create: (context) => CourseProvider()),
        ChangeNotifierProvider(create: (context) => AssignmentProvider()),
        ChangeNotifierProvider(create: (context) => AttendanceProvider()),
        // QuizProvider needs CourseProvider for fetching student quizzes
        ChangeNotifierProxyProvider<CourseProvider, QuizProvider>(
          create: (context) => QuizProvider(), // Initial creation
          update: (context, courseProvider, previousQuizProvider) {
            // Update QuizProvider with the latest CourseProvider instance
            previousQuizProvider?.updateCourseProvider(courseProvider);
            return previousQuizProvider ??
                QuizProvider(); // Return existing or new instance
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // Changed to StatelessWidget
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "EduTrack",
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).appTheme,
      initialRoute: AuthWrapper.routeName, // Start with AuthWrapper
      routes: {
        // Auth routes
        AuthWrapper.routeName: (context) => const AuthWrapper(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        LoginOrRegisterScreen.routeName:
            (context) => const LoginOrRegisterScreen(),

        // Password management routes
        ForgetPassword.routeName: (context) => const ForgetPassword(),
        PasswordConfirmationCode.routeName:
            (context) => const PasswordConfirmationCode(),
        ResetPasswordScreen.routeName: (context) => const ResetPasswordScreen(),
        ChangePasswordScreen.routeName:
            (context) => const ChangePasswordScreen(),

        // Main navigation routes
        MyBottomNavBar.routeName: (context) => const MyBottomNavBar(),
        NotificationsScreen.routeName: (context) => const NotificationsScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),

        // Attendance routes
        RegisterAttendanceScreen.routeName:
            (context) => const RegisterAttendanceScreen(),
        CameraPermissionScreen.routeName:
            (context) => const CameraPermissionScreen(),
        'attendance_history': (context) => const AttendanceHistoryScreen(),

        // Assignment routes
        AssignmentScreen.routeName: (context) => const AssignmentScreen(),
        AssignmentDetails.routeName: (context) => const AssignmentDetails(),
        AssignmentCreateScreen.routeName:
            (context) => const AssignmentCreateScreen(),
        AssignmentDraftsScreen.routeName:
            (context) => const AssignmentDraftsScreen(),
        AssignmentSubmissionScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is Assignment) {
            return AssignmentSubmissionScreen(assignment: arguments);
          } else if (arguments is Map<String, dynamic>) {
            return AssignmentSubmissionScreen(
              assignment: arguments['assignment'],
              existingSubmission: arguments['existingSubmission'],
            );
          } else {
            return AssignmentSubmissionScreen(
              assignment: Assignment(
                id: 0,
                title: 'Error',
                description: 'Invalid arguments',
                dueDate: '',
                maxPoints: 0,
              ),
            );
          }
        },
        AssignmentSubmissionsScreen.routeName:
            (context) => AssignmentSubmissionsScreen(
              assignmentId: ModalRoute.of(context)!.settings.arguments as int,
            ),
        AssignmentGradingScreen.routeName:
            (context) => AssignmentGradingScreen(
              submission:
                  ModalRoute.of(context)!.settings.arguments
                      as AssignmentSubmission,
            ),

        // Professor routes
        ProfessorRequestScreen.routeName:
            (context) => const ProfessorRequestScreen(),
        ProfessorHomeScreen.routeName: (context) => const ProfessorHomeScreen(),

        // Admin routes
        AdminHomeScreen.routeName: (context) => const AdminHomeScreen(),
        ProfessorRequestsScreen.routeName:
            (context) => const ProfessorRequestsScreen(),
        CourseManagementScreen.routeName:
            (context) => const CourseManagementScreen(),

        // Quiz routes
        QuizManagementScreen.routeName:
            (context) => const QuizManagementScreen(),
        QuizCreationScreen.routeName: (context) => const QuizCreationScreen(),
        QuizDraftsScreen.routeName: (context) => const QuizDraftsScreen(),
        StudentQuizListScreen.routeName:
            (context) => const StudentQuizListScreen(),

        // Misc routes
        ExplainScreens.routeName: (context) => const ExplainScreens(),
        HelpAndSupport.routeName: (context) => const HelpAndSupport(),
      },
    );
  }
}

// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
