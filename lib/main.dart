import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_state.dart';
import 'providers/data_provider.dart';
import 'theme/handora_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/new_order_toast.dart';
import 'widgets/order_shipped_modal.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/growth_screen.dart';
import 'screens/help_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env). Missing or unreadable config must not
  // stop the app — it is offline-first, and SQLite works without the cloud.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Could not load .env: $e — continuing offline-only.');
  }

  // Initialize Supabase. A placeholder or malformed URL (e.g. an unedited
  // .env.example) throws here; catching it degrades to offline-only instead of
  // crashing on launch.
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (Uri.tryParse(supabaseUrl)?.isAbsolute == true &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // Supersedes the deprecated `anonKey`; the two are interchangeable, and
        // a legacy anon key is still a valid value here.
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase init failed: $e — continuing offline-only.');
    }
  } else {
    debugPrint('⚠️ SUPABASE_URL / SUPABASE_ANON_KEY not configured — offline-only.');
  }

  // Read saved language/theme before the first frame so the app opens in the
  // artisan's chosen language rather than flashing English/light first.
  final appState = await AppState.restore();

  runApp(HandoraApp(appState: appState));
}

class HandoraApp extends StatelessWidget {
  final AppState appState;

  const HandoraApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) {
          final dp = DataProvider();
          dp.init(); // seeds DB on first launch, loads data
          return dp;
        }),
      ],
      child: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return MaterialApp(
      title: 'Handora',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _Shell(),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = context.watch<DataProvider>();
    final s = app.strings;

    // Both overlays are driven by real orders held in DataProvider.
    final pending = data.pendingOrder;
    final accepted = data.lastAcceptedOrder;

    final tabIndex = switch (app.tab) {
      NavTab.home    => 0,
      NavTab.catalog => 1,
      NavTab.growth  => 2,
      NavTab.help    => 3,
    };

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            AppHeader(
              language: app.language,
              onLanguageChange: app.setLanguage,
            ),
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: const [
                  HomeScreen(),
                  CatalogScreen(),
                  GrowthScreen(),
                  HelpScreen(),
                ],
              ),
            ),
            BottomNav(active: app.tab, onChange: app.setTab, labels: s.nav),
          ]),

          // Overlays
          if (accepted != null)
            Positioned.fill(
              child: OrderShippedModal(
                visible: true,
                order: accepted,
                language: app.language,
                strings: s,
                onClose: data.dismissShipped,
              ),
            ),
          if (pending != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: NewOrderToast(
                visible: true,
                order: pending,
                language: app.language,
                strings: s,
                onAccept: data.acceptPendingOrder,
              ),
            ),
        ]),
      ),
    );
  }
}
