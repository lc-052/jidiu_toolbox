// lib/games/snake_game.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/widgets/common_app_bar.dart';
import '../shared/widgets/grid_cell.dart';

/// Grid size constants.
const int _gridSize = 20;
const Duration _tickDuration = Duration(milliseconds: 140);

/// Direction enum — matches ArrowKey equivalents.
enum Direction { up, down, left, right }

/// A point on the grid.
class Point {
  final int x;
  final int y;
  const Point({required this.x, required this.y});
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

// ──────────────────────────────────────────────
// Private state class
// ──────────────────────────────────────────────

class _SnakeGameState extends State<SnakeGame> {
  // --- persistent state (cross-game-over) ---
  int _score = 0;

  // --- per-game state ---
  List<Point> _snake = [];
  Point _food = const Point(x: 0, y: 0);
  Direction _direction = Direction.right;
  Direction _nextDirection = Direction.right;
  Timer? _gameTimer;
  bool _isGameOver = false;

  // --- keyboard focus ---
  final FocusNode _focusNode = FocusNode();

  // --- helpers ---
  bool _isValidPoint(Point p) =>
      p.x >= 0 && p.x < _gridSize && p.y >= 0 && p.y < _gridSize;

  void _initGame() {
    final mid = _gridSize ~/ 2;
    _snake = [
      Point(x: mid, y: mid),
      Point(x: mid - 1, y: mid),
      Point(x: mid - 2, y: mid),
    ];
    _direction = Direction.right;
    _nextDirection = Direction.right;
    _score = 0;
    _isGameOver = false;
    _spawnFood();
    _startTimer();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(_tickDuration, (_) => _update());
  }

  void _spawnFood() {
    final occupied = _snake.toSet();
    Point p;
    do {
      p = Point(
        x: DateTime.now().millisecond % _gridSize,
        y: DateTime.now().microsecond % _gridSize,
      );
    } while (occupied.contains(p));
    _food = p;
  }

  void _update() {
    // Apply queued direction (prevent 180° reversal).
    if (_opposite(_direction) != _nextDirection) {
      _direction = _nextDirection;
    }

    final head = _snake.first;
    late Point newHead;
    switch (_direction) {
      case Direction.up:
        newHead = Point(x: head.x, y: head.y - 1);
        break;
      case Direction.down:
        newHead = Point(x: head.x, y: head.y + 1);
        break;
      case Direction.left:
        newHead = Point(x: head.x - 1, y: head.y);
        break;
      case Direction.right:
        newHead = Point(x: head.x + 1, y: head.y);
        break;
    }

    // Wall collision → game over.
    if (!_isValidPoint(newHead)) {
      _endGame();
      return;
    }

    // Self collision → game over (skip tail because it will move away).
    final bodyToCheck = _snake.sublist(0, _snake.length - 1);
    if (bodyToCheck.contains(newHead)) {
      _endGame();
      return;
    }

    final ate = newHead == _food;
    _snake.insert(0, newHead);

    if (ate) {
      _score += 10;
      _spawnFood();
    } else {
      _snake.removeLast();
    }

    setState(() {});
  }

  void _endGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    setState(() => _isGameOver = true);
  }

  Direction _opposite(Direction d) {
    return switch (d) {
      Direction.up => Direction.down,
      Direction.down => Direction.up,
      Direction.left => Direction.right,
      Direction.right => Direction.left,
    };
  }

  void _onKeyEvent(KeyEvent e) {
    if (_isGameOver) return;
    final key = e.logicalKey;
    Direction next = _direction;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      next = Direction.up;
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      next = Direction.down;
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      next = Direction.left;
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      next = Direction.right;
    } else {
      return;
    }
    setState(() => _nextDirection = next);
  }

  void _onPanStart(DragStartDetails details) {
    // Not needed — swipe direction uses velocity from onPanEnd.
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    final minVelocity = 50.0;
    if (dx.abs() < minVelocity && dy.abs() < minVelocity) return;

    Direction next;
    if (dx.abs() > dy.abs()) {
      next = dx > 0 ? Direction.right : Direction.left;
    } else {
      next = dy > 0 ? Direction.down : Direction.up;
    }

    if (_opposite(_direction) == next) return;
    setState(() => _nextDirection = next);
  }

  @override
  void initState() {
    super.initState();
    _initGame();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── build helpers ──────────────────────

  Color _cellColor(int x, int y) {
    final point = Point(x: x, y: y);
    final isHead = _snake.isNotEmpty && _snake.first == point;
    final isBody = !isHead && _snake.contains(point);
    final isFood = point == _food;
    if (isHead) return Theme.of(context).colorScheme.primary;
    if (isBody) return Theme.of(context).colorScheme.secondary;
    if (isFood) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cellSize = constraints.maxWidth / _gridSize;
        return Container(
          constraints: BoxConstraints.tight(Size(constraints.maxWidth.clamp(0, 600), constraints.maxWidth.clamp(0, 600))),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _gridSize,
              (row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _gridSize,
                  (col) => SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: Padding(
                      padding: EdgeInsets.all(cellSize * 0.05),
                      child: GridCell(
                        backgroundColor: _cellColor(col, row),
                        borderRadius: cellSize * 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _gameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '游戏结束',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '得分：$_score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => setState(_initGame),
                      icon: const Icon(Icons.replay),
                      label: const Text('重新开始'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_directionButton(Direction.up, Icons.arrow_upward)],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _directionButton(Direction.left, Icons.arrow_back),
            const SizedBox(width: 8),
            _directionButton(Direction.down, Icons.arrow_downward),
            const SizedBox(width: 8),
            _directionButton(Direction.right, Icons.arrow_forward),
          ],
        ),
      ],
    );
  }

  Widget _directionButton(Direction dir, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 56,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            if (_isGameOver) return;
            if (_opposite(_direction) == dir) return;
            setState(() => _nextDirection = dir);
          },
          icon: Icon(icon, size: 24),
          label: const Text(''),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
      ),
    );
  }

  // ─── build ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '贪吃蛇',
        actions: [
          Text(
            '🍎 $_score',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: _onKeyEvent,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanEnd: _onPanEnd,
                child: Column(
                  children: [
                    // Grid area – expands to fill remaining space.
                    Expanded(
                      flex: 3,
                      child: _buildGrid(),
                    ),
                    // Control pad (visible on mobile / as alternate input).
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _controlPad(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isGameOver) _gameOverOverlay(),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Public widget
// ──────────────────────────────────────────────

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  static const routeName = 'snake';

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}
