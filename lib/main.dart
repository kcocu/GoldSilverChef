import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_state.dart';
import 'services/data_loader.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GoldSilverChefApp());
}

class GoldSilverChefApp extends StatelessWidget {
  const GoldSilverChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'GoldSilver 요리사',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D4037),
            primary: const Color(0xFF5D4037),
          ),
          useMaterial3: true,
        ),
        home: const _LoadingWrapper(),
      ),
    );
  }
}

class _LoadingWrapper extends StatefulWidget {
  const _LoadingWrapper();

  @override
  State<_LoadingWrapper> createState() => _LoadingWrapperState();
}

class _LoadingWrapperState extends State<_LoadingWrapper> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final state = context.read<GameState>();
      await DataLoader.loadAll(state.engine);
      await state.recipeBook.load();
      state.markLoaded();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🍳', style: TextStyle(fontSize: 60)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFFE65100)),
              SizedBox(height: 16),
              Text('10,000가지 레시피 로딩중...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('오류: $_error')),
      );
    }

    return const HomeScreen();
  }
}
