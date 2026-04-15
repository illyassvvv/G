import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CheckersApp());
}

const int kN = 8;

const Color cDark  = Color(0xFF769656);
const Color cLight = Color(0xFFEEEED2);
const Color cSel   = Color(0xFFBDE051);
const Color cHint  = Color(0xCC82CAFF);

const Color cRedBase = Color(0xFFCC2929);
const Color cRedHi   = Color(0xFFFF7070);
const Color cBlkBase = Color(0xFF1E1E1E);
const Color cBlkHi   = Color(0xFF5C5C5C);
const Color cGold    = Color(0xFFFFD700);

enum Player   { red, black }
enum Phase    { playing, redWins, blackWins }
enum GameMode { twoPlayer, vsAI }
enum Difficulty { easy, medium, hard }

enum PieceType { empty, red, black, redKing, blackKing }

extension PT on PieceType {
  bool get isEmpty => this == PieceType.empty;
  bool get isRed   => this == PieceType.red   || this == PieceType.redKing;
  bool get isBlack => this == PieceType.black || this == PieceType.blackKing;
  bool get isKing  => this == PieceType.redKing || this == PieceType.blackKing;
  bool belongs(Player p) => p == Player.red ? isRed : isBlack;

  PieceType get promoted =>
      this == PieceType.red   ? PieceType.redKing  :
      this == PieceType.black ? PieceType.blackKing : this;
}

class Pos {
  final int r, c;
  const Pos(this.r, this.c);

  bool get ok => r >= 0 && r < kN && c >= 0 && c < kN;

  @override bool operator ==(Object o) => o is Pos && o.r == r && o.c == c;
  @override int  get hashCode => r * kN + c;
  @override String toString() => '($r,$c)';
}

class Move {
  final Pos        from, to;
  final List<Pos>  captured;
  final bool       becomesKing;
  const Move({
    required this.from, required this.to,
    this.captured = const [], this.becomesKing = false,
  });
  bool get isCapture => captured.isNotEmpty;
}

class MoveResult {
  final bool  isCapture, isPromotion;
  final Phase phase;
  const MoveResult({
    required this.isCapture,
    required this.isPromotion,
    required this.phase,
  });
}

class GameLogic {
  late List<List<PieceType>> _b;
  late Player                currentPlayer;
  late Phase                 phase;
  int redScore = 0, blackScore = 0;

  Pos?       selectedPos;
  List<Move> availableMoves = [];
  List<Move> mandatoryMoves = [];

  GameLogic() { _init(); }

  void _init() {
    _b = List.generate(kN, (_) => List.filled(kN, PieceType.empty));
    for (int r = 0; r < kN; r++) {
      for (int c = 0; c < kN; c++) {
        if ((r + c).isOdd) {
          if (r < 3)      _b[r][c] = PieceType.black;
          else if (r > 4) _b[r][c] = PieceType.red;
        }
      }
    }
    currentPlayer  = Player.black;
    phase          = Phase.playing;
    selectedPos    = null;
    availableMoves = [];
    _calcMandatory();
  }

  void restart() => _init();

  void fullReset() { 
    redScore = 0; 
    blackScore = 0; 
    _init(); 
  }

  PieceType at(Pos p) => p.ok ? _b[p.r][p.c] : PieceType.empty;

  static const List<List<int>> _allDirs = [[-1,-1],[-1,1],[1,-1],[1,1]];

  List<List<int>> _dirs(PieceType piece) {
    if (piece.isKing) return _allDirs;
    if (piece.isRed)  return [[-1,-1],[-1,1]];
    return [[1,-1],[1,1]];
  }

  bool _promotes(Pos to, PieceType piece) =>
      (piece == PieceType.red   && to.r == 0)      ||
      (piece == PieceType.black && to.r == kN - 1);

  List<Move> _regular(Pos pos, PieceType piece) {
    final out = <Move>[];
    for (final d in _dirs(piece)) {
      final to = Pos(pos.r + d[0], pos.c + d[1]);
      if (to.ok && at(to).isEmpty) {
        out.add(Move(from: pos, to: to, becomesKing: _promotes(to, piece)));
      }
    }
    return out;
  }

