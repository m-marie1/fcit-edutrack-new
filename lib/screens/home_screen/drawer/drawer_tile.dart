import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  final String title;

  final IconData? icon;

  final void Function()? onTap;

  const MyDrawerTile(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: onTap,
      leading: Icon(icon, color: MyAppColors.primaryColor),
    );
  }
}
