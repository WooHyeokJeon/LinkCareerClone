import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:team_project/screen_3tab/page_control.dart';
import 'package:team_project/const/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // colors.dart import
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:team_project/login_logic/splash.dart';
import 'package:team_project/const/navigationbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: 'ca95d72829a81916963ca8901b0719e8',
    javaScriptAppKey: 'bc444bc4bf1a89b175febf3567b79bb1',
  );

  await printKeyHash();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// 키 해시 출력 함수
Future<void> printKeyHash() async {
  try {
    final keyHash = await KakaoSdk.origin;
    print("현재 사용 중인 키 해시: $keyHash");
  } catch (e) {
    print("키 해시를 가져오는 중 오류 발생: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: bgColor, // 배경색 설정
        primaryColor: mainColor, // 기본 색상 설정
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: mainColor), // 텍스트 기본 색상
          bodyMedium: TextStyle(color: secondColor), // 보조 텍스트 색상
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: bgColor, // 하단 네비게이션 배경색
          selectedItemColor: mainColor, // 선택된 아이템 색상
          unselectedItemColor: secondColor, // 비선택 아이템 색상
        ),
      ),
      home: SplashScreen(), // SplashScreen으로 시작
    );
  }
}