  List<Move> _jumps(
    Pos startPos, Pos curPos, PieceType piece,
    List<List<PieceType>> board, List<Pos> captured,
  ) {
    final out = <Move>[];
    for (final d in _dirs(piece)) {
      final over = Pos(curPos.r + d[0],    curPos.c + d[1]);
      final to   = Pos(curPos.r + d[0]*2,  curPos.c + d[1]*2);

      if (!to.ok) continue;

      final op = board[over.r][over.c];
      if (op.isEmpty)            continue;
      if (captured.contains(over)) continue;
      assert(!captured.contains(over), 'Piece captured twice in chain');
      if (!(piece.isRed ? op.isBlack : op.isRed)) continue;
      if (board[to.r][to.c] != PieceType.empty)   continue;

      final newCap  = [...captured, over];
      final promotes = _promotes(to, piece);

      if (promotes) {
        out.add(Move(from: startPos, to: to, captured: newCap, becomesKing: true));
      } else {
        final nb     = _sim(board, curPos, over, to, piece);
        final chains = _jumps(startPos, to, piece, nb, newCap);
        if (chains.isEmpty) {
          out.add(Move(from: startPos, to: to, captured: newCap));
        } else {
          out.addAll(chains);
        }
      }
    }
    return out;
  }

  List<List<PieceType>> _sim(
    List<List<PieceType>> b,
    Pos from, Pos over, Pos to, PieceType piece,
  ) {
    final nb = b.map((r) => List<PieceType>.from(r)).toList();
    nb[from.r][from.c] = PieceType.empty;
    nb[over.r][over.c] = PieceType.empty;
    nb[to.r][to.c]     = piece;
    return nb;
  }

  List<Move> movesFor(Pos pos) {
    final piece = at(pos);
    if (piece.isEmpty || !piece.belongs(currentPlayer)) return [];
    final jumps = _jumps(pos, pos, piece, _b, []);
    if (mandatoryMoves.isNotEmpty) return jumps;
    return jumps.isNotEmpty ? jumps : _regular(pos, piece);
  }

  void _calcMandatory() {
    mandatoryMoves = [];
    for (int r = 0; r < kN; r++) {
      for (int c = 0; c < kN; c++) {
        final pos   = Pos(r, c);
        final piece = at(pos);
        if (piece.isEmpty || !piece.belongs(currentPlayer)) continue;
        mandatoryMoves.addAll(_jumps(pos, pos, piece, _b, []));
      }
    }
  }

  bool select(Pos pos) {
    if (phase != Phase.playing) return false;
    final moves = movesFor(pos);
    if (moves.isEmpty) return false;
    selectedPos    = pos;
    availableMoves = moves;
    return true;
  }

  void clearSelect() { selectedPos = null; availableMoves = []; }

  Set<Pos> get targets => availableMoves.map((m) => m.to).toSet();

  MoveResult? moveTo(Pos to) {
    if (selectedPos == null) return null;
    Move? m;
    for (final mv in availableMoves) { if (mv.to == to) { m = mv; break; } }
    if (m == null) return null;
    return _apply(m);
  }

  MoveResult _apply(Move m) {
    final piece = at(m.from);

    _b[m.from.r][m.from.c] = PieceType.empty;
    for (final cap in m.captured) _b[cap.r][cap.c] = PieceType.empty;
    _b[m.to.r][m.to.c] = m.becomesKing ? piece.promoted : piece;

    clearSelect();
    _checkWin();

    if (phase == Phase.playing) {
      currentPlayer = currentPlayer == Player.red ? Player.black : Player.red;
      _calcMandatory();
      if (!_anyMoves(currentPlayer)) {
        _setWinner(currentPlayer == Player.red ? Player.black : Player.red);
      }
    }
    return MoveResult(
      isCapture:   m.isCapture,
      isPromotion: m.becomesKing,
      phase:       phase,
    );
  }

  void _checkWin() {
    int reds = 0, blks = 0;
    for (final row in _b) {
      for (final p in row) {
        if (p.isRed)   reds++;
        if (p.isBlack) blks++;
      }
    }
    if (reds == 0) _setWinner(Player.black);
    if (blks == 0) _setWinner(Player.red);
  }

