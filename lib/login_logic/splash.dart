import 'package:flutter/material.dart';
import 'package:team_project/screen_3tab/page_control.dart';
import 'package:team_project/login_logic/login.dart';
import 'package:team_project/const/navigationbar.dart';

import '../screen_3tab/contests.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLogin = false; // 로그인 상태

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Splash 화면을 2초 동안 표시
    await Future.delayed(const Duration(seconds: 2));

    // 로그인 상태에 따라 화면 전환
    if (_isLogin) {
      // PageControl로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PageControl()),
      );
    } else {
      // Login 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // 스플래시 로딩 애니메이션
      ),
    );
  }
}