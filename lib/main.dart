import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FerreteriaCalcApp());
}

enum UnitKind { m2, ft2 }
enum CalcCategory { ceramica, cieloFalso }

class OptionItem {
  final String label;
  final double piezasPorM2;
  const OptionItem(this.label, this.piezasPorM2);
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    OptionItem('Cerámica 0.45 × 0.45', 4.94),
    OptionItem('Azulejo 0.25 × 0.33', 12.0),
    OptionItem('Cerámica 0.33 × 0.33', 9.0),
    OptionItem('Cerámica 0.29 × 0.495', 7.58),
    OptionItem('Cerámica 0.20 × 0.60', 8.33),
  ];

  static const cieloFalsoOptions = <OptionItem>[
    OptionItem('Tablilla 5.95 × 0.25 (1 m² = 1.49 piezas)', 1.49),
    OptionItem('Tablilla 0.20 × 5.95 (1 pieza = 1.19 m²)', 1 / 1.19),
  ];

  List<OptionItem> get options {
    switch (category) {
      case CalcCategory.ceramica:
        return ceramicaOptions;
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
      case CalcCategory.cieloFalso:
        return 'Cielo falso';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
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
                                      'Cerámica y cielo falso',
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
