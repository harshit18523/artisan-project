import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:handora/main.dart';
import 'package:handora/providers/app_state.dart';
import 'package:handora/services/database_helper.dart';
import 'package:path/path.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Test files run in parallel isolates; each needs its own database file.
    DatabaseHelper.databaseName = 'handora_widget_test.db';
    await DatabaseHelper.instance.resetForTests();
    await databaseFactory
        .deleteDatabase(join(await getDatabasesPath(), DatabaseHelper.databaseName));
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://mock.supabase.co
SUPABASE_ANON_KEY=mock-key
GEMINI_API_KEY=mock-gemini-key
''');
  });

  testWidgets('App renders without errors', (tester) async {
    await tester.pumpWidget(HandoraApp(appState: AppState()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Hand'), findsWidgets);
  });
}
