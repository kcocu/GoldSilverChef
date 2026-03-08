import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'cooking_screen.dart';
import 'recipe_book_screen.dart';
import 'story_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.playMenuBgm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🍳',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GoldSilver 요리사',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '10,000가지 요리의 세계',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _MenuButton(
                    icon: Icons.auto_stories,
                    label: '스토리 모드',
                    color: const Color(0xFFE65100),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryModeScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.restaurant,
                    label: '자유 경연',
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CookingScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.shuffle,
                    label: '랜덤 모드',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CookingScreen(isRandom: true)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.menu_book,
                    label: '레시피북',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecipeBookScreen()),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 사운드 토글
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          AudioService.instance.bgmEnabled
                              ? Icons.music_note
                              : Icons.music_off,
                          color: const Color(0xFF5D4037),
                        ),
                        onPressed: () {
                          setState(() => AudioService.instance.toggleBgm());
                          if (AudioService.instance.bgmEnabled) {
                            AudioService.instance.playMenuBgm();
                          }
                        },
                        tooltip: 'BGM',
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          AudioService.instance.sfxEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: const Color(0xFF5D4037),
                        ),
                        onPressed: () => setState(() => AudioService.instance.toggleSfx()),
                        tooltip: '효과음',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
