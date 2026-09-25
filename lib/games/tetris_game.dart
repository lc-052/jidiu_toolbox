// lib/games/tetris_game.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/widgets/common_app_bar.dart';

const int _cols = 10;
const int _rows = 20;
const Duration _initialTick = Duration(milliseconds: 600);

enum TetrominoType { i, o, t, s, z, j, l }

class Piece {
  final TetrominoType type;
  final List<List<int>> shape;
  final int x, y;
  const Piece({required this.type, required this.shape, this.x = 0, this.y = 0});
  Piece copyAt({TetrominoType? type, List<List<int>>? shape, int? x, int? y}) =>
      Piece(type: type ?? this.type, shape: shape ?? this.shape, x: x ?? this.x, y: y ?? this.y);
}

final Map<TetrominoType, List<List<int>>> _shapes = {
  TetrominoType.i: [[0,0,0,0],[1,1,1,1],[0,0,0,0],[0,0,0,0]],
  TetrominoType.o: [[1,1],[1,1]],
  TetrominoType.t: [[0,1,0],[1,1,1],[0,0,0]],
  TetrominoType.s: [[0,1,1],[1,1,0],[0,0,0]],
  TetrominoType.z: [[1,1,0],[0,1,1],[0,0,0]],
  TetrominoType.j: [[1,0,0],[1,1,1],[0,0,0]],
  TetrominoType.l: [[0,0,1],[1,1,1],[0,0,0]],
};

final Map<TetrominoType, Color> _palette = {
  TetrominoType.i: Colors.cyan,
  TetrominoType.o: Colors.amber,
  TetrominoType.t: Colors.purple,
  TetrominoType.s: Colors.green,
  TetrominoType.z: Colors.red,
  TetrominoType.j: Colors.blue,
  TetrominoType.l: Colors.orange,
};

