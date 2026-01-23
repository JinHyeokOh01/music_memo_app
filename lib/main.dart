import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 포맷 초기화
  try {
    await initializeDateFormatting('ko', null);
  } catch (e) {
    // 초기화 실패해도 앱은 계속 실행
    debugPrint('날짜 포맷 초기화 실패: $e');
  }

  // 상태바 스타일 (라이트 텍스트 - 다크모드용)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MusicMemoApp());
}

/// 🎵 Music Memo App
/// 음악가를 위한 녹음 정리 앱
class MusicMemoApp extends StatelessWidget {
  const MusicMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Memo',
      debugShowCheckedModeBanner: false,

      // 다크 테마 설정
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF30D158), // Apple 그린

        // 컬러 스킴
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF30D158),
          secondary: Color(0xFF30D158),
          surface: Color(0xFF1C1C1E),
        ),

        // 앱바 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),

        // 텍스트 테마
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
