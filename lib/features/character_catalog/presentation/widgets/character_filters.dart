import 'package:flutter/material.dart';

import '../../domain/entities/character_filter.dart';

final class CharacterFilters extends StatefulWidget {
  const CharacterFilters({
    required this.onApply,
    this.filter = const CharacterFilter(),
    super.key,
  });

  final ValueChanged<CharacterFilter> onApply;
  final CharacterFilter filter;

  @override
  State<CharacterFilters> createState() => _CharacterFiltersState();
}

final class _CharacterFiltersState extends State<CharacterFilters> {
  final _name = TextEditingController();
  final _species = TextEditingController();
  final _type = TextEditingController();
  CharacterStatus? _status;
  CharacterGender? _gender;
  late CharacterFilter _appliedFilter;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _appliedFilter = widget.filter;
    _writeFilter(widget.filter);
    _name.addListener(_onDraftChanged);
    _species.addListener(_onDraftChanged);
    _type.addListener(_onDraftChanged);
  }

  @override
  void didUpdateWidget(covariant CharacterFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != _appliedFilter) {
      _appliedFilter = widget.filter;
      _writeFilter(widget.filter);
    }
  }

  @override
  void dispose() {
    _name.removeListener(_onDraftChanged);
    _species.removeListener(_onDraftChanged);
    _type.removeListener(_onDraftChanged);
    _name.dispose();
    _species.dispose();
    _type.dispose();
    super.dispose();
  }

  CharacterFilter get _draftFilter => CharacterFilter(
    name: _name.text,
    species: _species.text,
    type: _type.text,
    status: _status,
    gender: _gender,
  );

  void _writeFilter(CharacterFilter filter) {
    _name.text = filter.name;
    _species.text = filter.species;
    _type.text = filter.type;
    _status = filter.status;
    _gender = filter.gender;
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  void _apply(CharacterFilter filter) {
    if (filter == _appliedFilter) return;
    setState(() => _appliedFilter = filter);
    _writeFilter(filter);
    widget.onApply(filter);
  }

  Future<void> _openSheet() async {
    setState(() => _sheetOpen = true);
    final result = await showModalBottomSheet<CharacterFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CharacterFilterSheet(
        initialFilter: _draftFilter,
        nameController: _name,
      ),
    );
    if (!mounted) return;
    setState(() => _sheetOpen = false);
    if (result != null) _apply(result);
  }

  void _applyDraft() => _apply(_draftFilter);

  void _clear() => _apply(const CharacterFilter());

  @override
  Widget build(BuildContext context) {
    final hasPendingChanges = _draftFilter != _appliedFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nome do personagem',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _applyDraft(),
        ),
        const SizedBox(height: 12),
        if (!_sheetOpen) _actions(hasPendingChanges),
        if (!_appliedFilter.isEmpty) ...[
          const SizedBox(height: 12),
          _appliedChips(),
        ],
      ],
    );
  }

  Widget _actions(bool hasPendingChanges) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _openSheet,
          icon: const Icon(Icons.tune),
          label: const Text('Filtros'),
        ),
      ),
      if (!_appliedFilter.isEmpty) ...[
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _clear,
          icon: const Icon(Icons.clear),
          label: const Text('Limpar'),
        ),
      ],
      if (hasPendingChanges || _appliedFilter.isEmpty) ...[
        const SizedBox(width: 8),
        FilledButton(onPressed: _applyDraft, child: const Text('Aplicar')),
      ],
    ],
  );

  Widget _appliedChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final label in _chipLabels(_appliedFilter)) Chip(label: Text(label)),
    ],
  );

  List<String> _chipLabels(CharacterFilter filter) => [
    if (filter.name.trim().isNotEmpty) 'Nome: ${filter.name.trim()}',
    if (filter.status != null) 'Status: ${_statusLabel(filter.status!)}',
    if (filter.gender != null) 'Gênero: ${_genderLabel(filter.gender!)}',
    if (filter.species.trim().isNotEmpty) 'Espécie: ${filter.species.trim()}',
    if (filter.type.trim().isNotEmpty) 'Tipo: ${filter.type.trim()}',
  ];

  String _statusLabel(CharacterStatus status) => switch (status) {
    CharacterStatus.alive => 'Vivo',
    CharacterStatus.dead => 'Morto',
    CharacterStatus.unknown => 'Desconhecido',
  };

  String _genderLabel(CharacterGender gender) => switch (gender) {
    CharacterGender.female => 'Feminino',
    CharacterGender.male => 'Masculino',
    CharacterGender.genderless => 'Sem gênero',
    CharacterGender.unknown => 'Desconhecido',
  };
}