/// Tetris game — classic brick-falling puzzle. Route name: `'tetris'`.
class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});
  static const routeName = 'tetris';
  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  // Board: 2D array where each cell holds the colour of a locked block, or null if empty.
  late List<List<Color?>> _board;

  /// Current falling piece, or null when the game is over / between pieces.
  Piece? _currentPiece;

  /// The type that will become the next piece once [_currentPiece] locks.
  TetrominoType? _nextPieceType;

  int _score = 0;
  bool _gameOver = false;
  Timer? _dropTimer;
  bool _paused = false;
  Offset? _swipeStart;

  void _newBoard() {
    _board = [];
    for (var r = 0; r < _rows; r++) {
      _board.add(List.filled(_cols, null));
    }
  }

  TetrominoType _randomType() => TetrominoType.values[Random().nextInt(TetrominoType.values.length)];

  void _newPiece() {
    if (_nextPieceType == null) _nextPieceType = _randomType();
    final t = _nextPieceType!;
    _nextPieceType = _randomType();
    final shape = _shapes[t]!;
    final offset = (_cols - shape.first.length) ~/ 2;
    _currentPiece = Piece(type: t, shape: shape, x: offset, y: 0);
    if (!canFit(_currentPiece!, 0, 0)) setState(() => _gameOver = true);
  }

  /// Returns true if every occupied cell of *p* shifted by *(dx, dy)* fits within bounds.
  bool canFit(Piece p, int dx, int dy) {
    for (int r = 0; r < p.shape.length; r++) {
      for (int c = 0; c < p.shape[r].length; c++) {
        if (p.shape[r][c] == 0) continue;
        final nx = p.x + c + dx, ny = p.y + r + dy;
        if (nx < 0 || nx >= _cols || ny >= _rows) return false;
        if (ny >= 0 && _board[ny][nx] != null) return false;
      }
    }
    return true;
  }

  /// Lock the current piece onto the board and clear completed lines.
  void lockPiece() {
    for (int r = 0; r < _currentPiece!.shape.length; r++) {
      for (int c = 0; c < _currentPiece!.shape[r].length; c++) {
        if (_currentPiece!.shape[r][c] == 0) continue;
        final ny = _currentPiece!.y + r;
        if (ny >= 0 && ny < _rows) {
          _board[ny][_currentPiece!.x + c] = _palette[_currentPiece!.type];
        }
      }
    }
    clearLines();
    setState(() {});
    if (!_gameOver) _newPiece();
  }

  /// Remove any full rows and replace them with empty rows at the top.
  void clearLines() {
    int cleared = 0;
    final kept = <List<Color?>>[];
    for (var r = 0; r < _rows; r++) {
      if (!_board[r].every((e) => e != null)) kept.add(List.from(_board[r]));
      else cleared++;
    }
    while (kept.length < _rows) {
      kept.insert(0, List.filled(_cols, null));
    }
    if (cleared > 0) {
      setState(() {
        _board = kept;
        switch (cleared) {
          case 1: _score += 100; break;
          case 2: _score += 300; break;
          case 3: _score += 500; break;
          default: _score += 800; break;
        }
      });
    }
  }

  /// Start / restart the auto-drop timer (speed increases with score).
  void startDrop() {
    var interval = _initialTick;
    if (_score > 5000) interval = const Duration(milliseconds: 300);
    else if (_score > 2000) interval = const Duration(milliseconds: 400);
    _dropTimer?.cancel();
    _dropTimer = Timer.periodic(interval, (_) {
      if (_paused || _gameOver || _currentPiece == null) return;
      if (canFit(_currentPiece!, 0, 1)) {
        setState(() => _currentPiece = _currentPiece!.copyAt(y: _currentPiece!.y + 1));
      } else {
        lockPiece();
      }
    });
  }

  /// Rotate the current piece 90° clockwise with wall-kick support.
  void rotatePiece() {
    if (_currentPiece == null) return;
    final shape = _currentPiece!.shape, n = shape.length;
    final rotated = <List<int>>[];
    for (var i = 0; i < n; i++) {
      rotated.add(List.filled(n, 0));
    }
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        rotated[c][n - 1 - r] = shape[r][c];
      }
    }
    final test = _currentPiece!.copyAt(shape: rotated);
    for (var kick = -2; kick <= 2; kick++) {
      if (canFit(test, kick, 0)) {
        setState(() => _currentPiece = test.copyAt(x: test.x + kick));
        return;
      }
    }
  }

  void moveLeft() {
    if (_currentPiece == null) return;
    if (canFit(_currentPiece!, -1, 0)) {
      setState(() => _currentPiece = _currentPiece!.copyAt(x: _currentPiece!.x - 1));
    }
  }

  void moveRight() {
    if (_currentPiece == null) return;
    if (canFit(_currentPiece!, 1, 0)) {
      setState(() => _currentPiece = _currentPiece!.copyAt(x: _currentPiece!.x + 1));
    }
  }

  void moveDown() {
    if (_currentPiece == null) return;
    if (canFit(_currentPiece!, 0, 1)) {
      setState(() => _currentPiece = _currentPiece!.copyAt(y: _currentPiece!.y + 1));
    } else {
      lockPiece();
    }
  }

  void hardDrop() {
    if (_currentPiece == null) return;
    while (canFit(_currentPiece!, 0, 1)) {
      setState(() => _currentPiece = _currentPiece!.copyAt(y: _currentPiece!.y + 1));
    }
    lockPiece();
  }

  /// Start or restart the game from scratch.
  void startGame() {
    _newBoard();
    _score = 0;
    _gameOver = false;
    _paused = false;
    _nextPieceType = null;
    _newPiece();
    startDrop();
    setState(() {});
  }

  /// Called when the keyboard listener receives a key event.
  void _onKeyEvent(KeyEvent e) {
    if (_gameOver || _paused || _currentPiece == null) return;
    if (e is KeyDownEvent) {
      switch (e.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          moveLeft();
          break;
        case LogicalKeyboardKey.arrowRight:
          moveRight();
          break;
        case LogicalKeyboardKey.arrowUp:
          rotatePiece();
          break;
        case LogicalKeyboardKey.arrowDown:
          moveDown();
          break;
        case LogicalKeyboardKey.space:
          hardDrop();
          break;
        case LogicalKeyboardKey.keyP:
          setState(() => _paused = !_paused);
          break;
      }
    }
  }

  void _onPanStart(DragStartDetails d) => _swipeStart = d.globalPosition;

  void _onPanEnd(DragEndDetails d) {
    if (_swipeStart == null || _gameOver || _currentPiece == null) return;
    final vel = d.velocity?.pixelsPerSecond;
    if (vel == null) return;
    if (vel.dx.abs() > 100) {
      vel.dx > 0 ? moveRight() : moveLeft();
    } else if (vel.dy.abs() > 100) {
      moveDown();
    } else if (vel.dy.abs() < 50) {
      rotatePiece();
    }
    _swipeStart = null;
  }

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _dropTimer?.cancel();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pad = MediaQuery.of(context).padding;
    final availH = MediaQuery.of(context).size.height - pad.top - pad.bottom - kToolbarHeight - 80;
    final boardH = (availH * 0.85).clamp(200.0, 620.0);
    final cellSize = boardH / _rows;
    final boardW = cellSize * _cols;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: CommonAppBar(title: '俄罗斯方块'),
        body: SafeArea(
          child: Stack(
            children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Score row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('得分: $_score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (_nextPieceType != null) ...[
                        Icon(Icons.star, size: 24, color: _palette[_nextPieceType]),
                        const SizedBox(width: 4),
                        Text('下一个:', style: theme.textTheme.bodySmall),
                      ],
                      IconButton(
                        icon: const Icon(Icons.replay),
                        tooltip: '重新开始',
                        onPressed: startGame,
                      ),
                    ],
                  ),
                ),
                // Board area
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanEnd: _onPanEnd,
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: _onKeyEvent,
                        child: Container(
                          width: boardW.clamp(100, 600),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[400]!, width: 2),
                          ),
                          child: CustomPaint(
                            painter: _TetrisPainter(board: _board, piece: _currentPiece, cellSize: cellSize, isDark: isDark),
                            size: Size(boardW.clamp(100, 600), boardH),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Mobile control buttons
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ctrl(Icons.arrow_back, moveLeft),
                      _ctrl(Icons.rotate_left, rotatePiece),
                      _ctrl(Icons.arrow_forward, moveRight),
                      const SizedBox(width: 16),
                      _ctrl(Icons.keyboard_double_arrow_down, hardDrop, primary: true),
                    ],
                  ),
                ),
              ]),
              // Game-over overlay
              if (_gameOver)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('游戏结束', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error)),
                          const SizedBox(height: 12),
                          Text('得分: $_score', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: startGame,
                            icon: const Icon(Icons.replay),
                            label: const Text('重新开始'),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              // Pause overlay
              if (_paused && !_gameOver)
                Container(
                  color: Colors.black38,
                  child: const Center(child: Text('暂停', style: TextStyle(fontSize: 32, color: Colors.white))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctrl(IconData icon, VoidCallback fn, {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: fn,
        icon: Icon(icon, size: 24, color: primary ? Theme.of(context).colorScheme.onPrimary : null),
        label: const Text(''),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(56, 56),
          backgroundColor: primary ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }
}

/// Custom painter that draws the tetris board on a Canvas.
class _TetrisPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Piece? piece;
  final double cellSize;
  final bool isDark;

  _TetrisPainter({required this.board, required this.piece, required this.cellSize, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Background rectangle
    final pad = 4.0;
    final bw = cellSize * _cols;
    final bh = cellSize * _rows;
    final bg = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pad, pad, bw, bh), const Radius.circular(6)),
      Paint()..color = bg,
    );

    // Draw grid lines
    final gridColor = isDark ? Colors.grey[800]! : Colors.grey[400]!;
    for (var r = 0; r <= _rows; r++) {
      final y = pad + r * cellSize;
      canvas.drawLine(Offset(pad, y), Offset(pad + bw, y), Paint()..color = gridColor..strokeWidth = 0.5);
    }
    for (var c = 0; c <= _cols; c++) {
      final x = pad + c * cellSize;
      canvas.drawLine(Offset(x, pad), Offset(x, pad + bh), Paint()..color = gridColor..strokeWidth = 0.5);
    }

    // Draw locked blocks
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final cell = board[r][c];
        if (cell != null) {
          final x = pad + c * cellSize;
          final y = pad + r * cellSize;
          canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2), Paint()..color = cell);
        }
      }
    }

    // Draw current (falling) piece
    if (piece != null) {
      final col = _palette[piece!.type]!;
      for (var r = 0; r < piece!.shape.length; r++) {
        for (var c = 0; c < piece!.shape[r].length; c++) {
          if (piece!.shape[r][c] == 0) continue;
          final px = pad + (piece!.x + c) * cellSize;
          final py = pad + (piece!.y + r) * cellSize;
          if (py >= pad && py < pad + bh) {
            canvas.drawRect(Rect.fromLTWH(px + 1, py + 1, cellSize - 2, cellSize - 2), Paint()..color = col.withValues(alpha: 0.75));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TetrisPainter old) =>
      old.board != board || old.piece != piece || old.cellSize != cellSize || old.isDark != isDark;
}