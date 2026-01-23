import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_memo_app/main.dart';
import 'package:music_memo_app/widgets/recording_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicMemoApp());
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.byType(RecordingButton), findsOneWidget);
  });
}
