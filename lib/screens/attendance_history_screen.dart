import 'package:fci_edutrack/models/attendance_model.dart';
import 'package:fci_edutrack/providers/attendance_provider.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  static const String routeName = 'attendance_history';

  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  Map<int, List<Attendance>> courseAttendance = {};
  Map<int, bool> expandedCourses = {};
  bool isLoading = false;

  // Store total classes for each course
  final Map<int, int> _totalClassesCache = {};

  // Fetch and cache total classes for a course
  Future<void> _fetchTotalClasses(int courseId) async {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    if (!_totalClassesCache.containsKey(courseId)) {
      await attendanceProvider.fetchTotalClassesForCourse(courseId);
      final total = attendanceProvider.totalClassesByCourse[courseId];
      if (total != null) {
        setState(() {
          _totalClassesCache[courseId] = total;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Load attendance history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        isLoading = true;
      });

      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);

      // Clear any previous attendance records
      attendanceProvider.clearAttendanceRecords();

      // Make sure we're fetching enrolled courses, not current courses
      await courseProvider.fetchEnrolledCourses();

      if (courseProvider.enrolledCourses.isNotEmpty) {
        for (var course in courseProvider.enrolledCourses) {
          // Pass empty string as userId since we're using the current user endpoint now
          await attendanceProvider.fetchUserAttendance("", course.id);

          // Initialize all courses as collapsed
          expandedCourses[course.id] = false;
        }
      } else {
        print("No enrolled courses found");
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  // Calculate attendance percentage for a course
  double calculateAttendancePercentage(int courseId) {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final attendanceRecords =
        attendanceProvider.getAttendanceForCourse(courseId);
    final totalClasses = _totalClassesCache[courseId] ?? 0;

    if (totalClasses == 0) return 0.0; // Avoid division by zero

    final attendedClasses = attendanceRecords.length;
    return (attendedClasses / totalClasses) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();
    final courseProvider = Provider.of<CourseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
       appBar: AppBar(
        elevation: 0,
        title: Text(
          'My Attendance History',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: MyAppColors.whiteColor
          )
        ),
        iconTheme: IconThemeData(
          color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
        ),
         centerTitle: true,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.only(
             bottomLeft:
             Radius.circular(MediaQuery.of(context).size.width * 0.1),
             bottomRight:
             Radius.circular(MediaQuery.of(context).size.width * 0.1),
           ),
         ),
         backgroundColor: MyAppColors.primaryColor,
         leading: IconButton(
           onPressed: () {
             Navigator.pop(context);
           },
           icon: const Icon(Icons.arrow_back_ios, color: MyAppColors.whiteColor,),
         ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Records',
              style:Theme.of(context).textTheme.titleMedium!.copyWith(
                color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
              )
            ),
            const SizedBox(height: 8),
            Text(
              'Your attendance for all enrolled courses',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // List of courses with attendance percentage
            Expanded(
              child: isLoading || courseProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(
                color: MyAppColors.primaryColor,
              ))
                  : courseProvider.enrolledCourses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'You are not enrolled in any courses yet',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: courseProvider.enrolledCourses.length,
                          itemBuilder: (context, index) {
                            final course =
                                courseProvider.enrolledCourses[index];
                            final attendancePercentage =
                                calculateAttendancePercentage(course.id);
                            final isExpanded =
                                expandedCourses[course.id] ?? false;
                            final attendanceRecords = attendanceProvider
                                .getAttendanceForCourse(course.id);
                            // Fetch total classes if not already cached
                            _fetchTotalClasses(course.id);
                            final totalClasses =
                                _totalClassesCache[course.id] ?? 0;
                            // Find the most recent attendance date
                            String lastAttended = 'Never';
                            if (attendanceRecords.isNotEmpty) {
                              final latest = attendanceRecords
                                  .map((r) =>
                                      DateTime.parse(r.timestamp).toUtc())
                                  .reduce((a, b) => a.isAfter(b) ? a : b)
                                  .toLocal();
                              lastAttended = DateFormat('MMM d').format(latest);
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: isDark
                                  ? MyAppColors.secondaryDarkColor
                                  : MyAppColors.whiteColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          expandedCourses[course.id] =
                                              !isExpanded;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.courseName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  course.courseCode,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: attendancePercentage >= 75
                                                  ? Colors.green
                                                      .withOpacity(0.15)
                                                  : attendancePercentage >= 50
                                                      ? Colors.orange
                                                          .withOpacity(0.15)
                                                      : Colors.red
                                                          .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${attendancePercentage.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: attendancePercentage >=
                                                        75
                                                    ? Colors.green
                                                    : attendancePercentage >= 50
                                                        ? Colors.orange
                                                        : Colors.red,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildAttendanceInfoItem(
                                            'Attended',
                                            '${attendanceRecords.length}',
                                            Icons.check_circle_outline,
                                            Colors.green,
                                            isDark),
                                        _buildAttendanceInfoItem(
                                            'Total Classes',
                                            '$totalClasses',
                                            Icons.calendar_today,
                                            Colors.blue,
                                            isDark),
                                        _buildAttendanceInfoItem(
                                            'Last Attended',
                                            lastAttended,
                                            Icons.access_time,
                                            Colors.blue,
                                            isDark),
                                      ],
                                    ),

                                    // Expanded attendance details
                                    if (isExpanded) ...[
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Attendance Details',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (attendanceRecords.isEmpty)
                                        Text(
                                          'No attendance records found',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      else
                                        ...attendanceRecords.map((record) {
                                          final recordDate =
                                              DateTime.parse(record.timestamp)
                                                  .toUtc()
                                                  .toLocal();
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  DateFormat(
                                                          'EEEE, MMMM d, yyyy - HH:mm')
                                                      .format(recordDate),
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceInfoItem(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10,),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