  bool _anyMoves(Player player) {
    for (int r = 0; r < kN; r++) {
      for (int c = 0; c < kN; c++) {
        final pos   = Pos(r, c);
        final piece = at(pos);
        if (piece.isEmpty || !piece.belongs(player)) continue;
        if (_jumps(pos, pos, piece, _b, []).isNotEmpty) return true;
        if (_regular(pos, piece).isNotEmpty)             return true;
      }
    }
    return false;
  }

  void _setWinner(Player w) {
    phase = w == Player.red ? Phase.redWins : Phase.blackWins;
    if (w == Player.red) redScore++; else blackScore++;
  }

  int _evaluateBoard(List<List<PieceType>> board) {
    int score = 0;
    for (int r = 0; r < kN; r++) {
      for (int c = 0; c < kN; c++) {
        final p = board[r][c];
        if (p.isEmpty) continue;
        int val = p.isKing ? 10 : 5;
        if (p.isRed) score += val;
        else score -= val;
      }
    }
    return score;
  }

  List<Move> _getRegularSim(Pos pos, PieceType piece, List<List<PieceType>> board) {
    final out = <Move>[];
    for (final d in _dirs(piece)) {
      final to = Pos(pos.r + d[0], pos.c + d[1]);
      if (to.ok && board[to.r][to.c] == PieceType.empty) {
        out.add(Move(from: pos, to: to, becomesKing: _promotes(to, piece)));
      }
    }
    return out;
  }

  List<Move> _getAllSim(List<List<PieceType>> board, Player p) {
    final jumps = <Move>[];
    final regulars = <Move>[];
    for (int r = 0; r < kN; r++) {
      for (int c = 0; c < kN; c++) {
        final pos = Pos(r, c);
        final piece = board[r][c];
        if (!piece.isEmpty && piece.belongs(p)) {
          jumps.addAll(_jumps(pos, pos, piece, board, []));
        }
      }
    }
    if (jumps.isNotEmpty) return jumps;
    
    for (int r = 0; r < kN; r++) {
      for (int c = 0; c < kN; c++) {
        final pos = Pos(r, c);
        final piece = board[r][c];
        if (!piece.isEmpty && piece.belongs(p)) {
          regulars.addAll(_getRegularSim(pos, piece, board));
        }
      }
    }
    return regulars;
  }

  List<List<PieceType>> _simMove(List<List<PieceType>> board, Move m) {
    final nb = board.map((r) => List<PieceType>.from(r)).toList();
    final piece = nb[m.from.r][m.from.c];
    nb[m.from.r][m.from.c] = PieceType.empty;
    for (final cap in m.captured) nb[cap.r][cap.c] = PieceType.empty;
    nb[m.to.r][m.to.c] = m.becomesKing ? piece.promoted : piece;
    return nb;
  }

  int _minimax(List<List<PieceType>> board, int depth, bool isMax) {
    if (depth == 0) return _evaluateBoard(board);
    final player = isMax ? Player.red : Player.black;
    final moves = _getAllSim(board, player);
    if (moves.isEmpty) return isMax ? -999 : 999;

    if (isMax) {
      int maxE = -9999;
      for (final m in moves) {
        int eval = _minimax(_simMove(board, m), depth - 1, false);
        if (eval > maxE) maxE = eval;
      }
      return maxE;
    } else {
      int minE = 9999;
      for (final m in moves) {
        int eval = _minimax(_simMove(board, m), depth - 1, true);
        if (eval < minE) minE = eval;
      }
      return minE;
    }
  }

  Move? aiMove(Difficulty diff) {
    if (phase != Phase.playing) return null;
    final moves = _getAllSim(_b, currentPlayer);
    if (moves.isEmpty) return null;

    if (diff == Difficulty.easy) {
      return moves[Random().nextInt(moves.length)];
    }

    if (diff == Difficulty.medium) {
      int score(Move m) {
        int s = 0;
        if (m.isCapture) s += 10 + m.captured.length * 5;
        if (m.becomesKing) s += 8;
        return s;
      }
      moves.sort((a, b) => score(b) - score(a));
      final best = score(moves.first);
      final top = moves.where((m) => score(m) == best).toList();
      return top[Random().nextInt(top.length)];
    }

    moves.shuffle(); 
    Move? bestMove;
    int bestVal = -9999;
    
    for (final m in moves) {
      final nb = _simMove(_b, m);
      int moveVal = _minimax(nb, 2, false); 
      if (m.isCapture) moveVal += 3;
      
      if (moveVal > bestVal) {
        bestVal = moveVal;
        bestMove = m;
      }
    }
    return bestMove ?? moves.first;
  }

