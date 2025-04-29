import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef Validator = String? Function(String?);

class CustomTextFormField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData preIcon;
  final IconData? sufIcon;
  final Validator validator;
  final bool obscureText;

  const CustomTextFormField({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.validator,
    required this.preIcon,
    this.sufIcon,
    this.obscureText = false,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _passwordVisible;

  @override
  void initState() {
    super.initState();
    _passwordVisible = !widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.01),
      child: TextFormField(
        decoration: InputDecoration(
          label:
              Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
          border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: MyAppColors.primaryColor,
              ),
              borderRadius: BorderRadius.all(
                  Radius.circular(MediaQuery.of(context).size.width * 0.022))),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: MyAppColors.primaryColor,
              ),
              borderRadius: BorderRadius.all(
                  Radius.circular(MediaQuery.of(context).size.width * 0.022))),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: MyAppColors.primaryColor,
              ),
              borderRadius: BorderRadius.all(
                  Radius.circular(MediaQuery.of(context).size.width * 0.04))),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.022),
              borderSide: const BorderSide(color: MyAppColors.redColor)),
          prefixIcon: Icon(
            widget.preIcon,
            color: Provider.of<ThemeProvider>(context).isDark()
                ? MyAppColors.lightBlueColor
                : MyAppColors.blackColor,
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off_outlined,
                  ),
                  color: Provider.of<ThemeProvider>(context).isDark()
                      ? MyAppColors.lightBlueColor
                      : MyAppColors.blackColor,
                )
              : widget.sufIcon != null
                  ? IconButton(
                      onPressed: () {},
                      icon: Icon(widget.sufIcon),
                      color: Provider.of<ThemeProvider>(context).isDark()
                          ? MyAppColors.lightBlueColor
                          : MyAppColors.blackColor,
                    )
                  : null,
        ),
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        obscureText: widget.obscureText && !_passwordVisible,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
