import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../screen_3tab/page_control.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 앱 로고 및 소개 텍스트
              Column(
                children: [
                  // 이미지 추가
                  Image.asset(
                    'asset/img/link1.jpg', // 이미지 경로
                    height: 120, // 적절한 높이 설정
                    fit: BoxFit.contain, // 이미지 비율 유지
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login to continue",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              // Google 로그인 버튼
              getStyledButton(
                onTap: signInWithGoogle,
                backgroundColor: Colors.white,
                borderColor: Colors.grey.shade300,
                iconPath: 'asset/img/google.png',
                text: "Sign In with Google",
                textColor: Colors.grey.shade700,
              ),
              const SizedBox(height: 20),
              // Kakao 로그인 버튼
              getStyledButton(
                onTap: signInWithKakao,
                backgroundColor: Colors.yellow,
                borderColor: Colors.transparent,
                iconPath: 'asset/img/kakao.png',
                text: "Sign In with Kakao",
                textColor: Colors.black87,
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }

  // 공통 버튼 디자인 함수
  Widget getStyledButton({
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color borderColor,
    required String iconPath,
    required String text,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Google 로그인 함수
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print("Google sign-in was canceled by the user.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      navigateToHome();
    } catch (e) {
      print("Google 로그인 중 오류 발생: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google 로그인 중 오류가 발생했습니다: $e")),
      );
    }
  }

  // Kakao 로그인 함수
  Future<void> signInWithKakao() async {
    try {
      OAuthToken token;

      // KakaoTalk이 설치되어 있는 경우
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
        print("카카오톡으로 로그인 성공: ${token.accessToken}");
      } else {
        // Kakao 계정을 통한 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
        print("카카오 계정으로 로그인 성공: ${token.accessToken}");
      }

      navigateToHome();
    } catch (error) {
      print("카카오 로그인 실패: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kakao 로그인 중 오류가 발생했습니다: $error")),
      );
    }
  }

  // 홈 화면으로 이동
  void navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PageControl()),
    );
  }
}
