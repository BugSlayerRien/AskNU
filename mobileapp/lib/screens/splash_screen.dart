import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  final Duration duration;

  const SplashScreen({super.key, required this.next, this.duration = const Duration(seconds: 2)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _startDelay();
  }

  Future<void> _startDelay() async {
    await Future.delayed(widget.duration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => widget.next));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.chat_bubble_rounded,
                    color: theme.colorScheme.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 18),
                Text('AskNU', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Gold or Blue, AskNU!', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
