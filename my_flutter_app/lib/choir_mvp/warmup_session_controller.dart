import 'package:flutter/foundation.dart';

import 'warmup_engine.dart';
import 'warmups_library.dart';
import 'warmups_models.dart';

class WarmupSessionController extends ChangeNotifier {
  WarmupSessionController({
    WarmupEngine? engine,
    List<Warmup>? library,
  }) : _engine = engine ?? WarmupEngine(),
       _library = library ?? WarmupsLibrary.buildAll() {
    _engine.addListener(_handleEngineUpdate);
  }

  final WarmupEngine _engine;
  final List<Warmup> _library;

  WarmupCategory? _selectedCategory;
  WarmupLevel? _selectedLevel;
  Warmup? _selectedWarmup;

  WarmupEngine get engine => _engine;
  List<Warmup> get allWarmups => _library;
  WarmupCategory? get selectedCategory => _selectedCategory;
  WarmupLevel? get selectedLevel => _selectedLevel;
  Warmup? get selectedWarmup => _selectedWarmup;

  List<WarmupCategory> get categories => WarmupCategory.values;
  List<WarmupLevel> get levels => WarmupLevel.values;

  List<Warmup> warmupsFor({
    required WarmupCategory category,
    required WarmupLevel level,
  }) {
    return WarmupsLibrary.filter(
      warmups: _library,
      category: category,
      level: level,
    );
  }

  void selectCategory(WarmupCategory category) {
    _selectedCategory = category;
    _selectedLevel = null;
    _selectedWarmup = null;
    notifyListeners();
  }

  void selectLevel(WarmupLevel level) {
    _selectedLevel = level;
    _selectedWarmup = null;
    notifyListeners();
  }

  void selectWarmup(Warmup warmup) {
    _selectedWarmup = warmup;
    _engine.loadWarmup(warmup);
    notifyListeners();
  }

  Future<void> initializeAudio() async {
    await _engine.initializeAudio();
  }

  @override
  void dispose() {
    _engine.removeListener(_handleEngineUpdate);
    _engine.dispose();
    super.dispose();
  }

  void _handleEngineUpdate() {
    notifyListeners();
  }
}

