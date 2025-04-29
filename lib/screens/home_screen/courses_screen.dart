import 'package:fci_edutrack/models/course_model.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch courses when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
      Provider.of<CourseProvider>(context, listen: false)
          .fetchEnrolledCourses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Courses',
          style: TextStyle(
            color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MyAppColors.primaryColor,
          labelColor: MyAppColors.primaryColor,
          unselectedLabelColor:
              isDark ? MyAppColors.lightBlueColor : Colors.grey,
          tabs: const [
            Tab(text: 'All Courses'),
            Tab(text: 'My Courses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Courses Tab
          courseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCoursesList(courseProvider.courses, true),

          // My Courses Tab
          courseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCoursesList(courseProvider.enrolledCourses, false),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                // Refresh the courses list
                Provider.of<CourseProvider>(context, listen: false)
                    .fetchCourses();
              },
              backgroundColor: MyAppColors.primaryColor,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _buildCoursesList(List<Course> courses, bool showEnrollButton) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();

    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showEnrollButton
                  ? Icons.school_outlined
                  : Icons.bookmarks_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              showEnrollButton
                  ? 'No courses available at the moment'
                  : 'You are not enrolled in any courses yet',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: isDark ? MyAppColors.darkCardColor : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              course.courseName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Code: ${course.courseCode}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time: ${course.startTime} - ${course.endTime}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Days: ${course.days.join(', ')}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showEnrollButton) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _enrollInCourse(course),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyAppColors.primaryColor,
                      foregroundColor: MyAppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    child: const Text('Enroll'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _enrollInCourse(Course course) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Enrolling...'),
          ],
        ),
      ),
    );

    try {
      final response = await courseProvider.enrollInCourse(course.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response['success']) {
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(
                  'You have successfully enrolled in ${course.courseName}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Switch to My Courses tab
                    _tabController.animateTo(1);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content:
                  Text(response['message'] ?? 'Failed to enroll in course'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('An error occurred. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
