import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:orbit_mobile/core/networking/orbit_api.dart';

void main() => runApp(const OrbitApp());

const bg = Color(0xFF111827);
const card = Color(0xFF1B2638);
const violet = Color(0xFF8B7CFF);
const mint = Color(0xFF57D6B3);
const muted = Color(0xFFA7B1C2);
const warning = Color(0xFFF2C66D);
const danger = Color(0xFFFF7F87);

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key, this.apiFactory});
  final OrbitApiService Function(String, String)? apiFactory;
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
    home: OrbitHome(apiFactory: apiFactory),
  );
}

class OrbitHome extends StatefulWidget {
  const OrbitHome({super.key, this.apiFactory});
  final OrbitApiService Function(String, String)? apiFactory;
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
  bool apiConnected = false;
  bool agentOnline = false;
  bool refreshInFlight = false;
  String? connectionError;
  OrbitApiService? api;
  Timer? pollTimer;
  final backendController = TextEditingController(text: 'http://127.0.0.1:8765');
  final tokenController = TextEditingController();
  List<Map<String, String>> remoteTasks = [];
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
    pollTimer?.cancel();
    api?.close();
    input.dispose();
    backendController.dispose();
    tokenController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get visibleTasks => apiConnected ? remoteTasks : tasks;
  String get connectionLabel => apiConnected
      ? (agentOnline ? 'PC online' : 'Agent offline')
      : (online ? 'Demo mode' : 'PC offline');

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
                    connectionLabel,
                    style: TextStyle(
                      color: apiConnected ? (agentOnline ? mint : warning) : violet,
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
              (apiConnected ? agentOnline : online) ? Icons.shield_outlined : Icons.wifi_off,
              color: (apiConnected ? agentOnline : online) ? mint : warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                !apiConnected
                    ? (online ? 'Demo data only · connect to your PC in Settings' : 'PC offline · connect in Settings')
                    : agentOnline
                        ? 'Your PC is ready · allowlisted actions only'
                        : 'Backend connected · Windows agent is offline',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (!apiConnected)
              TextButton(
                onPressed: () => setState(() => tab = 3),
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
      if (showLoading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(key: ValueKey('demo-loading-indicator'), color: violet),
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
      if (connectionError != null)
        _panel(Text(connectionError!, style: const TextStyle(color: danger, fontSize: 12))),
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
      ...visibleTasks.where((task) => task['status'] == 'Running' || task['status'] == 'Queued').map((task) => Column(
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
      ...visibleTasks.where((task) => task['status'] == 'Needs review').expand((task) => [
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
            .map((s) => ActionChip(label: Text(s), onPressed: () => _submit(s == 'Create note' ? 'Create note: A note created from Orbit mobile.' : s)))
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

  Future<void> _submit(String title) async {
    if (title.trim().isEmpty) return;
    if (apiConnected && api != null) {
      try {
        final result = await api!.submit(title);
        await _refreshRemote();
        if (mounted) {
          input.clear();
          final status = result['status']?.toString();
          final message = status == 'failed'
              ? result['error']?.toString() ?? result['step']?.toString() ?? 'Unsupported task'
              : 'Task sent to your PC';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (error) {
        if (mounted) setState(() => connectionError = error.toString());
      }
      return;
    }
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

  Future<void> _connectBackend() async {
    OrbitApiService? candidate;
    try {
      candidate = widget.apiFactory?.call(backendController.text, tokenController.text.trim())
          ?? OrbitApi(backendController.text, tokenController.text.trim());
      final health = await candidate.health();
      final loaded = await candidate.tasks();
      if (!mounted) { candidate.close(); return; }
      pollTimer?.cancel();
      api?.close();
      setState(() {
        api = candidate;
        apiConnected = true;
        agentOnline = health['agent_online'] == true;
        remoteTasks = loaded.map(_toTaskMap).toList();
        connectionError = null;
      });
      pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemote());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected to the Orbit backend')));
    } catch (error) {
      candidate?.close();
      if (mounted) setState(() { apiConnected = false; agentOnline = false; connectionError = error.toString(); });
    }
  }

  Future<void> _refreshRemote() async {
    final client = api;
    if (!apiConnected || client == null || refreshInFlight) return;
    refreshInFlight = true;
    try {
      final values = await Future.wait([client.health(), client.tasks()]);
      if (!mounted || api != client) return;
      setState(() {
        agentOnline = (values[0] as Map<String, dynamic>)['agent_online'] == true;
        remoteTasks = (values[1] as List<Map<String, dynamic>>).map(_toTaskMap).toList();
        connectionError = null;
      });
    } catch (error) {
      if (mounted && api == client) setState(() => connectionError = error.toString());
    } finally {
      refreshInFlight = false;
    }
  }

  Map<String, String> _toTaskMap(Map<String, dynamic> raw) {
    final evidence = raw['evidence'] is List && (raw['evidence'] as List).isNotEmpty
        ? (raw['evidence'] as List).first as Map<String, dynamic>
        : null;
    final rawDate = DateTime.tryParse(raw['created_at']?.toString() ?? '');
    final status = switch (raw['status']) {
      'queued' => 'Queued',
      'running' => 'Running',
      'waiting_approval' => 'Needs review',
      'completed' => 'Completed',
      'failed' => 'Failed',
      'stopped' => 'Stopped',
      _ => 'Failed',
    };
    return {
      'id': raw['id']?.toString() ?? '',
      'title': raw['title']?.toString() ?? 'Orbit task',
      'status': status,
      'step': raw['error']?.toString().isNotEmpty == true ? raw['error'].toString() : raw['step']?.toString() ?? '',
      'date': rawDate == null ? 'Recently' : rawDate.toLocal().toString().substring(0, 16),
      'progress': raw['progress']?.toString() ?? '0',
      'result': raw['result']?.toString() ?? '',
      'evidence': evidence == null ? 'false' : 'true',
      'evidenceId': evidence?['id']?.toString() ?? '',
      'raw': jsonEncode(raw),
    };
  }

  void _decideApproval(Map<String, String> task, bool approved) {
    setState(() {
      task['status'] = approved ? 'Running' : 'Stopped';
      task['step'] = approved ? 'Reading approved Orbit folder' : 'Approval declined';
    });
  }

  Future<void> _stopTask(Map<String, String> task) async {
    if (apiConnected && api != null && task['id']?.isNotEmpty == true) {
      try {
        await api!.stop(task['id']!);
        await _refreshRemote();
      } catch (error) {
        if (mounted) setState(() => connectionError = error.toString());
      }
      return;
    }
    setState(() {
      task['status'] = 'Stopped';
      task['step'] = 'Stopped by you';
    });
  }

  Widget _activity() {
    final visible = showEmpty ? <Map<String, String>>[] : visibleTasks.where((task) {
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
      if (showEmpty || !visibleTasks.any((t) => t['evidence'] == 'true'))
        _panel(const Text('No evidence yet. Evidence from task runs will appear here.', style: TextStyle(color: muted)))
      else ...visibleTasks
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
            Text(apiConnected ? (agentOnline ? 'Windows agent online' : 'Windows agent offline') : 'Not connected · using local mock data'),
            const SizedBox(height: 9),
            TextField(controller: backendController, autocorrect: false, decoration: const InputDecoration(labelText: 'Backend URL', hintText: 'http://192.168.1.20:8765')),
            const SizedBox(height: 8),
            TextField(controller: tokenController, autocorrect: false, obscureText: true, decoration: const InputDecoration(labelText: 'Mobile access token')),
            const SizedBox(height: 4),
            const Text('On a phone, use your PC’s private Wi-Fi address. The token stays in memory for this session.', style: TextStyle(color: muted, fontSize: 11)),
            if (connectionError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(connectionError!, style: const TextStyle(color: danger, fontSize: 11))),
            Wrap(children: [
              FilledButton(onPressed: _connectBackend, child: Text(apiConnected ? 'Reconnect' : 'Connect')),
              const SizedBox(width: 8),
              TextButton(onPressed: _disconnect, child: const Text('Disconnect')),
            ]),
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
    if (ok == true) {
      pollTimer?.cancel();
      api?.close();
      setState(() {
        api = null;
        apiConnected = false;
        agentOnline = false;
        online = false;
        remoteTasks = [];
        connectionError = null;
      });
    }
  }

  void _showTask(Map<String, String> task) {
    final raw = task['raw'];
    final events = raw == null
        ? <dynamic>[]
        : (jsonDecode(raw) as Map<String, dynamic>)['events'] as List<dynamic>? ?? <dynamic>[];
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
              if (events.isNotEmpty)
                ...events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.circle, size: 8, color: mint),
                    const SizedBox(width: 9),
                    Expanded(child: Text('${event['message']}', style: const TextStyle(fontSize: 12))),
                  ]),
                ))
              else ...[
                Text('✓ Task submitted · ${task['date']}'),
                const SizedBox(height: 8),
                const Text('✓ Permissions checked · Allowed demo action'),
                const SizedBox(height: 8),
                Text('• ${task['step']}'),
              ],
              if (task['result']?.isNotEmpty == true)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('Result · ${task['result']}', style: const TextStyle(color: mint, fontSize: 12))),
              if (task['evidence'] == 'true') ...[
                const SizedBox(height: 16),
                const Text('EVIDENCE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 8),
                if (apiConnected && task['evidenceId']?.isNotEmpty == true && api != null)
                  FutureBuilder<Uint8List>(
                    future: api!.evidence(task['evidenceId']!),
                    builder: (context, snapshot) => Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF26344A)),
                      clipBehavior: Clip.antiAlias,
                      child: snapshot.hasData
                          ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                          : Center(child: snapshot.hasError ? const Icon(Icons.broken_image_outlined, color: danger) : const CircularProgressIndicator()),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFF514A89), Color(0xFF244B54)])),
                    child: const Center(child: Icon(Icons.image_outlined, size: 40)),
                  ),
                const SizedBox(height: 5),
                Text(apiConnected ? 'Generated note preview' : 'Mock evidence preview', style: const TextStyle(color: muted, fontSize: 11)),
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
      child: Column(children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.circle, size: 12, color: _statusColor(task['status']!)),
          title: Text(task['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('${task['status']} · ${task['step']}\n${task['date']}', style: const TextStyle(color: muted, height: 1.5, fontSize: 11)),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right, color: muted),
          onTap: () => _showTask(task),
        ),
        if (task['status'] == 'Running' || task['status'] == 'Queued')
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(
              value: double.tryParse(task['progress'] ?? '') ?? 0.62,
              minHeight: 4,
              backgroundColor: const Color(0xFF303B50),
              color: violet,
            ),
          ),
      ]),
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
