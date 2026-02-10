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
  final int? piezasPorCaja;
  final double? m2PorCaja;
  const OptionItem(
    this.label,
    this.piezasPorM2, {
    this.piezasPorCaja,
    this.m2PorCaja,
  });
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
      title: 'Ferretería Santa Fe',
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
    OptionItem('Azulejo 25 × 33', 12.0, piezasPorCaja: 18, m2PorCaja: 1.5),
    OptionItem('Cerámica 33 × 33', 9.0, piezasPorCaja: 12, m2PorCaja: 1.33),
    OptionItem('Cerámica 45 × 45', 4.94, piezasPorCaja: 7, m2PorCaja: 1.41),
    OptionItem('Cerámica 20 × 60', 8.33, piezasPorCaja: 9, m2PorCaja: 1.08),
    OptionItem('Cerámica 60 × 60', 2.77, piezasPorCaja: 4, m2PorCaja: 1.44),
    OptionItem('Cerámica 29 × 49.5', 7.58, piezasPorCaja: 11, m2PorCaja: 1.45),
    OptionItem('Cerámica Unicesa 33 × 33', 9.0, piezasPorCaja: 18, m2PorCaja: 2.0),
  ];

  static const porcelanatoOptions = <OptionItem>[
    OptionItem('Porcelanato 60 × 60', 2.77, piezasPorCaja: 4),
    OptionItem('Porcelanato 60 × 120', 1.39, piezasPorCaja: 2),
    OptionItem('Porcelanato 20 × 120', 4.16, piezasPorCaja: 5),
    OptionItem('Porcelanato 1.20 × 1.80', 0.46),
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

  String fmtCaja(double v) {
    final s = v.toStringAsFixed(2);
    if (s.endsWith('00')) return v.toStringAsFixed(0);
    if (s.endsWith('0')) return v.toStringAsFixed(1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final opt = selected;

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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: cs.primary.withValues(alpha: 0.10),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) {
                                      return Icon(Icons.store_rounded, color: cs.primary, size: 28);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ferretería Santa Fe',
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
                                  title: 'Piezas por 1 m²',
                                  value: opt == null ? '—' : fmt2(opt.piezasPorM2),
                                ),
                                const SizedBox(height: 8),
                                _ResultRow(
                                  title: 'Piezas por caja',
                                  value: opt?.piezasPorCaja == null ? '—' : '${opt!.piezasPorCaja}',
                                ),
                                const SizedBox(height: 8),
                                _ResultRow(
                                  title: 'm² por caja',
                                  value: opt?.m2PorCaja == null ? '—' : fmtCaja(opt!.m2PorCaja!),
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
                          'Ferretería Santa Fe',
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
      titulo: 'Varilla',
      alias: [
        'varilla',
        'corrugada',
        'lisa',
        'entorchada',
        'roscada',
        'grado 40',
        '3/8',
        '1/2',
        '5/8',
        '3/4',
        '1',
        '9.5',
        '13',
        '15.9',
        '19.1',
        '25.4',
        '12',
        '8.5',
        '8.0',
        '7.5',
        '7.2',
        '5.5'
      ],
      lineas: [
        ShortcutLine(
          label: 'Varilla corrugada legítima',
          buscarComo: '3/8 (9.5 mm) • 1/2 (13 mm) • 5/8 (15.9 mm) • 3/4 (19.1 mm) • 1" (25.4 mm)',
        ),
        ShortcutLine(
          label: 'Varilla corrugada intermedia',
          buscarComo: '1/2 (12 mm) • 3/8 (8.5 mm)',
        ),
        ShortcutLine(
          label: 'Varilla corrugada milimétrica',
          buscarComo: '3/8 (8.0 mm) • 3/8 (7.5 mm) • 3/8 (7.2 mm)',
        ),
        ShortcutLine(
          label: 'Varilla lisa legítima',
          buscarComo: '5/8" • 3/4" • 1/2" • 3/8" • 1/4" (5.5 mm)',
        ),
        ShortcutLine(
          label: 'Varilla entorchada',
          buscarComo: '1/2" • 3/8"',
        ),
        ShortcutLine(
          label: 'Varilla roscada (pernos)',
          buscarComo: '1/2" • 3/8" • 1/4" • 5/16"',
        ),
        ShortcutLine(
          label: 'Grado',
          buscarComo: 'Grado 40',
          nota: 'Grado 60 solo por pedido especial.',
        ),
      ],
    ),
    ShortcutItem(
      titulo: 'Aluzinc',
      alias: [
        'aluzinc',
        
      ],
      lineas: [
        ShortcutLine(label: 'Calibre 28 (intermedio)', buscarComo: '0.30'),
        ShortcutLine(label: 'Calibre 26 (legítimo)', buscarComo: '0.40'),
        ShortcutLine(label: 'Calibre 26 (intermedio)', buscarComo: '0.34'),
        ShortcutLine(label: 'Calibre 26 (intermedio)', buscarComo: '0.35'),
        ShortcutLine(label: 'Colores', buscarComo: 'Natural • Rojo • Rojo teja'),
        ShortcutLine(
          label: 'Capotes (ofrecer)',
          buscarComo: 'Capote Natural • Capote Rojo',
          nota: 'Medida: 8 pies (2.43 m).',
        ),
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
    ShortcutLine(
          label: '2x4 (clasificación)',
          buscarComo: '0.80 Milimétrica • 0.90 Intermedia • 1.00 Intermedia • 1.10 Intermedia • 1.20 Intermedia • 1.50 Legítima',
        ),
        ShortcutLine(
          label: '2x6 (clasificación)',
          buscarComo: '1.00 Intermedia • 1.10 Intermedia • 1.20 Intermedia • 1.50 Legítima',
        ),
  ],
),

    ShortcutItem(
      titulo: 'Tubo estructural',
      alias: [
        'tubo estructural',
        'chapa',
        'espesor',
        'color',
        'negro',
        'galvanizado',
        '3/4x3/4',
        '2x4',
        '2x6',
        '4x4',
        '1x2',
        '1x1',
        '2x2'
      ],
      lineas: [
        ShortcutLine(label: 'Chapa 20', buscarComo: '1.0 mm', nota: 'Color identificación: Rojo'),
        ShortcutLine(label: 'Chapa 18', buscarComo: '2.0–1.20 mm', nota: 'Color identificación: Dorado'),
        ShortcutLine(label: 'Chapa 16', buscarComo: '1.30–1.50 mm', nota: 'Color identificación: Azul / Amarillo'),
        ShortcutLine(label: 'Chapa 14', buscarComo: '1.80–1.90 mm', nota: 'Color identificación: Verde'),
        ShortcutLine(
          label: 'Medidas',
          buscarComo: '3/4x3/4 • 1x1 • 1 1/4x1 1/4 • 1 1/2x1 1/2 • 2x2 • 3x3 • 2x4 • 4x4 • 1x2',
        ),
        
        ShortcutLine(
          label: 'Fundiciones',
          buscarComo: 'Tubo 2x4 y 4x4',
          nota: 'En estas medidas se ofrece chapa 16 o chapa 14.',
        ),
      ],
    ),
    ShortcutItem(
      titulo: 'Tubo para cerca / redondo',
      alias: ['cerca', 'redondo', 'galvanizado', 'chapa 18', 'chapa 16', 'chapa 14', '3 pulgadas'],
      lineas: [
        ShortcutLine(label: 'Chapas', buscarComo: '18 • 16 • 14'),
        ShortcutLine(label: 'Medidas', buscarComo: '3/4 • 1 • 1 1/4 • 1 1/2 • 2'),
        ShortcutLine(label: 'Nota', buscarComo: 'Todos los tubos para cerca son galvanizados'),
        ShortcutLine(label: 'Extra', buscarComo: 'Tubo redondo negro 3"'),
      ],
    ),
    ShortcutItem(
      titulo: 'Tubo HG (hierro galvanizado)',
      alias: ['hg', 'hierro galvanizado', 'agua potable', 'rosca', '1/2', '3/4', '1 1/4', '2', '3', '4', '6'],
      lineas: [
        ShortcutLine(label: 'Uso', buscarComo: 'Agua potable (rosca en ambos extremos)'),
        ShortcutLine(label: 'Medidas', buscarComo: '1/2 • 3/4 • 1 • 1 1/4 • 1 1/2 • 2 • 3 • 4'),
        ShortcutLine(label: 'Por encargo', buscarComo: '6'),
      ],
    ),
    ShortcutItem(
      titulo: 'Tubería PVC',
      alias: ['pvc', 'sdr26', 'sdr41', 'sdr64', 'potable', 'drenaje', 'dual force', 'alcantarillado'],
      lineas: [
        ShortcutLine(
          label: 'PVC potable (SDR26) – alta presión',
          buscarComo: '1/2 • 3/4 • 1 • 1 1/4 • 1 1/2 • 2 • 3 • 4 • 6 • 8',
        ),
        ShortcutLine(
          label: 'PVC inyectado (SDR41) – semi presión',
          buscarComo: '2 • 3 • 4 • 6 • 8',
          nota: 'Aguas negras.',
        ),
        ShortcutLine(
          label: 'PVC drenaje (SDR64)',
          buscarComo: '2" • 3" • 4" • 6" • 8"',
        ),
        ShortcutLine(
          label: 'Tubo corrugado alcantarillado (Dual Force)',
          buscarComo: '10" • 12" • 18" • 24" • 36"',
        ),
      ],
    ),
    ShortcutItem(
      titulo: 'Accesorios PVC',
      alias: ['accesorios', 'codo', 'tee', 'camisa', 'tapon', 'trampa', 'reductor', 'yee', 'adaptador'],
      lineas: [
        ShortcutLine(
          label: 'Potable',
          buscarComo:
              'Codos 90° y 45° • Tee 1/2 a 6 • Adaptador macho • Adaptador hembra (camisa con rosca) • Camisa o unión • Tapón liso y con rosca • Trampas 2,3,4 • Reductores 3/4 a 1/2 hasta 8 a 6',
        ),
        ShortcutLine(
          label: 'Drenaje',
          buscarComo:
              'Codos 2,3,4,6,8 (90° y 45°) • Tee • Camisa lisa • Tapón liso • Trampa • Reductores 3 a 2 • 4 a 3 • 6 a 4 • 8 a 6 • Yee 6 a 4',
        ),
      ],
    ),
    ShortcutItem(
      titulo: 'Cerámica (caja / palet)',
      alias: ['ceramica', 'azulejo', 'caja', 'palet', '25x33', '33x33', '45x45', '20x60', '60x60', '29x49.5', 'unicesa'],
      lineas: [
        ShortcutLine(label: 'Azulejo 25x33', buscarComo: '12 pzas/m² • 18 pzas/caja • 1.5 m²/caja'),
        ShortcutLine(label: 'Cerámica 33x33', buscarComo: '9 pzas/m² • 12 pzas/caja • 1.33 m²/caja'),
        ShortcutLine(label: 'Cerámica 45x45', buscarComo: '4.94 pzas/m² • 7 pzas/caja • 1.41 m²/caja'),
        ShortcutLine(label: 'Cerámica 20x60', buscarComo: '8.33 pzas/m² • 9 pzas/caja • 1.08 m²/caja'),
        ShortcutLine(label: 'Cerámica 60x60', buscarComo: '2.77 pzas/m² • 4 pzas/caja • 1.44 m²/caja'),
        ShortcutLine(label: 'Cerámica 29x49.5', buscarComo: '7.58 pzas/m² • 11 pzas/caja • 1.45 m²/caja'),
        ShortcutLine(label: 'Cerámica Unicesa 33x33', buscarComo: '9 pzas/m² • 18 pzas/caja • 2 m²/caja'),
        ShortcutLine(label: 'Cajas por palet', buscarComo: '25x33: 42 • 33x33: 84 • 45x45: 72 • 60x60: 36'),
        ShortcutLine(label: 'Cerámica brasileña 45x45', buscarComo: 'Se vende por caja', nota: 'La caja trae 11 piezas.'),
      ],
    ),
    ShortcutItem(
      titulo: 'Porcelanato (caja)',
      alias: ['porcelanato', '60x60', '60x120', '20x120', '1.20x1.80', 'caja', 'piezas'],
      lineas: [
        ShortcutLine(label: '60x60', buscarComo: '2.77 pzas/m² • 4 pzas/caja'),
        ShortcutLine(label: '60x120', buscarComo: '1.39 pzas/m² • 2 pzas/caja'),
        ShortcutLine(label: '20x120', buscarComo: '4.16 pzas/m² • 5 pzas/caja', nota: 'Se vende solo por caja.'),
        ShortcutLine(label: '1.20x1.80', buscarComo: '0.46 pzas/m²'),
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
    ShortcutItem(
      titulo: 'Cables',
      alias: ['cable', 'cables', 'awg', '12awg', 'cable 12', '12 awg'],
      lineas: [
        ShortcutLine(label: 'Cable 12 AWG', buscarComo: '12awg'),
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
                  labelText: 'Búsqueda',
                  hintText: 'Ej: varilla, 0.40, chapa 14, SDR26, 25x33, 2x4...',
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
                                                    ln.buscarComo,
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
