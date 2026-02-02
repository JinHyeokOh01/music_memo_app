import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/summary.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(SummaryAdapter());
  Hive.registerAdapter(SummaryTypeAdapter());

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
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
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

      // 브라운 우드 톤 테마 설정
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFDFCF8), // 밝은 웜 베이지 배경
        primaryColor: const Color(0xFF8D6E63), // 웜 브라운

        // 컬러 스킴
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8D6E63),
          secondary: Color(0xFFD7CCC8),
          surface: Color(0xFFF5F1E6), // 카드 배경 (약간 더 진한 베이지)
          onSurface: Color(0xFF4E342E), // 기본 텍스트
        ),

        // 앱바 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDFCF8),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF4E342E)),
          titleTextStyle: TextStyle(
            color: Color(0xFF4E342E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 텍스트 테마
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF4E342E), // 다크 브라운
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF4E342E),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF795548), // 미디엄 브라운
            fontSize: 14,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF4E342E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F1E6), // 입력란 배경 (Surface와 동일하거나 비슷하게)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: const Color(0xFF795548).withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // 아이콘 테마
        iconTheme: const IconThemeData(
          color: Color(0xFF795548),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
