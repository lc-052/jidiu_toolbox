import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/widgets/common_app_bar.dart';

class SlidingPuzzleGame extends StatefulWidget {
  const SlidingPuzzleGame({super.key});

  static const String routeName = 'sliding';

  @override
  State<SlidingPuzzleGame> createState() => _SlidingPuzzleGameState();
}

class _SlidingPuzzleGameState extends State<SlidingPuzzleGame> {
  late int gridSize;
  List<int?> tiles = []; // null represents the blank cell
  bool won = false;
  int moves = 0;
  int elapsedSeconds = 0;
  Timer? timer;

  final List<int> gridSizes = [3, 4, 5];

  @override
  void initState() {
    super.initState();
    gridSize = 3;
    newGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Start a new game with the current grid size.
  /// Generates a shuffled solvable puzzle via simulated sliding moves.
  void newGame() {
    setState(() {
      timer?.cancel();
      moves = 0;
      elapsedSeconds = 0;
      won = false;
      isRunning = true;
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return timer!.cancel();
        setState(() => elapsedSeconds++);
      });

      try {
        // Generate a solvable puzzle by starting from solved state
        // and performing many random valid slides. This guarantees solvability.
        tiles = _solvedTiles();
        _shuffleBySlides();
      } catch (e) {
        // Fallback: if anything goes wrong, start fresh
        tiles = _solvedTiles();
      }
    });
  }

  /// Create the solved order: [1, 2, ..., n*n-1, null]
  List<int?> _solvedTiles() {
    final total = gridSize * gridSize;
    final list = List<int?>.filled(total, null);
    for (int i = 0; i < total - 1; i++) {
      list[i] = i + 1;
    }
    list[total - 1] = null; // last cell is blank
    return list;
  }

  /// Shuffle by simulating random valid tile slides from the solved state.
  /// Each move slides a neighbor into the blank space, preserving solvability.
  void _shuffleBySlides() {
    final rng = Random();
    final numMoves = gridSize * gridSize * gridSize * 1000;
    var blankIdx = tiles.indexOf(null);

    for (int i = 0; i < numMoves; i++) {
      final neighbors = _getNeighbors(blankIdx);
      if (neighbors.isEmpty) continue;
      final chosen = neighbors[rng.nextInt(neighbors.length)];

      // Swap blank with chosen neighbor
      tiles[blankIdx] = tiles[chosen];
      tiles[chosen] = null;
      blankIdx = chosen;
    }
  }

  /// Get neighbor indices of the given index in the grid.
  List<int> _getNeighbors(int idx) {
    final row = idx ~/ gridSize;
    final col = idx % gridSize;
    final result = <int>[];
    if (row > 0) result.add(idx - gridSize); // above
    if (row < gridSize - 1) result.add(idx + gridSize); // below
    if (col > 0) result.add(idx - 1); // left
    if (col < gridSize - 1) result.add(idx + 1); // right
    return result;
  }

  /// Handle tile tap: move adjacent tile into blank space
  void onTileTapped(int index) {
    if (won) return;
    final blankIdx = tiles.indexOf(null);
    final neighbors = _getNeighbors(blankIdx);
    if (!neighbors.contains(index)) return;

    setState(() {
      tiles[blankIdx] = tiles[index];
      tiles[index] = null;
      moves++;
    });

    // Check win condition
    if (_checkWin()) {
      won = true;
      timer?.cancel();
      isRunning = false;
    }
  }

  bool _checkWin() {
    final total = gridSize * gridSize;
    for (int i = 0; i < total - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles[total - 1] == null;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool isRunning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = isDark
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final tileTextColor = isDark
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final blankColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerLow;

    return Scaffold(
      appBar: CommonAppBar(title: '数字华容道'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Difficulty selector
                Text(
                  '选择难度',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: gridSizes.map((size) {
                    final isSelected = size == gridSize;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          gridSize = size;
                          newGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        child: Text('${size}x${size}'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '步数: $moves',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      '时间: ${_formatTime(elapsedSeconds)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Puzzle board
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: blankColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.outline
                            : theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: GridView.builder(
                      key: ValueKey('puzzle_${gridSize}_${elapsedSeconds}'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        childAspectRatio: 1,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: gridSize * gridSize,
                      itemBuilder: (context, index) {
                        final value = tiles[index];
                        if (value == null) {
                          // Blank cell
                          return Container(
                            decoration: BoxDecoration(
                              color: blankColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }
                        final neighbors = _getNeighbors(
                            tiles.indexOf(null));
                        final canMove = neighbors.contains(index);
                        // Highlight tile when it's already in its solved position
                        final inCorrectPos = (value != null && value == index + 1);
                        final actualIndex = index;
                        return InkWell(
                          onTap: () => onTileTapped(actualIndex),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: inCorrectPos
                                  ? theme.colorScheme.primaryContainer
                                  : tileColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: inCorrectPos
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                '$value',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: inCorrectPos
                                      ? theme.colorScheme.onPrimaryContainer
                                      : tileTextColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // New game button
                ElevatedButton.icon(
                  onPressed: newGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('新游戏'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                ),

                // Win message
                if (won) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🎉 恭喜过关！',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '共 $moves 步，用时 ${_formatTime(elapsedSeconds)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
