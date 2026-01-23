import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FerreteriaCalcApp());
}

enum UnitKind { m2, ft2 }
enum CalcCategory { ceramica, porcelanato, cieloFalso }

class OptionItem {
  final String label;
  final double piezasPorM2;
  const OptionItem(this.label, this.piezasPorM2);
}

class ShortcutItem {
  final String titulo;
  final List<String> alias;
  final List<ShortcutLine> lineas;
  const ShortcutItem({
    required this.titulo,
    required this.alias,
    required this.lineas,
  });
}

class ShortcutLine {
  final String label;
  final String buscarComo;
  final String? nota;
  const ShortcutLine({
    required this.label,
    required this.buscarComo,
    this.nota,
  });
}

class SuggestionItem {
  final String titulo;
  final List<String> bullets;
  const SuggestionItem({
    required this.titulo,
    required this.bullets,
  });
}

class FerreteriaCalcApp extends StatelessWidget {
  const FerreteriaCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ferretería',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      CalculadorasScreen(),
      AtajosScreen(),
      SugerenciasScreen(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_rounded),
            label: 'Cálculos',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Atajos',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline_rounded),
            label: 'Sugerencias',
          ),
        ],
      ),
    );
  }
}

class CalculadorasScreen extends StatefulWidget {
  const CalculadorasScreen({super.key});

  @override
  State<CalculadorasScreen> createState() => _CalculadorasScreenState();
}

class _CalculadorasScreenState extends State<CalculadorasScreen> {
  final areaCtrl = TextEditingController();
  final focus = FocusNode();

  UnitKind unit = UnitKind.m2;
  CalcCategory category = CalcCategory.ceramica;

  OptionItem? selected;

  double? exacto;
  int? redondeado;
  String? error;

  static const _ft2ToM2 = 0.09290304;

  static const ceramicaOptions = <OptionItem>[
    OptionItem('Cerámica 1.20 × 0.60', 1.39),
    OptionItem('Cerámica 45 × 45', 4.94),
    OptionItem('Azulejo 25 × 33', 12.0),
    OptionItem('Cerámica 33 × 33', 9.0),
    OptionItem('Cerámica 29 × 49.5', 7.58),
    OptionItem('Cerámica 20 × 60', 8.33),
  ];

  static const porcelanatoOptions = <OptionItem>[
    OptionItem('Porcelanato 60 × 120', 1.39),
    OptionItem('Porcelanato 60 × 60', 2.77),
  ];

  static const cieloFalsoOptions = <OptionItem>[
    OptionItem('Tablilla 5.95 × 0.25 (1 m² = 1.49 piezas)', 1.49),
    OptionItem('Tablilla 0.20 × 5.95 (1 pieza = 1.19 m²)', 1 / 1.19),
  ];

  List<OptionItem> get options {
    switch (category) {
      case CalcCategory.ceramica:
        return ceramicaOptions;
      case CalcCategory.porcelanato:
        return porcelanatoOptions;
      case CalcCategory.cieloFalso:
        return cieloFalsoOptions;
    }
  }

  @override
  void initState() {
    super.initState();
    selected = options.first;
  }

  @override
  void dispose() {
    areaCtrl.dispose();
    focus.dispose();
    super.dispose();
  }

  void onChangeCategory(CalcCategory? v) {
    if (v == null) return;
    setState(() {
      category = v;
      selected = options.first;
      exacto = null;
      redondeado = null;
      error = null;
    });
  }

  void onChangeUnit(UnitKind? v) {
    if (v == null) return;
    setState(() {
      unit = v;
      exacto = null;
      redondeado = null;
      error = null;
    });
  }

  void calcular() {
    final raw = areaCtrl.text.trim().replaceAll(',', '.');
    final area = double.tryParse(raw);

    if (area == null || area <= 0) {
      setState(() {
        error = 'Ingresá un área válida.';
        exacto = null;
        redondeado = null;
      });
      return;
    }

    final opt = selected;
    if (opt == null) {
      setState(() {
        error = 'Seleccioná una medida.';
        exacto = null;
        redondeado = null;
      });
      return;
    }

    final areaM2 = unit == UnitKind.m2 ? area : area * _ft2ToM2;
    final piezas = areaM2 * opt.piezasPorM2;
    final piezasEnteras = piezas.ceil();

    setState(() {
      error = null;
      exacto = piezas;
      redondeado = piezasEnteras;
    });

    FocusScope.of(context).unfocus();
  }

