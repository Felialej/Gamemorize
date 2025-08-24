import 'package:flutter/material.dart';

void main() {
  runApp(const GamemorizeApp());
}

class GamemorizeApp extends StatelessWidget {
  const GamemorizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamemorize',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF)),
        scaffoldBackgroundColor: const Color(0xFFFFF7F2),
        // 👇 IMPORTANTE: CardThemeData (no CardTheme)
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const MemoryGamePage(),
    );
  }
}

class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key});

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  // 🔹 Tablero fijo 4×4 => 16 cartas => 8 pares
  static const int _columns = 4;
  static const int _rows = 4;

  late List<_GameCard> _cards;
  _GameCard? _firstSelected;
  bool _allowFlip = true;

  int _moves = 0; // intentos
  Duration _elapsed = Duration.zero;
  bool _timerRunning = false;
  Ticker? _ticker;

  static const List<IconData> _iconPool = [
    Icons.cake,
    Icons.flight,
    Icons.home,
    Icons.sports_esports,
    Icons.star,
    Icons.work,
    Icons.pets,
    Icons.favorite,
    Icons.music_note,
    Icons.extension,
    Icons.anchor,
    Icons.directions_bike,
  ];

  @override
  void initState() {
    super.initState();
    _initializeCards();
    _ticker = Ticker((dt) {
      if (_timerRunning) {
        setState(() => _elapsed += dt);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _initializeCards() {
    _timerRunning = false;
    _elapsed = Duration.zero;
    _moves = 0;

    final neededPairs = (_columns * _rows) ~/ 2; // 8 pares
    final icons = _iconPool.take(neededPairs).toList();

    _cards = icons
        .expand((icon) => [_GameCard(icon), _GameCard(icon)])
        .toList()
      ..shuffle();

    setState(() {
      _firstSelected = null;
      _allowFlip = true;
    });
  }

  void _onCardTapped(_GameCard card) {
    if (!_allowFlip || card.isFaceUp || card.isMatched) return;

    if (!_timerRunning) _timerRunning = true;

    setState(() => card.isFaceUp = true);

    if (_firstSelected == null) {
      _firstSelected = card;
    } else {
      _moves++;
      if (_firstSelected!.icon == card.icon) {
        setState(() {
          card.isMatched = true;
          _firstSelected!.isMatched = true;
          _firstSelected = null;
        });
        if (_cards.every((c) => c.isMatched)) {
          _timerRunning = false;
          Future.delayed(const Duration(milliseconds: 300), _showWinDialog);
        }
      } else {
        _allowFlip = false;
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            card.isFaceUp = false;
            _firstSelected!.isFaceUp = false;
            _firstSelected = null;
            _allowFlip = true;
          });
        });
      }
    }
  }

  void _resetGame() => _initializeCards();

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _showWinDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('¡Ganaste! 🎉'),
          content: Text('Tiempo: ${_formatDuration(_elapsed)}\nIntentos: $_moves'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('Jugar de nuevo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamemorize'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con tiempo e intentos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: _formatDuration(_elapsed),
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.touch_app_outlined,
                  label: 'Intentos: $_moves',
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
          ),

          // Tablero 4x4
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 12.0;
                  final totalSpacingX = spacing * (_columns - 1);
                  final totalSpacingY = spacing * (_rows - 1);
                  final cellWidth = (constraints.maxWidth - totalSpacingX) / _columns;
                  final cellHeight =
                      (constraints.maxHeight - totalSpacingY) / _rows;
                  final size = cellWidth < cellHeight ? cellWidth : cellHeight;

                  return Center(
                    child: SizedBox(
                      width: size * _columns + totalSpacingX,
                      height: size * _rows + totalSpacingY,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columns,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                        ),
                        itemCount: _cards.length,
                        itemBuilder: (context, index) {
                          final card = _cards[index];
                          final faceColor = Colors.white;
                          final backColor = scheme.primary;

                          return GestureDetector(
                            onTap: () => _onCardTapped(card),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color:
                                    card.isFaceUp || card.isMatched ? faceColor : backColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (card.isFaceUp || card.isMatched)
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: card.isFaceUp || card.isMatched
                                    ? Icon(card.icon, size: 40, color: scheme.primary)
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: scheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

class _GameCard {
  final IconData icon;
  bool isFaceUp = false;
  bool isMatched = false;

  _GameCard(this.icon);
}

/// Un ticker súper simple para refrescar el cronómetro
class Ticker {
  Ticker(this.onTick);

  final void Function(Duration) onTick;
  bool _running = false;

  void start() {
    _running = true;
    _tick();
  }

  void dispose() => _running = false;

  Future<void> _tick() async {
    var elapsed = Duration.zero;
    while (_running) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!_running) break;
      elapsed += const Duration(seconds: 1);
      onTick(elapsed);
    }
  }
}
