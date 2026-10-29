import 'package:flutter/material.dart';

void main() => runApp(const OrbitApp());

const bg = Color(0xFF111827);
const card = Color(0xFF1B2638);
const violet = Color(0xFF8B7CFF);
const mint = Color(0xFF57D6B3);
const muted = Color(0xFFA7B1C2);
const warning = Color(0xFFF2C66D);
const danger = Color(0xFFFF7F87);

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Orbit',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        secondary: mint,
        surface: card,
      ),
      useMaterial3: true,
    ),
    home: const OrbitHome(),
  );
}

class OrbitHome extends StatefulWidget {
  const OrbitHome({super.key});
  @override
  State<OrbitHome> createState() => _OrbitHomeState();
}

class _OrbitHomeState extends State<OrbitHome> {
  int tab = 0;
  bool online = true;
  bool showLoading = false;
  bool showError = false;
  bool showEmpty = false;
  bool notifications = true;
  String activityFilter = 'All';
  final input = TextEditingController();
  final tasks = <Map<String, String>>[
    {
      'title': 'Research quiet mechanical keyboards',
      'status': 'Running',
      'step': 'Comparing trusted review sources',
      'date': 'Just now',
      'evidence': 'true',
    },
    {
      'title': 'Summarize project notes',
      'status': 'Needs review',
      'step': 'Waiting to read your Orbit folder',
        'date': 'Today, 10:42',
        'evidence': 'true',
    },
    {
      'title': 'Create a weekly planning note',
      'status': 'Completed',
      'step': 'Saved to Demo folder',
      'date': 'Yesterday',
      'evidence': 'true',
    },
    {
      'title': 'Organize downloads',
      'status': 'Failed',
      'step': 'File moves are not enabled',
      'date': 'Yesterday',
    },
  ];
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_agent(), _activity(), _recordings(), _settings()];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.bubble_chart, color: violet, size: 30),
                  const SizedBox(width: 8),
                  const Text(
                    'orbit',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    online ? '● PC online' : '● PC offline',
                    style: TextStyle(
                      color: online ? mint : warning,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => tab = 3),
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
            Expanded(child: pages[tab]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            label: 'Agent',
          ),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Activity'),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            label: 'Recordings',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _agent() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Your workspace', style: TextStyle(color: muted)),
      const SizedBox(height: 5),
      const Text(
        'What can I help with?',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 18),
      _panel(
        Row(
          children: [
            Icon(
              online ? Icons.shield_outlined : Icons.wifi_off,
              color: online ? mint : warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                online
                    ? 'Your PC is ready · approved permissions only'
                    : 'PC offline · reconnect in Settings',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (!online)
              TextButton(
                onPressed: () => setState(() => online = true),
                child: const Text('Reconnect'),
              ),
          ],
        ),
      ),
      if (showLoading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(color: violet),
        ),
      if (showError)
        _panel(
          const Row(
            children: [
              Icon(Icons.error_outline, color: danger),
              SizedBox(width: 8),
              Expanded(child: Text('Could not refresh activity. Your saved tasks are still here.')),
            ],
          ),
        ),
      const SizedBox(height: 18),
      if (showEmpty)
        _panel(
          const Column(
            children: [
              Icon(Icons.bubble_chart_outlined, color: violet, size: 32),
              SizedBox(height: 8),
              Text('A little room to think'),
              SizedBox(height: 4),
              Text('Start a task and Orbit will show progress here.', style: TextStyle(color: muted)),
            ],
          ),
        )
      else ...[
      const Text(
        'ACTIVE TASK',
        style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1),
      ),
      const SizedBox(height: 8),
      ...tasks.where((task) => task['status'] == 'Running' || task['status'] == 'Queued').map((task) => Column(
        children: [
          _task(task),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _stopTask(task),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop'),
              style: TextButton.styleFrom(foregroundColor: danger),
            ),
          ),
        ],
      )),
      ...tasks.where((task) => task['status'] == 'Needs review').expand((task) => [
        _task(task),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _decideApproval(task, false), child: const Text('Decline'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(onPressed: () => _decideApproval(task, true), style: FilledButton.styleFrom(backgroundColor: violet), child: const Text('Approve'))),
        ]),
      ]),
      const Text(
        'RECENT CONVERSATION',
        style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1),
      ),
      const SizedBox(height: 8),
      _panel(
        const Text(
          'You  ·  Research quiet mechanical keyboards',
          style: TextStyle(height: 1.5),
        ),
      ),
      const SizedBox(height: 8),
      _panel(
        const Text(
          'Orbit  ·  I’m comparing trusted sources and will bring back a short summary.',
          style: TextStyle(height: 1.5),
        ),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 7,
        children: ['Research web', 'Summarize files', 'Create note']
            .map((s) => ActionChip(label: Text(s), onPressed: () => _submit(s)))
            .toList(),
      ),
      ],
      const SizedBox(height: 12),
      _panel(
        Column(
          children: [
            TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ask Orbit to do something…',
                border: InputBorder.none,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Demo mode · supported actions only',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
                const Spacer(),
                IconButton.filled(
                  onPressed: () => _submit(input.text),
                  icon: const Icon(Icons.arrow_upward),
                  style: IconButton.styleFrom(backgroundColor: violet),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  void _submit(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      showEmpty = false;
      tasks.insert(0, {
        'title': title,
        'status': online ? 'Queued' : 'Failed',
        'step': online ? 'Waiting for your PC' : 'PC is offline',
        'date': 'Just now',
      });
      input.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(online ? 'Task added to the local demo queue' : 'PC offline · task marked failed in local history')),
    );
  }

  void _decideApproval(Map<String, String> task, bool approved) {
    setState(() {
      task['status'] = approved ? 'Running' : 'Stopped';
      task['step'] = approved ? 'Reading approved Orbit folder' : 'Approval declined';
    });
  }

  void _stopTask(Map<String, String> task) {
    setState(() {
      task['status'] = 'Stopped';
      task['step'] = 'Stopped by you';
    });
  }

  Widget _activity() {
    final visible = showEmpty ? <Map<String, String>>[] : tasks.where((task) {
      return switch (activityFilter) {
        'Running' => task['status'] == 'Running' || task['status'] == 'Queued',
        'Completed' => task['status'] == 'Completed',
        'Needs review' => task['status'] == 'Needs review' || task['status'] == 'Failed',
        _ => true,
      };
    }).toList();
    return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Activity',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const Text(
        'A clear history of what Orbit has done.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 15),
      Wrap(
        spacing: 6,
        children: ['All', 'Running', 'Completed', 'Needs review']
            .map(
              (s) => ChoiceChip(
                label: Text(s),
                selected: s == activityFilter,
                onSelected: (_) => setState(() => activityFilter = s),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 12),
      if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(children: [
            Icon(Icons.inbox_outlined, color: violet, size: 34),
            SizedBox(height: 10),
            Text('Nothing in this view'),
            SizedBox(height: 5),
            Text('Try another filter or start a task.', style: TextStyle(color: muted)),
          ]),
        )
      else ...visible.map(_task),
    ],
  );
  }

  Widget _recordings() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Recordings',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Private evidence captured during task runs.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 14),
      if (showEmpty || !tasks.any((t) => t['evidence'] == 'true'))
        _panel(const Text('No evidence yet. Evidence from task runs will appear here.', style: TextStyle(color: muted)))
      else ...tasks
          .where((t) => t['evidence'] == 'true')
          .map(
            (t) => InkWell(
              onTap: () => _showTask(t),
              borderRadius: BorderRadius.circular(17),
              child: _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 125,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF514A89), Color(0xFF244B54)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_outline, size: 42),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(t['title']!),
                  Text(
                    '${t['date']} · screenshot preview',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            ),
          ),
    ],
  );

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Settings',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Your connection, permissions and privacy.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 16),
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(online ? 'My Windows PC · online' : 'My Windows PC · offline'),
            const SizedBox(height: 6),
            const Text(
              'Private demo connection',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () => setState(() => online = true),
                  child: const Text('Reconnect'),
                ),
                TextButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _panel(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allowed folders'),
            SizedBox(height: 4),
            Text(
              'Orbit Demo · Documents/Orbit',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            Divider(),
            Text('Supported actions'),
            SizedBox(height: 4),
            Text(
              'Web research · read files · create notes',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            Divider(),
            Text('Sensitive actions'),
            SizedBox(height: 4),
            Text(
              'Always ask before proceeding',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _panel(
        Column(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notifications,
            activeTrackColor: mint,
            title: const Text('Task notifications'),
            subtitle: const Text('Progress, approvals and completion', style: TextStyle(color: muted, fontSize: 11)),
            onChanged: (value) => setState(() => notifications = value),
          ),
          const Divider(),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.dark_mode_outlined, color: violet), title: Text('Appearance'), subtitle: Text('Dark mode', style: TextStyle(color: muted, fontSize: 11))),
        ]),
      ),
      const SizedBox(height: 15),
      const Text('DEMO STATES', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1)),
      Wrap(spacing: 6, runSpacing: 4, children: [
        TextButton(onPressed: () => setState(() => showLoading = !showLoading), child: Text(showLoading ? 'Hide loading' : 'Show loading')),
        TextButton(onPressed: () => setState(() => showError = !showError), child: Text(showError ? 'Hide error' : 'Show error')),
        TextButton(onPressed: () => setState(() => showEmpty = !showEmpty), child: Text(showEmpty ? 'Show sample data' : 'Show empty state')),
      ]),
      const Text(
        'Orbit · Phase 1 demo · Local mock data',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 11),
      ),
    ],
  );

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect this PC?'),
        content: const Text('Your task history stays on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => online = false);
  }

  void _showTask(Map<String, String> task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: Text(task['title']!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              Text('${task['status']} · ${task['date']}', style: TextStyle(color: _statusColor(task['status']!))),
              const SizedBox(height: 16),
              const Text('EVENT TIMELINE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('✓ Task submitted · ${task['date']}'),
              const SizedBox(height: 8),
              const Text('✓ Permissions checked · Allowed demo action'),
              const SizedBox(height: 8),
              Text('• ${task['step']}'),
              if (task['evidence'] == 'true') ...[
                const SizedBox(height: 16),
                const Text('EVIDENCE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFF514A89), Color(0xFF244B54)])),
                  child: const Center(child: Icon(Icons.image_outlined, size: 40)),
                ),
                const SizedBox(height: 5),
                const Text('Mock screenshot preview', style: TextStyle(color: muted, fontSize: 11)),
              ],
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _task(Map<String, String> task) => _panel(
        Material(
          color: card,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.circle,
        size: 12,
        color: _statusColor(task['status']!),
      ),
      title: Text(
        task['title']!,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${task['status']} · ${task['step']}\n${task['date']}',
        style: const TextStyle(color: muted, height: 1.5, fontSize: 11),
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right, color: muted),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['title']!,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Timeline · Submitted ${task['date']}'),
              const SizedBox(height: 8),
              Text(task['step']!),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
          ),
        ),
  );

  Color _statusColor(String s) => switch (s) {
    'Completed' => mint,
    'Failed' || 'Stopped' => danger,
    'Needs review' => warning,
    _ => violet,
  };
  Widget _panel(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 3),
    child: Material(
      color: card,
      borderRadius: BorderRadius.circular(17),
      child: Padding(padding: const EdgeInsets.all(13), child: child),
    ),
  );
}