  void limpiar() {
    setState(() {
      areaCtrl.clear();
      unit = UnitKind.m2;
      category = CalcCategory.ceramica;
      selected = options.first;
      exacto = null;
      redondeado = null;
      error = null;
    });
    FocusScope.of(context).requestFocus(focus);
  }

  String fmt2(double v) => v.toStringAsFixed(2);
  String unitLabel(UnitKind u) => u == UnitKind.m2 ? 'm²' : 'ft²';

  String categoryLabel(CalcCategory c) {
    switch (c) {
      case CalcCategory.ceramica:
        return 'Cerámica';
      case CalcCategory.porcelanato:
        return 'Porcelanato';
      case CalcCategory.cieloFalso:
        return 'Cielo falso';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                cs.primaryContainer,
                                cs.primaryContainer.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.construction_rounded, color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Calculadora Ferretería',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cerámica, porcelanato y cielo falso',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<UnitKind>(
                                        value: unit,
                                        items: UnitKind.values
                                            .map(
                                              (e) => DropdownMenuItem<UnitKind>(
                                                value: e,
                                                child: Text(unitLabel(e)),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: onChangeUnit,
                                        decoration: InputDecoration(
                                          labelText: 'Unidad',
                                          prefixIcon: const Icon(Icons.straighten_rounded),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonFormField<CalcCategory>(
                                        value: category,
                                        items: CalcCategory.values
                                            .map(
                                              (e) => DropdownMenuItem<CalcCategory>(
                                                value: e,
                                                child: Text(categoryLabel(e)),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: onChangeCategory,
                                        decoration: InputDecoration(
                                          labelText: 'Tipo',
                                          prefixIcon: const Icon(Icons.category_rounded),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: areaCtrl,
                                  focusNode: focus,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => calcular(),
                                  decoration: InputDecoration(
                                    labelText: 'Área (${unitLabel(unit)})',
                                    hintText: unit == UnitKind.m2 ? 'Ej: 12.5' : 'Ej: 150',
                                    prefixIcon: const Icon(Icons.square_foot_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<OptionItem>(
                                  value: selected,
                                  items: options
                                      .map(
                                        (e) => DropdownMenuItem<OptionItem>(
                                          value: e,
                                          child: Text(e.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selected = v;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Medida',
                                    prefixIcon: const Icon(Icons.grid_on_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: calcular,
                                        icon: const Icon(Icons.calculate_rounded),
                                        label: const Text('Calcular'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton.filledTonal(
                                      onPressed: limpiar,
                                      icon: const Icon(Icons.refresh_rounded),
                                      tooltip: 'Limpiar',
                                    ),
                                  ],
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: cs.errorContainer.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline_rounded, color: cs.onErrorContainer),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            error!,
                                            style: TextStyle(color: cs.onErrorContainer),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Resultado',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ResultRow(
                                  title: 'Piezas (redondeado)',
                                  value: redondeado == null ? '—' : '$redondeado',
                                  big: true,
                                ),
                                const SizedBox(height: 8),
                                _ResultRow(
                                  title: 'Cálculo exacto',
                                  value: exacto == null ? '—' : fmt2(exacto!),
                                ),
                                const SizedBox(height: 8),
                                _ResultRow(
                                  title: 'Factor (piezas por 1 m²)',
                                  value: selected == null ? '—' : fmt2(selected!.piezasPorM2),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Se redondea hacia arriba porque se vende por pieza.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Si usás ft², internamente se convierte a m².',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Ferretería • Cálculo rápido',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String title;
  final String value;
  final bool big;

  const _ResultRow({
    required this.title,
    required this.value,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: big ? 20 : 15,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class AtajosScreen extends StatefulWidget {
  const AtajosScreen({super.key});

  @override
  State<AtajosScreen> createState() => _AtajosScreenState();
}

class _AtajosScreenState extends State<AtajosScreen> {
  final q = TextEditingController();

  static const items = <ShortcutItem>[
    ShortcutItem(
      titulo: 'Aluzinc',
      alias: ['aluzinc', 'lamina aluzinc', 'zinc', 'aluzinc 26', 'aluzinc 28', 'calibre 26', 'calibre 28', '0.40', '0.35', '0.34', '0.30'],
      lineas: [
        ShortcutLine(label: 'Calibre 26 legítimo (0.40)', buscarComo: '0.40'),
        ShortcutLine(label: 'Calibre 26 intermedio (0.34)', buscarComo: '0.34'),
        ShortcutLine(label: 'Calibre 26 intermedio (0.35)', buscarComo: '0.35'),
        ShortcutLine(label: 'Calibre 28 (0.30)', buscarComo: '0.30'),
        ShortcutLine(
          label: 'Tornillo recomendado',
          buscarComo: '1/4 punta broca / punta fina / madera',
          nota: 'Canaleta: broca. Madera: punta fina/madera.',
        ),
      ],
    ),
    ShortcutItem(
      titulo: 'Canaleta',
      alias: ['canaleta', 'canaleta legitima', 'canaleta intermedia', 'canaleta milimetrica', '1.20', '1.5', '1.10', '1.0', '0.80', '0.90'],
      lineas: [
        ShortcutLine(label: '1.20 legítima', buscarComo: '1.20'),
        ShortcutLine(label: '1.50 legítima', buscarComo: '1.5'),
        ShortcutLine(label: '1.00 intermedia', buscarComo: '1.0'),
        ShortcutLine(label: '1.10 intermedia', buscarComo: '1.10'),
        ShortcutLine(label: '0.80 milimétrica', buscarComo: '0.80'),
        ShortcutLine(label: '0.90 milimétrica', buscarComo: '0.90'),
      ],
    ),
    ShortcutItem(
      titulo: 'Varilla',
      alias: ['varilla', 'varilla 1/4', 'varilla 3/8', 'varilla 1/2', 'corrugada', 'lisa', '5.5', '3/8', '11'],
      lineas: [
        ShortcutLine(label: 'Varilla 1/4', buscarComo: '5.5 varilla'),
        ShortcutLine(
          label: 'Varilla 3/8',
          buscarComo: '3/8',
          nota: 'Hay lisa y corrugada. Intermedia 8.5 a 8.0. Milimétrica 7.5 a 7.2.',
        ),
        ShortcutLine(
          label: 'Varilla 1/2 (intermedia)',
          buscarComo: '11',
          nota: 'Hay lisa y corrugada. Corrugada: legítima e intermedia.',
        ),
      ],
    ),
    ShortcutItem(
      titulo: 'Tubería PVC',
      alias: ['pvc', 'tuberia pvc', 'sdr26', 'sdr41', 'sdr64', 'potable', 'inyectado', 'drenaje'],
      lineas: [
        ShortcutLine(label: 'SDR26 (potable)', buscarComo: 'SDR26'),
        ShortcutLine(label: 'SDR41 (inyectado)', buscarComo: 'SDR41'),
        ShortcutLine(label: 'SDR64 (drenaje)', buscarComo: 'SDR64'),
      ],
    ),
    ShortcutItem(
      titulo: 'Cables',
      alias: ['cable', 'cables', 'awg', '12awg', 'cable 12', '12 awg'],
      lineas: [
        ShortcutLine(label: 'Cable 12 AWG', buscarComo: '12awg'),
      ],
    ),
    ShortcutItem(
      titulo: 'Conduit (tubo gris)',
      alias: ['conduit', 'condulit', 'tubo pvc gris', 'c-20', 'tubo gris'],
      lineas: [
        ShortcutLine(label: 'Conduit', buscarComo: 'tubo PVC gris C-20 condulit'),
      ],
    ),
    ShortcutItem(
      titulo: 'Manguera / Tubo Durmanflex',
      alias: ['durmanflex', 'duranflex', 'duelanflex', 'manguera durman', 'tubo durman', 'durman fle'],
      lineas: [
        ShortcutLine(label: 'Durmanflex', buscarComo: 'durman fle'),
      ],
    ),
    ShortcutItem(
      titulo: 'Pared (curado)',
      alias: ['curado', 'pared', 'dias curado', '30 dias'],
      lineas: [
        ShortcutLine(label: 'Curado mínimo', buscarComo: '30 días'),
      ],
    ),
    ShortcutItem(
      titulo: 'Colorámica (códigos)',
      alias: ['coloramica', 'y81', 'y82', 'agua', 'aceite'],
      lineas: [
        ShortcutLine(label: 'Y81', buscarComo: 'agua'),
        ShortcutLine(label: 'Y82', buscarComo: 'aceite'),
      ],
    ),
    ShortcutItem(
      titulo: 'Cemento',
      alias: ['cemento', 'bijao', 'sureno', 'lempira'],
      lineas: [
        ShortcutLine(label: 'Marcas', buscarComo: 'Bijao / Sureño / Lempira'),
      ],
    ),
    ShortcutItem(
      titulo: 'Clavo acero',
      alias: ['clavo', 'clavo acero', 'fa', 'clavo lb', 'c/c'],
      lineas: [
        ShortcutLine(label: 'Tipos', buscarComo: 'FA / Clavo lb / C/C'),
      ],
    ),
  ];

  List<ShortcutItem> get filtered {
    final s = q.text.trim().toLowerCase();
    if (s.isEmpty) return items;

    bool matchLine(ShortcutLine ln) {
      final a = ln.label.toLowerCase();
      final b = ln.buscarComo.toLowerCase();
      final c = (ln.nota ?? '').toLowerCase();
      return a.contains(s) || b.contains(s) || c.contains(s);
    }

    bool matchItem(ShortcutItem it) {
      final t = it.titulo.toLowerCase();
      final al = it.alias.any((x) => x.toLowerCase().contains(s));
      final ln = it.lineas.any(matchLine);
      return t.contains(s) || al || ln;
    }

    return items.where(matchItem).toList();
  }

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atajos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            children: [
              TextField(
                controller: q,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Busqueda',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          'No hay resultados.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final it = list[i];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          it.titulo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.search_rounded,
                                        color: cs.primary.withValues(alpha: 0.8),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ...it.lineas.map((ln) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    ln.label,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w900,
                                                      color: cs.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Buscar como: ${ln.buscarComo}',
                                                    style: TextStyle(color: cs.onSurfaceVariant),
                                                  ),
                                                  if (ln.nota != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      ln.nota!,
                                                      style: TextStyle(color: cs.onSurfaceVariant),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton.filledTonal(
                                              onPressed: () => copy(ln.buscarComo),
                                              icon: const Icon(Icons.copy_rounded),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SugerenciasScreen extends StatelessWidget {
  const SugerenciasScreen({super.key});

  static const suggestions = <SuggestionItem>[
    SuggestionItem(
      titulo: 'Inodoro',
      bullets: [
        'Surtidor para inodoro: B16 o C40 (cambia el material).',
        'Válvula de control: económica “válvula control recta”; otra: ip-110 o ip-108.',
        'Brida: depende si la tubería es de 3" o 4".',
      ],
    ),
    SuggestionItem(
      titulo: 'Lavamanos',
      bullets: [
        'Hay trampa para lavamanos y para lavatrastos.',
        'Lavamanos: con pedestal o solo.',
        'Ofrecer: surtidor + válvula de control.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerencias'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      cs.tertiaryContainer,
                      cs.tertiaryContainer.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.lightbulb_outline_rounded, color: cs.tertiary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checklist rápido',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Para no olvidar accesorios al vender',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onTertiaryContainer.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...suggestions.map((sug) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sug.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.checklist_rounded,
                              color: cs.tertiary.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...sug.bullets.map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Icon(Icons.circle, size: 8, color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
