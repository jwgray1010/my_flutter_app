import 'dart:async';

import 'package:flutter/material.dart';

import 'warmup_session_controller.dart';
import 'warmups_models.dart';

class WarmupCategoryScreen extends StatefulWidget {
  const WarmupCategoryScreen({super.key});

  @override
  State<WarmupCategoryScreen> createState() => _WarmupCategoryScreenState();
}

class _WarmupCategoryScreenState extends State<WarmupCategoryScreen> {
  late final WarmupSessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WarmupSessionController();
    unawaited(_controller.initializeAudio());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WarmupTokens.bg,
      appBar: AppBar(
        backgroundColor: _WarmupTokens.bg,
        title: const Text('Warmups'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '1) Choose Category',
              style: _WarmupTokens.title,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _controller.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final category = _controller.categories[index];
                  return _WarmupButton(
                    label: category.title,
                    onPressed: () {
                      _controller.selectCategory(category);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WarmupLevelScreen(
                            controller: _controller,
                            category: category,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WarmupLevelScreen extends StatelessWidget {
  const WarmupLevelScreen({
    super.key,
    required this.controller,
    required this.category,
  });

  final WarmupSessionController controller;
  final WarmupCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WarmupTokens.bg,
      appBar: AppBar(
        backgroundColor: _WarmupTokens.bg,
        title: const Text('Warmups'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              category.title,
              style: _WarmupTokens.title,
            ),
            const SizedBox(height: 10),
            const Text(
              '2) Choose Level',
              style: _WarmupTokens.subtitle,
            ),
            const SizedBox(height: 18),
            _WarmupButton(
              label: 'MIDDLE',
              height: 92,
              onPressed: () {
                controller.selectLevel(WarmupLevel.ms);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WarmupLibraryScreen(
                      controller: controller,
                      category: category,
                      level: WarmupLevel.ms,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _WarmupButton(
              label: 'LOWER HS',
              height: 92,
              onPressed: () {
                controller.selectLevel(WarmupLevel.lhs);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WarmupLibraryScreen(
                      controller: controller,
                      category: category,
                      level: WarmupLevel.lhs,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _WarmupButton(
              label: 'UPPER HS',
              height: 92,
              onPressed: () {
                controller.selectLevel(WarmupLevel.uhs);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WarmupLibraryScreen(
                      controller: controller,
                      category: category,
                      level: WarmupLevel.uhs,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WarmupLibraryScreen extends StatelessWidget {
  const WarmupLibraryScreen({
    super.key,
    required this.controller,
    required this.category,
    required this.level,
  });

  final WarmupSessionController controller;
  final WarmupCategory category;
  final WarmupLevel level;

  @override
  Widget build(BuildContext context) {
    final warmups = controller.warmupsFor(category: category, level: level);
    return Scaffold(
      backgroundColor: _WarmupTokens.bg,
      appBar: AppBar(
        backgroundColor: _WarmupTokens.bg,
        title: const Text('Warmups'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              category.title,
              style: _WarmupTokens.title,
            ),
            const SizedBox(height: 6),
            Text(
              '3) Choose Warmup - ${level.title}',
              style: _WarmupTokens.subtitle,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: warmups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final warmup = warmups[index];
                  return _WarmupCardButton(
                    title: warmup.title,
                    subtitle:
                        '${warmup.description}  •  ${warmup.defaultTempoBpm} BPM',
                    onPressed: () {
                      controller.selectWarmup(warmup);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WarmupPlayerScreen(controller: controller),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WarmupPlayerScreen extends StatefulWidget {
  const WarmupPlayerScreen({
    super.key,
    required this.controller,
  });

  final WarmupSessionController controller;

  @override
  State<WarmupPlayerScreen> createState() => _WarmupPlayerScreenState();
}

class _WarmupPlayerScreenState extends State<WarmupPlayerScreen> {
  @override
  void dispose() {
    widget.controller.engine.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final warmup = widget.controller.selectedWarmup;
        final engine = widget.controller.engine;
        final range = engine.selectedRangePreset;
        if (warmup == null || range == null) {
          return Scaffold(
            backgroundColor: _WarmupTokens.bg,
            appBar: AppBar(
              backgroundColor: _WarmupTokens.bg,
              title: const Text('Warmup Player'),
            ),
            body: const Center(
              child: Text(
                'No warmup selected.',
                style: _WarmupTokens.subtitle,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _WarmupTokens.bg,
          appBar: AppBar(
            backgroundColor: _WarmupTokens.bg,
            title: const Text('Warmup Player'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  warmup.title,
                  style: _WarmupTokens.title,
                ),
                const SizedBox(height: 6),
                Text(
                  warmup.description,
                  style: _WarmupTokens.subtitle,
                ),
                const SizedBox(height: 10),
                _StatusBlock(
                  keyLabel: engine.currentKeyLabel,
                  repeatLabel: '${engine.currentRepeat + 1}/${engine.repeatsPerKey}',
                  keysCompleted: engine.completedKeys,
                  texture: engine.texture.label,
                  statusLine: engine.statusLine,
                  audioStatus: engine.audioStatus,
                ),
                const SizedBox(height: 12),
                _WarmupButton(
                  label: engine.isPlaying ? 'PAUSE' : 'PLAY',
                  height: 110,
                  accent: true,
                  onPressed: () {
                    if (engine.isPlaying) {
                      engine.pause();
                    } else {
                      unawaited(engine.play());
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _WarmupButton(
                        label: 'TEMPO -',
                        height: 82,
                        onPressed: () => engine.adjustTempo(-5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WarmupButton(
                        label: 'TEMPO +',
                        height: 82,
                        onPressed: () => engine.adjustTempo(5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${engine.tempoBpm} BPM',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _WarmupTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _WarmupButton(
                  label: engine.demoOn ? 'DEMO ON' : 'DEMO OFF',
                  height: 74,
                  selected: engine.demoOn,
                  onPressed: () => engine.setDemoOn(!engine.demoOn),
                ),
                if (engine.demoOn) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _WarmupButton(
                          label: 'TREBLE',
                          height: 70,
                          selected: engine.demoVoice == WarmupDemoVoice.treble,
                          onPressed: () => engine.setDemoVoice(WarmupDemoVoice.treble),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WarmupButton(
                          label: 'BOY',
                          height: 70,
                          selected: engine.demoVoice == WarmupDemoVoice.boy,
                          onPressed: () => engine.setDemoVoice(WarmupDemoVoice.boy),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Text('TEXTURE', style: _WarmupTokens.sectionTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: WarmupTexture.values
                      .map(
                        (texture) => SizedBox(
                          width: 160,
                          child: _WarmupButton(
                            label: texture.label,
                            height: 66,
                            selected: engine.texture == texture,
                            onPressed: () => engine.setTexture(texture),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('STEP', style: _WarmupTokens.sectionTitle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WarmupButton(
                        label: '1/2',
                        height: 66,
                        selected: engine.stepMode == WarmupStepMode.halfStep,
                        onPressed: () => engine.setStepMode(WarmupStepMode.halfStep),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WarmupButton(
                        label: 'WHOLE',
                        height: 66,
                        selected: engine.stepMode == WarmupStepMode.wholeStep,
                        onPressed: () => engine.setStepMode(WarmupStepMode.wholeStep),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('RANGE', style: _WarmupTokens.sectionTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < warmup.rangePresets.length; i++)
                      SizedBox(
                        width: 140,
                        child: _WarmupButton(
                          label: warmup.rangePresets[i].name.toUpperCase(),
                          height: 62,
                          selected: i == engine.selectedRangePresetIndex,
                          onPressed: () => engine.setRangePresetIndex(i),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('REPEATS PER KEY', style: _WarmupTokens.sectionTitle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final value in [1, 2, 3]) ...[
                      Expanded(
                        child: _WarmupButton(
                          label: '$value',
                          height: 62,
                          selected: engine.repeatsPerKey == value,
                          onPressed: () => engine.setRepeatsPerKey(value),
                        ),
                      ),
                      if (value != 3) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.keyLabel,
    required this.repeatLabel,
    required this.keysCompleted,
    required this.texture,
    required this.statusLine,
    this.audioStatus,
  });

  final String keyLabel;
  final String repeatLabel;
  final int keysCompleted;
  final String texture;
  final String statusLine;
  final String? audioStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _WarmupTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WarmupTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Tag(label: 'KEY $keyLabel'),
              _Tag(label: 'REP $repeatLabel'),
              _Tag(label: 'TEXTURE $texture'),
              _Tag(label: 'KEYS $keysCompleted'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLine,
            style: _WarmupTokens.subtitle,
          ),
          if (audioStatus != null) ...[
            const SizedBox(height: 4),
            Text(
              audioStatus!,
              style: const TextStyle(
                color: _WarmupTokens.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _WarmupTokens.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _WarmupTokens.textPrimary,
        ),
      ),
    );
  }
}

class _WarmupCardButton extends StatelessWidget {
  const _WarmupCardButton({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _WarmupTokens.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _WarmupTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: _WarmupTokens.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarmupButton extends StatelessWidget {
  const _WarmupButton({
    required this.label,
    required this.onPressed,
    this.height = 74,
    this.accent = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = accent || selected ? _WarmupTokens.accent : _WarmupTokens.card;
    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: _WarmupTokens.textPrimary,
          disabledBackgroundColor: _WarmupTokens.card.withOpacity(0.45),
          disabledForegroundColor: _WarmupTokens.textSecondary,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _WarmupTokens.border),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _WarmupTokens {
  static const bg = Color(0xFF15181D);
  static const card = Color(0xFF1E232B);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color.fromRGBO(255, 255, 255, 0.70);
  static const border = Color.fromRGBO(255, 255, 255, 0.12);
  static const accent = Color(0xFF6E5BFF);

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
}