final class _CharacterFilterSheet extends StatefulWidget {
  const _CharacterFilterSheet({
    required this.initialFilter,
    required this.nameController,
  });

  final CharacterFilter initialFilter;
  final TextEditingController nameController;

  @override
  State<_CharacterFilterSheet> createState() => _CharacterFilterSheetState();
}

final class _CharacterFilterSheetState extends State<_CharacterFilterSheet> {
  late final TextEditingController _species;
  late final TextEditingController _type;
  late CharacterStatus? _status;
  late CharacterGender? _gender;

  @override
  void initState() {
    super.initState();
    _species = TextEditingController(text: widget.initialFilter.species);
    _type = TextEditingController(text: widget.initialFilter.type);
    _status = widget.initialFilter.status;
    _gender = widget.initialFilter.gender;
  }

  @override
  void dispose() {
    _species.dispose();
    _type.dispose();
    super.dispose();
  }

  void _apply() => Navigator.of(context).pop(
    CharacterFilter(
      name: widget.nameController.text,
      species: _species.text,
      type: _type.text,
      status: _status,
      gender: _gender,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _handle()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtrar personagens',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      Navigator.of(context).pop(const CharacterFilter()),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Limpar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Combine status, gênero e espécie para refinar a listagem.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _statusField(),
            const SizedBox(height: 12),
            _genderField(),
            const SizedBox(height: 12),
            TextField(
              controller: _species,
              decoration: const InputDecoration(
                labelText: 'Espécie',
                hintText: 'Ex.: Human ou Alien',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                hintText: 'Ex.: Parasite',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check),
              label: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.outlineVariant,
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _statusField() => DropdownButtonFormField<CharacterStatus>(
    key: ValueKey('sheet-status-$_status'),
    initialValue: _status,
    decoration: const InputDecoration(
      labelText: 'Status',
      border: OutlineInputBorder(),
    ),
    items: [
      const DropdownMenuItem(child: Text('Todos os status')),
      for (final status in CharacterStatus.values)
        DropdownMenuItem(value: status, child: Text(_statusLabel(status))),
    ],
    onChanged: (value) => setState(() => _status = value),
  );

  Widget _genderField() => DropdownButtonFormField<CharacterGender>(
    key: ValueKey('sheet-gender-$_gender'),
    initialValue: _gender,
    decoration: const InputDecoration(
      labelText: 'Gênero',
      border: OutlineInputBorder(),
    ),
    items: [
      const DropdownMenuItem(child: Text('Todos os gêneros')),
      for (final gender in CharacterGender.values)
        DropdownMenuItem(value: gender, child: Text(_genderLabel(gender))),
    ],
    onChanged: (value) => setState(() => _gender = value),
  );

  String _statusLabel(CharacterStatus status) => switch (status) {
    CharacterStatus.alive => 'Vivo',
    CharacterStatus.dead => 'Morto',
    CharacterStatus.unknown => 'Desconhecido',
  };

  String _genderLabel(CharacterGender gender) => switch (gender) {
    CharacterGender.female => 'Feminino',
    CharacterGender.male => 'Masculino',
    CharacterGender.genderless => 'Sem gênero',
    CharacterGender.unknown => 'Desconhecido',
  };
}
