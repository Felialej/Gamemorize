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
      theme: ThemeData(primarySwatch: Colors.blue),
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
  late List<_GameCard> _cards;
  _GameCard? _firstSelected;
  bool _allowFlip = true;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    const icons = [
      Icons.ac_unit,
      Icons.cake,
      Icons.flight,
      Icons.home,
      Icons.star,
      Icons.work,
    ];
    _cards = icons
        .expand((icon) => [
              _GameCard(icon),
              _GameCard(icon),
            ])
        .toList();
    _cards.shuffle();
  }

  void _onCardTapped(_GameCard card) {
    if (!_allowFlip || card.isFaceUp || card.isMatched) return;
    setState(() => card.isFaceUp = true);
    if (_firstSelected == null) {
      _firstSelected = card;
    } else {
      if (_firstSelected!.icon == card.icon) {
        setState(() {
          card.isMatched = true;
          _firstSelected!.isMatched = true;
          _firstSelected = null;
        });
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

  void _resetGame() {
    setState(() {
      _initializeCards();
      _firstSelected = null;
      _allowFlip = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamemorize'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Restart',
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return GestureDetector(
            onTap: () => _onCardTapped(card),
            child: Container(
              decoration: BoxDecoration(
                color: card.isFaceUp || card.isMatched
                    ? Colors.white
                    : Colors.blue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black54),
              ),
              child: Center(
                child: card.isFaceUp || card.isMatched
                    ? Icon(card.icon, size: 40, color: Colors.black87)
                    : const SizedBox.shrink(),
              ),
            ),
          );
        },
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
