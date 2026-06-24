import 'package:velora/velora.dart';

import 'chat_message.dart';

abstract class MessagesDataSource {
  Future<List<ChatMessage>> getMessages(String conversationId);
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentUrls = const [],
  });
}

/// In-memory mock that simulates `GET /api/conversations/{id}/messages`
/// and `POST /api/conversations/{id}/messages` via [VeloraMockApi].
class MockMessagesDataSource implements MessagesDataSource {
  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final seed = _seedMessages[conversationId] ?? [];
    return VeloraMockApi.ok<List<ChatMessage>>(
      seed.map((m) => m.toJson()).toList(),
      parser: (v) => (v as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentUrls = const [],
  }) async {
    // Simulate assistant thinking delay (separate from network latency).
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return VeloraMockApi.ok<ChatMessage>(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _generateReply(content, attachmentUrls: attachmentUrls),
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      ).toJson(),
      parser: (v) => ChatMessage.fromJson(v as Map<String, dynamic>),
      delayMs: 100,
    );
  }

  static String _generateReply(
    String input, {
    List<String> attachmentUrls = const [],
  }) {
    if (attachmentUrls.isNotEmpty) {
      final count = attachmentUrls.length;
      return 'I can see you\'ve shared ${count == 1 ? 'a file' : '$count files'}. In a real integration I\'d analyse the content with Claude\'s vision and document-understanding capabilities. The attachment URLs were uploaded via `VeloraAttachmentsMixin.uploadAll()` and are now available in your controller\'s `uploadedUrls` getter.';
    }
    final lower = input.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello! I\'m Claude, made by Anthropic. How can I help you today?';
    }
    if (lower.contains('theme') || lower.contains('velora')) {
      return 'This demo is built with the **Velora Flutter DX layer**.\n\nThe theming system uses `VeloraTheme.fromScheme()` with a hand-crafted `ColorScheme` to precisely match Claude\'s warm copper-and-cream brand palette. Custom tokens (message bubbles, code blocks, input bar) live outside Material\'s standard palette and are injected via `ThemeExtension<ClaudeTokens>`.';
    }
    if (lower.contains('paginate') || lower.contains('list')) {
      return 'The conversation list uses `VeloraPaginatedController<T>` — a base class that manages paging state, incremental loading, and pull-to-refresh. Subclasses just implement `fetchPage(int page)` pointing at their data source.';
    }
    return 'That\'s a great question. In a real integration I\'d stream a response from the Claude API. This demo mocks the reply, but the full UI — message bubbles, typing indicator, code-block rendering, and scroll-to-bottom — all behave exactly as in production.';
  }

  static final _seed0 = DateTime.now().subtract(const Duration(minutes: 12));

  static final Map<String, List<ChatMessage>> _seedMessages = {
    '1': [
      ChatMessage(
        id: 'q1',
        content: 'Can you explain quantum entanglement in simple terms?',
        role: MessageRole.user,
        createdAt: _seed0,
      ),
      ChatMessage(
        id: 'q2',
        content:
            'Quantum entanglement is one of the most fascinating phenomena in physics.\n\nImagine you have two coins that are "entangled." When you flip them and one lands heads, the other *instantly* lands tails — no matter how far apart they are. Not because one coin "told" the other, but because their states are correlated at the quantum level.\n\nWhat makes this genuinely strange is that before you look at either coin, neither has a definite state. They exist in a superposition of both heads *and* tails simultaneously.',
        role: MessageRole.assistant,
        createdAt: _seed0.add(const Duration(seconds: 3)),
      ),
      ChatMessage(
        id: 'q3',
        content: 'Does that mean information travels faster than light?',
        role: MessageRole.user,
        createdAt: _seed0.add(const Duration(minutes: 2)),
      ),
      ChatMessage(
        id: 'q4',
        content:
            'No — and this is where it gets subtle.\n\nEntanglement doesn\'t allow faster-than-light communication. When you measure your coin and see "heads," you instantly know the other is "tails." But you can\'t *control* what result you get, so you can\'t use that to send information.\n\nEinstein called it "spooky action at a distance" and didn\'t believe it was real. Bell\'s theorem (1964) and subsequent experiments proved him wrong.',
        role: MessageRole.assistant,
        createdAt: _seed0.add(const Duration(minutes: 2, seconds: 4)),
      ),
    ],
    '2': [
      ChatMessage(
        id: 'p1',
        content: 'I need a Python script to batch process CSV files — rename columns, filter rows, and output to a new folder.',
        role: MessageRole.user,
        createdAt: _seed0,
      ),
      ChatMessage(
        id: 'p2',
        content:
            '```python\nimport pandas as pd\nfrom pathlib import Path\n\ndef process_csv(src: Path, dst: Path) -> None:\n    df = pd.read_csv(src)\n    df.rename(columns={\'old_name\': \'new_name\'}, inplace=True)\n    df = df[df[\'status\'] == \'active\']\n    df.to_csv(dst, index=False)\n\ndef batch_process(input_dir: str, output_dir: str) -> None:\n    src_dir = Path(input_dir)\n    dst_dir = Path(output_dir)\n    dst_dir.mkdir(parents=True, exist_ok=True)\n    for csv_file in src_dir.glob(\'*.csv\'):\n        process_csv(csv_file, dst_dir / csv_file.name)\n        print(f\'Processed {csv_file.name}\')\n\nif __name__ == \'__main__\':\n    batch_process(\'./input\', \'./output\')\n```\n\nWant me to add async support or better error handling?',
        role: MessageRole.assistant,
        createdAt: _seed0.add(const Duration(seconds: 2)),
      ),
    ],
    '3': [
      ChatMessage(
        id: 'r1',
        content: 'What are the most important React hooks best practices people miss?',
        role: MessageRole.user,
        createdAt: _seed0,
      ),
      ChatMessage(
        id: 'r2',
        content:
            'Here are the ones I see missed most often:\n\n**1. useEffect cleanup**\nAlways return a cleanup function:\n```js\nuseEffect(() => {\n  const id = setInterval(() => setCount(c => c + 1), 1000);\n  return () => clearInterval(id);\n}, []);\n```\n\n**2. Stale closures in callbacks**\nIf your effect uses a value that changes, include it in the dependency array — or use `useRef` to hold the latest value.\n\n**3. Initialiser functions in useState**\n```js\n// ❌ Runs every render\nconst [s] = useState(heavyComputation());\n// ✅ Runs once\nconst [s] = useState(() => heavyComputation());\n```',
        role: MessageRole.assistant,
        createdAt: _seed0.add(const Duration(seconds: 3)),
      ),
    ],
  };
}
