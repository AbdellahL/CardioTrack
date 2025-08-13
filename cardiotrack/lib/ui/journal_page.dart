import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../data/database.dart';
import '../domain/esc.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final AppDatabase _db = AppDatabase();

  final _formKey = GlobalKey<FormState>();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final systolic = int.parse(_systolicCtrl.text);
    final diastolic = int.parse(_diastolicCtrl.text);
    final notes = _notesCtrl.text.trim();
    await _db.insertReading(ReadingsCompanion.insert(
      systolic: systolic,
      diastolic: diastolic,
      takenAt: _selectedDateTime,
      notes: Value(notes),
    ));
    _systolicCtrl.clear();
    _diastolicCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _selectedDateTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final form = Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _systolicCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'PAS (systolique)'),
                          validator: (v) {
                            final value = int.tryParse(v ?? '');
                            if (value == null || value < 50 || value > 300) return 'Valeur invalide';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _diastolicCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'PAD (diastolique)'),
                          validator: (v) {
                            final value = int.tryParse(v ?? '');
                            if (value == null || value < 30 || value > 200) return 'Valeur invalide';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDateTime,
                          icon: const Icon(Icons.event),
                          label: Text(dateFmt.format(_selectedDateTime)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _notesCtrl,
                          decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final list = Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder(
              stream: _db.watchReadings(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucune mesure pour le moment. Ajoutez votre première mesure.'),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('PAS')),
                      DataColumn(label: Text('PAD')),
                      DataColumn(label: Text('Cat.')),
                      DataColumn(label: Text('Notes')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final r in items)
                        DataRow(cells: [
                          DataCell(Text(dateFmt.format(r.takenAt))),
                          DataCell(Text(r.systolic.toString())),
                          DataCell(Text(r.diastolic.toString())),
                          DataCell(_CategoryChip(s: r.systolic, d: r.diastolic)),
                          DataCell(Text(r.notes)),
                          DataCell(Row(
                            children: [
                              IconButton(
                                tooltip: 'Supprimer',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _db.deleteReadingById(r.id),
                              ),
                            ],
                          )),
                        ])
                    ],
                  ),
                );
              },
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: form),
              Expanded(flex: 6, child: list),
            ],
          );
        }
        return ListView(
          children: [form, list],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final int s;
  final int d;
  const _CategoryChip({required this.s, required this.d});
  @override
  Widget build(BuildContext context) {
    final cat = EscClassification.classify(systolic: s, diastolic: d);
    return Chip(
      label: Text(EscClassification.label(cat)),
      backgroundColor: EscClassification.color(cat).withOpacity(0.15),
      side: BorderSide(color: EscClassification.color(cat)),
      labelStyle: TextStyle(color: EscClassification.color(cat), fontWeight: FontWeight.w600),
    );
  }
}