  MoveResult? applyAI(Move m) {
    selectedPos    = m.from;
    availableMoves = [m];
    return moveTo(m.to);
  }
}

class Sounds {
  static void _play(Future<void> Function() hapticCall) {
    hapticCall().catchError((e) {
      if (kDebugMode) debugPrint('Haptic unavailable: $e');
    });
  }

  static void move()    => _play(HapticFeedback.selectionClick);
  static void capture() => _play(HapticFeedback.mediumImpact);
  static void win()     => _play(HapticFeedback.heavyImpact);
  static void tap()     => _play(HapticFeedback.lightImpact);
}

class CheckersApp extends StatelessWidget {
  const CheckersApp({super.key});

  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'Checkers',
    debugShowCheckedModeBanner: false,
    theme: const CupertinoThemeData(brightness: Brightness.light),
    home: const GameScreen(),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _g = GameLogic();
  GameMode _mode   = GameMode.twoPlayer;
  Difficulty _difficulty = Difficulty.medium;
  bool     _aiTurn = false;
  Timer?   _aiTimer;
  bool     _winDialogShown = false; 

  @override
  void dispose() { 
    _aiTimer?.cancel(); 
    super.dispose(); 
  }

  void _onTap(Pos pos) {
    if (_g.phase != Phase.playing) return;
    if (_aiTurn)  return;
    if (_mode == GameMode.vsAI && _g.currentPlayer == Player.red) return;

    setState(() {
      if (_g.targets.contains(pos)) {
        final res = _g.moveTo(pos);
        if (res != null) _afterMove(res);
      } else {
        final piece = _g.at(pos);
        if (!piece.isEmpty && piece.belongs(_g.currentPlayer)) {
          if (_g.selectedPos == pos) {
            _g.clearSelect();
          } else {
            _g.select(pos);
            Sounds.tap();
          }
        } else {
          _g.clearSelect(); 
        }
      }
    });
  }

