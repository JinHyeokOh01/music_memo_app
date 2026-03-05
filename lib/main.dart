import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      title: 'Musician Notes',
      debugShowCheckedModeBanner: false,

      // 다크 모드 미니멀리스트 테마 (V3)
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // 딥 차콜 그레이 배경
        primaryColor: const Color(0xFF800020), // 딥 버건디 (마이크 등 주요 액센트)
        canvasColor: const Color(0xFF1A1A1A),

        // 컬러 스킴
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF800020), // 딥 버건디
          secondary: Color(0xFFC5A059), // 뮤트 골드 (펜 가디언 등 서브 액센트)
          surface: Color(0xFF242424), // 카드 배경 (오프 블랙)
          onSurface: Colors.white, // 순백색 텍스트
          onPrimary: Colors.white,
        ),

        // 앱바 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: false,
          titleSpacing: 24,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),

        // 텍스트 테마 (Inter + NotoSansKR)
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.notoSansKr(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.notoSansKr(
            color: const Color(0xFFE0E0E0), // 약간 부드러운 화이트
            fontSize: 14,
            height: 1.5,
          ),
        ),

        // 입력 필드 테마 (검색바 등)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A), // 검색창 배경 등
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFC5A059), width: 1.5), // 포커스 시 골드
          ),
          hintStyle: GoogleFonts.notoSansKr(
            color: const Color(0xFF888888),
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),

        // 아이콘 테마
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        
        // 카드 테마
        cardTheme: CardTheme(
          color: const Color(0xFF242424),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),
        
        // 버튼 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF800020),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
