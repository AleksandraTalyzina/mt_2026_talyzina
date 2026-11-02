import 'package:flutter/material.dart';

void main() => runApp(const CounterJournalApp());

class CounterJournalApp extends StatelessWidget {
  const CounterJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter Journal',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const JournalPage(),
    );
  }
}

class JournalEntry {
  JournalEntry(this.change, this.value, this.time);

  final int change;
  final int value;
  final DateTime time;
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  int _counter = 0;
  final List<JournalEntry> _entries = [];

  void _change(int delta) {
    setState(() {
      _counter += delta;
      _entries.insert(0, JournalEntry(delta, _counter, DateTime.now()));
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
      _entries.clear();
    });
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Text('$_counter', style: theme.textTheme.displayLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => _change(-1),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () => _change(1),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No entries yet'))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      final up = e.change > 0;
                      return ListTile(
                        leading: Icon(
                          up ? Icons.arrow_upward : Icons.arrow_downward,
                          color: up ? Colors.green : Colors.red,
                        ),
                        title: Text('${up ? '+' : ''}${e.change} → ${e.value}'),
                        trailing: Text(_formatTime(e.time)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}