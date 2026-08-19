import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _subTab = 0; // 0 = Log, 1 = Presets, 2 = History

  bool _loading = true;
  String? _error;

  int _targetCal = 1800;
  double _targetProtein = 80;
  List<Map<String, dynamic>> _presets = [];
  List<Map<String, dynamic>> _todayFoods = [];
  List<Map<String, dynamic>> _allFoods = []; // for History, grouped client-side

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final targets = await ApiService.getTargets();
      final presets = await ApiService.getPresets();
      final todayFoods = await ApiService.getFoods(date: ApiService.todayString());
      final allFoods = await ApiService.getFoods();
      setState(() {
        _targetCal = targets['target_calories'];
        _targetProtein = (targets['target_protein'] as num).toDouble();
        _presets = presets;
        _todayFoods = todayFoods;
        _allFoods = allFoods;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        title: Text('Nutrition', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadEverything, colors: colors)
              : Column(
                  children: [
                    _SubTabBar(
                      selected: _subTab,
                      onChanged: (i) => setState(() => _subTab = i),
                      colors: colors,
                    ),
                    Expanded(child: _buildSubTab(colors)),
                  ],
                ),
    );
  }

  Widget _buildSubTab(AppColors colors) {
    switch (_subTab) {
      case 0:
        return _LogTab(
          colors: colors,
          targetCal: _targetCal,
          targetProtein: _targetProtein,
          presets: _presets,
          todayFoods: _todayFoods,
          onTargetsSaved: (cal, protein) async {
            await ApiService.setTargets(calories: cal, protein: protein);
            setState(() {
              _targetCal = cal;
              _targetProtein = protein;
            });
          },
          onFoodAdded: (name, cal, protein, grams) async {
            await ApiService.addFood(
              date: ApiService.todayString(),
              name: name,
              calories: cal,
              protein: protein,
              grams: grams,
            );
            await _loadEverything();
          },
          onFoodUpdated: (id, name, cal, protein, grams) async {
            await ApiService.updateFood(id: id, name: name, calories: cal, protein: protein, grams: grams);
            await _loadEverything();
          },
          onFoodDeleted: (id) async {
            await ApiService.deleteFood(id);
            await _loadEverything();
          },
        );
      case 1:
        return _PresetsTab(
          colors: colors,
          presets: _presets,
          onPresetAdded: (name, cal, protein, baseGrams) async {
            await ApiService.addPreset(name: name, calories: cal, protein: protein, baseGrams: baseGrams);
            await _loadEverything();
          },
        );
      case 2:
        return _HistoryTab(colors: colors, allFoods: _allFoods);
      default:
        return const SizedBox();
    }
  }
}

// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final AppColors colors;
  const _ErrorView({required this.error, required this.onRetry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.wifi_off, size: 48, color: colors.textMuted),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Could not reach the server.\n$error', textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted)),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.onAccent),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _SubTabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final AppColors colors;
  const _SubTabBar({required this.selected, required this.onChanged, required this.colors});

  static const _labels = ['Log', 'Presets', 'History'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final isSelected = i == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? colors.accent : colors.border),
                  color: isSelected ? colors.accent.withOpacity(0.16) : Colors.transparent,
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(color: isSelected ? colors.accent : colors.textMuted, fontSize: 12),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final AppColors colors;
  const _Card({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// LOG TAB
// ---------------------------------------------------------------------------

class _LogTab extends StatefulWidget {
  final AppColors colors;
  final int targetCal;
  final double targetProtein;
  final List<Map<String, dynamic>> presets;
  final List<Map<String, dynamic>> todayFoods;
  final Future<void> Function(int cal, double protein) onTargetsSaved;
  final Future<void> Function(String name, int cal, double protein, double? grams) onFoodAdded;
  final Future<void> Function(int id, String name, int cal, double protein, double? grams) onFoodUpdated;
  final Future<void> Function(int id) onFoodDeleted;

  const _LogTab({
    required this.colors,
    required this.targetCal,
    required this.targetProtein,
    required this.presets,
    required this.todayFoods,
    required this.onTargetsSaved,
    required this.onFoodAdded,
    required this.onFoodUpdated,
    required this.onFoodDeleted,
  });

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  bool _editingTarget = false;
  final _targetCalCtrl = TextEditingController();
  final _targetProteinCtrl = TextEditingController();

  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  bool _saving = false;

  // the preset matching whatever's currently typed in the name field, if any
  Map<String, dynamic>? get _matchedPreset {
    final typed = _nameCtrl.text.trim().toLowerCase();
    if (typed.isEmpty) return null;
    final matches = widget.presets.where((p) => (p['name'] as String).toLowerCase() == typed);
    return matches.isEmpty ? null : matches.first;
  }

  void _recalculateFromGrams() {
    final preset = _matchedPreset;
    if (preset == null) return;
    final baseGrams = (preset['base_grams'] as num).toDouble();
    final enteredGrams = double.tryParse(_gramsCtrl.text);

    if (enteredGrams == null || enteredGrams <= 0) {
      // no grams entered - just show the preset's base values
      _calCtrl.text = '${preset['calories']}';
      _proteinCtrl.text = '${preset['protein']}';
      return;
    }
    final ratio = enteredGrams / baseGrams;
    _calCtrl.text = (preset['calories'] as num).toDouble().mul(ratio).round().toString();
    _proteinCtrl.text = ((preset['protein'] as num).toDouble() * ratio).toStringAsFixed(1);
  }

  Future<void> _addFood() async {
    final name = _nameCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text);
    final protein = double.tryParse(_proteinCtrl.text);
    final grams = double.tryParse(_gramsCtrl.text); // optional - stays null if blank
    if (name.isEmpty || cal == null || protein == null) return;

    setState(() => _saving = true);
    await widget.onFoodAdded(name, cal, protein, grams);
    _nameCtrl.clear();
    _gramsCtrl.clear();
    _calCtrl.clear();
    _proteinCtrl.clear();
    setState(() => _saving = false);
  }

  Future<void> _editEntry(Map<String, dynamic> food) async {
    final nameCtrl = TextEditingController(text: food['name']);
    final calCtrl = TextEditingController(text: '${food['calories']}');
    final proteinCtrl = TextEditingController(text: '${food['protein']}');
    final gramsCtrl = TextEditingController(text: food['grams'] != null ? '${food['grams']}' : '');
    final colors = widget.colors;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Edit entry', style: TextStyle(color: colors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories')),
            TextField(controller: proteinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)')),
            TextField(controller: gramsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grams (optional)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.onAccent),
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (action == 'delete') {
      await widget.onFoodDeleted(food['id'] as int);
    } else if (action == 'save') {
      await widget.onFoodUpdated(
        food['id'] as int,
        nameCtrl.text.trim(),
        int.tryParse(calCtrl.text) ?? food['calories'],
        double.tryParse(proteinCtrl.text) ?? food['protein'],
        gramsCtrl.text.trim().isEmpty ? null : double.tryParse(gramsCtrl.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    // grams is informational only - never added into these totals
    final totalCal = widget.todayFoods.fold<int>(0, (sum, f) => sum + (f['calories'] as int));
    final totalProtein = widget.todayFoods.fold<double>(0, (sum, f) => sum + (f['protein'] as num).toDouble());
    final remainingCal = widget.targetCal - totalCal;
    final remainingProtein = widget.targetProtein - totalProtein;
    final matchedPreset = _matchedPreset;

    return ListView(
      children: [
        _Card(
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily target', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  GestureDetector(
                    onTap: () {
                      if (!_editingTarget) {
                        _targetCalCtrl.text = '${widget.targetCal}';
                        _targetProteinCtrl.text = '${widget.targetProtein}';
                      }
                      setState(() => _editingTarget = !_editingTarget);
                    },
                    child: Text(_editingTarget ? 'Done' : 'Edit', style: TextStyle(color: colors.accent, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_editingTarget)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _targetCalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Target cal', isDense: true),
                        onSubmitted: (_) => _saveTargets(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _targetProteinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Target protein', isDense: true),
                        onSubmitted: (_) => _saveTargets(),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RemainingStat(value: '$remainingCal', label: 'kcal remaining', colors: colors),
                    _RemainingStat(value: '${remainingProtein.toStringAsFixed(0)}g', label: 'protein remaining', colors: colors, alignRight: true),
                  ],
                ),
            ],
          ),
        ),
        _Card(
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a food', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return const Iterable<String>.empty();
                  return widget.presets
                      .map((p) => p['name'] as String)
                      .where((name) => name.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (name) {
                  _nameCtrl.text = name;
                  setState(() => _recalculateFromGrams());
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  controller.addListener(() {
                    _nameCtrl.text = controller.text;
                    setState(() => _recalculateFromGrams());
                  });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(hintText: 'Food name', isDense: true),
                  );
                },
              ),
              if (matchedPreset != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Preset: ${matchedPreset['base_grams']}g = ${matchedPreset['calories']} kcal, ${matchedPreset['protein']}g protein',
                  style: TextStyle(color: colors.accent, fontSize: 10),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _gramsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Grams (optional)', isDense: true),
                onChanged: (_) => setState(_recalculateFromGrams),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _calCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Calories', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Protein (g)', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.onAccent),
                  onPressed: _saving ? null : _addFood,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(_saving ? 'Adding...' : 'Add'),
                ),
              ),
            ],
          ),
        ),
        _Card(
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text('Tap an entry to edit or delete it', style: TextStyle(color: colors.textMuted, fontSize: 10)),
              const SizedBox(height: 6),
              ...widget.todayFoods.map((f) => InkWell(
                    onTap: () => _editEntry(f),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            f['grams'] != null ? '${f['name']} (${f['grams']}g)' : '${f['name']}',
                            style: TextStyle(color: colors.text, fontSize: 12),
                          ),
                          Text('${f['calories']} kcal · ${f['protein']}g', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  )),
              Divider(color: colors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(color: colors.text, fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('$totalCal kcal · ${totalProtein.toStringAsFixed(0)}g', style: TextStyle(color: colors.accent, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveTargets() async {
    final cal = int.tryParse(_targetCalCtrl.text);
    final protein = double.tryParse(_targetProteinCtrl.text);
    if (cal == null || protein == null) return;
    await widget.onTargetsSaved(cal, protein);
    setState(() => _editingTarget = false);
  }
}

extension on double {
  double mul(double factor) => this * factor;
}

class _RemainingStat extends StatelessWidget {
  final String value;
  final String label;
  final AppColors colors;
  final bool alignRight;
  const _RemainingStat({required this.value, required this.label, required this.colors, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: colors.accent, fontSize: 22, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PRESETS TAB
// ---------------------------------------------------------------------------

class _PresetsTab extends StatefulWidget {
  final AppColors colors;
  final List<Map<String, dynamic>> presets;
  final Future<void> Function(String name, int cal, double protein, double baseGrams) onPresetAdded;
  const _PresetsTab({required this.colors, required this.presets, required this.onPresetAdded});

  @override
  State<_PresetsTab> createState() => _PresetsTabState();
}

class _PresetsTabState extends State<_PresetsTab> {
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text);
    final protein = double.tryParse(_proteinCtrl.text);
    final baseGrams = double.tryParse(_gramsCtrl.text) ?? 100;
    if (name.isEmpty || cal == null || protein == null) return;
    setState(() => _saving = true);
    await widget.onPresetAdded(name, cal, protein, baseGrams);
    _nameCtrl.clear();
    _gramsCtrl.text = '100';
    _calCtrl.clear();
    _proteinCtrl.clear();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return ListView(
      children: [
        _Card(
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Save a new preset', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                'Set the gram amount your calories/protein are for - e.g. 100g of yoghurt = 100 kcal',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 8),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Food name', isDense: true)),
              const SizedBox(height: 8),
              TextField(
                controller: _gramsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Grams this is based on (e.g. 100)', isDense: true),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Calories', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _proteinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Protein (g)', isDense: true))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.onAccent),
                  onPressed: _saving ? null : _add,
                  child: Text(_saving ? 'Saving...' : 'Save preset'),
                ),
              ),
            ],
          ),
        ),
        _Card(
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved items', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              if (widget.presets.isEmpty)
                Text('No presets yet', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              ...widget.presets.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p['name']}', style: TextStyle(color: colors.text, fontSize: 12)),
                        Text(
                          '${p['base_grams']}g = ${p['calories']} kcal · ${p['protein']}g',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HISTORY TAB
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  final AppColors colors;
  final List<Map<String, dynamic>> allFoods;
  const _HistoryTab({required this.colors, required this.allFoods});

  @override
  Widget build(BuildContext context) {
    // group by date, sum calories/protein (grams intentionally excluded from this sum)
    final Map<String, Map<String, num>> byDate = {};
    for (final f in allFoods) {
      final date = f['date'] as String;
      byDate.putIfAbsent(date, () => {'calories': 0, 'protein': 0});
      byDate[date]!['calories'] = byDate[date]!['calories']! + (f['calories'] as int);
      byDate[date]!['protein'] = byDate[date]!['protein']! + (f['protein'] as num);
    }
    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a)); // newest first

    if (dates.isEmpty) {
      return Center(child: Text('No history yet', style: TextStyle(color: colors.textMuted)));
    }

    return ListView(
      children: dates
          .map((date) => _Card(
                colors: colors,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date, style: TextStyle(color: colors.text, fontSize: 12)),
                    Text(
                      '${byDate[date]!['calories']} kcal · ${byDate[date]!['protein']}g',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}