  void _afterMove(MoveResult res) {
    if (res.isCapture) Sounds.capture(); else Sounds.move();
    if (res.phase != Phase.playing) {
      Sounds.win();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWin(res.phase));
      return;
    }
    if (_mode == GameMode.vsAI && _g.currentPlayer == Player.red) {
      _scheduleAI();
    }
  }

  void _scheduleAI() {
    setState(() => _aiTurn = true);
    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final move = _g.aiMove(_difficulty); 
      setState(() {
        _aiTurn = false;
        if (move == null) return;
        final res = _g.applyAI(move);
        if (res != null) _afterMove(res);
      });
    });
  }

  void _showWin(Phase phase) {
    if (_winDialogShown) return;
    _winDialogShown = true;
    
    _aiTimer?.cancel();
    if (!mounted) return;
    
    final redWon = phase == Phase.redWins;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          redWon ? '🔴 Red Wins!' : '⚫ Black Wins!',
          style: const TextStyle(fontSize: 20),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Score   🔴 ${_g.redScore} – ${_g.blackScore} ⚫',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () { 
              _winDialogShown = false;
              Navigator.pop(ctx); 
              _restart(); 
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    _aiTimer?.cancel();
    setState(() { 
      _g.restart(); 
      _aiTurn = false; 
    });
  }

  void _toggleMode() {
    _aiTimer?.cancel(); 
    setState(() {
      _mode = _mode == GameMode.twoPlayer ? GameMode.vsAI : GameMode.twoPlayer;
      _g.restart();
      _aiTurn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Checkers',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _restart,
          child: const Icon(CupertinoIcons.refresh, size: 22),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 12),
          _buildScoreBar(),
          const SizedBox(height: 10),
          _buildTurnBadge(),
          const SizedBox(height: 10),
          Expanded(child: _buildBoard()),
          _buildBottomBar(),
        ]),
      ),
    );
  }

  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreChip('🔴 Red',   _g.redScore,   cRedBase),
          GestureDetector(
            onLongPress: () {
              setState(() => _g.fullReset());
              Sounds.tap();
            },
            child: const Text('SCORE', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 2, color: CupertinoColors.secondaryLabel,
            )),
          ),
          _scoreChip('Black ⚫', _g.blackScore, cBlkBase),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        Text('$score', style: TextStyle(fontSize: 26, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildTurnBadge() {
    final isRed = _g.currentPlayer == Player.red;
    final col   = isRed ? cRedBase : cBlkBase;

    final label = _g.phase != Phase.playing
        ? (_g.phase == Phase.redWins ? '🔴 Red Wins!' : '⚫ Black Wins!')
        : _aiTurn
            ? 'AI is thinking…'
            : (isRed ? '🔴 Red' : '⚫ Black') + '\'s Turn';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: col.withOpacity(0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
          color: col, fontWeight: FontWeight.w600, fontSize: 15,
        )),
        if (_aiTurn) ...[
          const SizedBox(width: 10),
          const CupertinoActivityIndicator(),
        ],
      ]),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x50000000), blurRadius: 22, offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: kN,
                ),
                itemCount: kN * kN,
                itemBuilder: (_, idx) => _buildCell(idx ~/ kN, idx % kN),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final pos      = Pos(row, col);
    final isDark   = (row + col).isOdd;
    final piece    = _g.at(pos);
    final isSel    = _g.selectedPos == pos;
    final isTarget = _g.targets.contains(pos);

    final bg = isSel                ? cSel
             : (isTarget && isDark) ? cHint
             : isDark               ? cDark
             :                        cLight;

    return GestureDetector(
      onTap: () => _onTap(pos),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: bg,
        child: isDark
          ? Stack(alignment: Alignment.center, children: [
              if (isTarget && piece.isEmpty)
                Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: cHint, shape: BoxShape.circle,
                  ),
                ),
              if (!piece.isEmpty) _buildPiece(piece, isSel),
            ])
          : null, 
      ),
    );
  }

  Widget _buildPiece(PieceType piece, bool selected) {
    final isRed  = piece.isRed;
    final isKing = piece.isKing;

    return AnimatedScale(
      scale: selected ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 140),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.40),
            colors: [
              isRed ? cRedHi : cBlkHi,
              isRed ? cRedBase : cBlkBase,
            ],
          ),
          border: isKing
              ? Border.all(color: cGold, width: 2.5)
              : selected
                  ? Border.all(color: const Color(0xCCFFFF99), width: 2)
                  : null,
          boxShadow: [
            const BoxShadow(
              color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2),
            ),
            if (selected)
              const BoxShadow(
                color: Color(0x55FFE066), blurRadius: 10, spreadRadius: 1,
              ),
          ],
        ),
        child: isKing
          ? const Center(
              child: Text(
                '★',
                style: TextStyle(
                  color: cGold, fontSize: 15, fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_mode == GameMode.vsAI) ...[
          CupertinoSlidingSegmentedControl<Difficulty>(
            groupValue: _difficulty,
            children: const {
              Difficulty.easy: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Easy', style: TextStyle(fontSize: 13))),
              Difficulty.medium: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Medium', style: TextStyle(fontSize: 13))),
              Difficulty.hard: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Hard', style: TextStyle(fontSize: 13))),
            },
            onValueChanged: (val) {
              if (val != null && !_aiTurn) setState(() => _difficulty = val);
            },
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          child: Row(children: [
            Expanded(child: _btn(
              label: _mode == GameMode.twoPlayer ? '👥  2 Players' : '🤖  vs AI',
              onTap: _toggleMode,
              primary: false,
            )),
            const SizedBox(width: 12),
            Expanded(child: _btn(
              label: '↺  New Game',
              onTap: _restart,
              primary: true,
            )),
          ]),
        ),
      ],
    );
  }

  Widget _btn({
    required String       label,
    required VoidCallback onTap,
    required bool         primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: primary ? CupertinoColors.white : CupertinoColors.label,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
