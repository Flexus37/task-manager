import 'dart:async';

import 'package:flutter/material.dart';

import '../styles/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  List<Color> _gradientColors = AppStyles.gradientColors1; // Начальный градиент
  bool _toggle = true;

  @override
  void initState() {
    super.initState();
    _startGradientAnimation();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startGradientAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _gradientColors =
            _toggle ? AppStyles.gradientColors2 : AppStyles.gradientColors1;
        _toggle = !_toggle;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Agile-доска',
                style: AppStyles.homeTitleStyle,
                textAlign: TextAlign.center,
              ),
              AppStyles.verticalSpacingLarge,
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: AppStyles.startButtonStyle,
                child: const Text(
                  'Начать',
                  style: AppStyles.buttonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
