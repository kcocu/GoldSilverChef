import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/audio_service.dart';
import '../services/game_state.dart';
import '../widgets/ingredient_picker.dart';
import '../widgets/cooking_tools.dart';
import '../widgets/cooking_result_card.dart';
import 'judging_screen.dart';

class CookingScreen extends StatefulWidget {
  final bool isRandom;
  final String? requiredTheme; // 스토리 모드 주제

  const CookingScreen({
    super.key,
    this.isRandom = false,
    this.requiredTheme,
  });

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  Timer? _cookingTimer;
  bool _isCooking = false;
  final _audio = AudioService.instance;

  @override
  void initState() {
    super.initState();
    _audio.playCookingBgm();
  }

  @override
  void dispose() {
    _cookingTimer?.cancel();
    _audio.playMenuBgm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final title = widget.isRandom ? '랜덤 모드' : (widget.requiredTheme != null ? '주제: ${widget.requiredTheme}' : '자유 경연');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.resetCooking(),
            tooltip: '초기화',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFFFF8E1),
        child: Column(
          children: [
            // 주제 힌트 표시
            if (widget.requiredTheme != null) _buildThemeHint(state),

            // 선택된 재료 표시
            _buildSelectedIngredients(state),

            const Divider(height: 1),

            // 조리 도구
            CookingTools(
              knifeCount: state.knifeCount,
              waterAmount: state.waterAmount,
              fireLevel: state.fireLevel,
              isCooking: _isCooking,
              cookingTime: state.cookingTime,
              onChop: () { state.chop(); _audio.playChop(); },
              onWaterChange: (v) => state.setWaterAmount(v),
              onFireChange: (v) { state.setFireLevel(v); _audio.playFire(); },
              onStartCooking: _startCooking,
              onStopCooking: _stopCooking,
            ),

            const Divider(height: 1),

            // 결과 또는 재료 선택
            Expanded(
              child: state.lastResult != null
                  ? _buildResultArea(state)
                  : IngredientPicker(
                      engine: state.engine,
                      onSelect: (id) => state.addIngredient(id),
                      isRandom: widget.isRandom,
                    ),
            ),
          ],
        ),
      ),
      // 조합 버튼
      floatingActionButton: state.lastResult == null && state.selectedIngredients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _tryCook(state),
              icon: const Icon(Icons.local_fire_department),
              label: const Text('조리하기'),
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildThemeHint(GameState state) {
    if (widget.requiredTheme == null) return const SizedBox.shrink();

    final chain = state.engine.getRecipeChain(widget.requiredTheme!);
    if (chain.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFE3F2FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 조합 힌트:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...chain.map((r) {
            final inputs = r.inputs.map((i) {
              final ing = state.engine.getIngredient(i.ingredientId);
              return ing?.name ?? i.ingredientId;
            }).join(' + ');
            return Text('$inputs → ${r.name}', style: const TextStyle(fontSize: 13));
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedIngredients(GameState state) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFFFF3E0),
      child: state.selectedIngredients.isEmpty
          ? const Center(
              child: Text('아래에서 재료를 선택하세요', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.selectedIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = state.engine.getIngredient(state.selectedIngredients[index]);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => state.removeIngredient(index),
                    child: Chip(
                      avatar: Text(ingredient?.icon ?? '?', style: const TextStyle(fontSize: 18)),
                      label: Text(ingredient?.name ?? '?'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => state.removeIngredient(index),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildResultArea(GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CookingResultCard(result: state.lastResult!),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => state.useResultAsIngredient(),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('재료로 사용'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.requestJudging();
                    if (state.lastJudging != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JudgingScreen(result: state.lastJudging!),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.gavel),
                  label: const Text('심사 받기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startCooking(GameState state) {
    setState(() => _isCooking = true);
    _cookingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      state.addCookingTime(0.5);
    });
  }

  void _stopCooking() {
    _cookingTimer?.cancel();
    setState(() => _isCooking = false);
  }

  void _tryCook(GameState state) {
    _stopCooking();
    final result = state.cook();
    if (result != null) {
      _audio.playBell();
      _audio.playCookware();
    }
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 조합으로는 만들 수 있는 요리가 없습니다!')),
      );
    } else {
      final isNew = state.recipeBook.isDiscovered(result.recipeId);
      if (isNew) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 새 요리 발견! ${result.recipeName}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    }
  }
}
