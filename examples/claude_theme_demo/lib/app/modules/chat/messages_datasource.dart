import 'package:velora/velora.dart';

import 'chat_message.dart';

abstract class MessagesDataSource {
  /// Cursor-paginated message history.
  ///
  /// Pass [beforeId] = null for the most recent page.
  /// Subsequent "load earlier" calls pass the oldest message ID from the
  /// previous page as [beforeId].
  ///
  /// Returns a [CursorPage] whose [CursorPage.nextCursor] is the oldest
  /// message ID in this batch — pass it as [beforeId] for the next earlier
  /// page.  [CursorPage.nextCursor] is null when the start of the history
  /// has been reached.
  Future<CursorPage<ChatMessage, String>> getPage(
    String conversationId, {
    String? beforeId,
    int limit = 20,
  });

  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentUrls = const [],
  });

  Future<void> clearMessages(String conversationId);
  Future<void> rename(String conversationId, String title);
  Future<void> toggleStar(String conversationId);
  Future<void> delete(String conversationId);
}

/// In-memory mock that simulates `GET /api/conversations/{id}/messages`
/// and `POST /api/conversations/{id}/messages`.
///
/// The store is static so [HomeController] and [ChatController] see the same
/// mutations without a real backend.
class MockMessagesDataSource implements MessagesDataSource {
  @override
  Future<CursorPage<ChatMessage, String>> getPage(
    String conversationId, {
    String? beforeId,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final all = _store[conversationId] ?? <ChatMessage>[];

    // endIndex is the exclusive upper bound of the slice we'll return.
    int endIndex = all.length;
    if (beforeId != null) {
      final idx = all.indexWhere((m) => m.id == beforeId);
      endIndex = idx >= 0 ? idx : all.length;
    }

    final startIndex = (endIndex - limit).clamp(0, endIndex);
    final page = all.sublist(startIndex, endIndex);

    // nextCursor = oldest message ID in this batch; null once we reach the start.
    final nextCursor = startIndex > 0 ? page.first.id : null;

    return CursorPage<ChatMessage, String>(data: page, nextCursor: nextCursor);
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentUrls = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final bucket = _store.putIfAbsent(conversationId, () => <ChatMessage>[]);
    bucket.add(ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}-u',
      content: content,
      role: MessageRole.user,
      createdAt: DateTime.now(),
    ));
    final assistantMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}-a',
      content: _generateReply(content, attachmentUrls: attachmentUrls),
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
    );
    bucket.add(assistantMsg);
    return VeloraMockApi.ok<ChatMessage>(
      assistantMsg.toJson(),
      parser: (v) => ChatMessage.fromJson(v as Map<String, dynamic>),
      delayMs: 100,
    );
  }

  @override
  Future<void> clearMessages(String conversationId) async {
    await VeloraMockApi.ok<void>(null, delayMs: 200);
    _store[conversationId]?.clear();
  }

  @override
  Future<void> rename(String conversationId, String title) =>
      VeloraMockApi.ok<void>(null, delayMs: 150);

  @override
  Future<void> toggleStar(String conversationId) =>
      VeloraMockApi.ok<void>(null, delayMs: 100);

  @override
  Future<void> delete(String conversationId) async {
    await VeloraMockApi.ok<void>(null, delayMs: 200);
    _store.remove(conversationId);
  }

  // ---------------------------------------------------------------------------
  // Reply generation
  // ---------------------------------------------------------------------------

  static String _generateReply(
    String input, {
    List<String> attachmentUrls = const [],
  }) {
    if (attachmentUrls.isNotEmpty) {
      final count = attachmentUrls.length;
      return 'I can see you\'ve shared ${count == 1 ? 'a file' : '$count files'}. '
          'In a real integration I\'d analyse the content with Claude\'s vision '
          'and document-understanding capabilities. The attachment URLs were uploaded '
          'via `VeloraAttachmentsMixin.uploadAll()` and are now available in your '
          "controller's `uploadedUrls` getter.";
    }
    final lower = input.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return "Hello! I'm Claude, made by Anthropic. How can I help you today?";
    }
    if (lower.contains('theme') || lower.contains('velora')) {
      return 'This demo is built with the **Velora Flutter DX layer**.\n\n'
          'The theming system uses `VeloraTheme.fromScheme()` with a hand-crafted '
          '`ColorScheme` to precisely match Claude\'s warm copper-and-cream brand '
          'palette. Custom tokens (message bubbles, code blocks, input bar) live '
          "outside Material's standard palette and are injected via "
          '`ThemeExtension<ClaudeTokens>`.';
    }
    if (lower.contains('paginate') || lower.contains('earlier') ||
        lower.contains('cursor')) {
      return 'Message history uses **cursor/keyset pagination** via '
          '`CursorPage<T, C>` from Velora.\n\n'
          'Each `getPage()` call returns a batch and a `nextCursor` — the ID of '
          'the oldest message in the batch. Pass it as `beforeId` on the next '
          '"load earlier" request. When `nextCursor` is null the start of history '
          'has been reached.\n\n'
          'The controller uses `loadEarlier()` which prepends the new batch to '
          'the front of the list and updates `hasEarlier`.';
    }
    return "That's a great question. In a real integration I'd stream a response "
        'from the Claude API. This demo mocks the reply, but the full UI — '
        'message bubbles, typing indicator, code-block rendering, cursor '
        'pagination, and scroll-to-bottom — all behave exactly as in production.';
  }

  // ---------------------------------------------------------------------------
  // Seed data — static so mutations persist across controller instances
  // ---------------------------------------------------------------------------

  static final _t0 = DateTime.now().subtract(const Duration(hours: 1));

  static final Map<String, List<ChatMessage>> _store = {
    '1': _seedQuantum(),
    '2': _seedPython(),
    '3': _seedReact(),
    '4': _seedJapan(),
    '5': _seedTypeScript(),
    '6': _seedCoverLetter(),
    '7': _seedSql(),
    '8': _seedMonads(),
  };

  static List<ChatMessage> _seedQuantum() {
    DateTime t(int minutes) => _t0.add(Duration(minutes: minutes));
    return [
      ChatMessage(id: 'q01', role: MessageRole.user, createdAt: t(0),
          content: 'Can you explain quantum entanglement in simple terms?'),
      ChatMessage(id: 'q02', role: MessageRole.assistant, createdAt: t(1),
          content: 'Quantum entanglement is one of the most fascinating phenomena '
              'in physics.\n\nImagine two coins that are "entangled." When you flip '
              'them and one lands heads, the other *instantly* lands tails — no '
              'matter how far apart they are.\n\nBefore you look at either coin, '
              'neither has a definite state. They exist in a superposition of both '
              'heads *and* tails simultaneously.'),
      ChatMessage(id: 'q03', role: MessageRole.user, createdAt: t(3),
          content: 'Does that mean information travels faster than light?'),
      ChatMessage(id: 'q04', role: MessageRole.assistant, createdAt: t(4),
          content: "No — and this is where it gets subtle.\n\nEntanglement doesn't "
              "allow faster-than-light communication. You can't *control* which "
              'result you get, so you can\'t use it to send information.\n\n'
              'Einstein called it "spooky action at a distance." Bell\'s theorem '
              '(1964) and subsequent experiments proved entanglement is real.'),
      ChatMessage(id: 'q05', role: MessageRole.user, createdAt: t(6),
          content: "What is Bell's theorem exactly?"),
      ChatMessage(id: 'q06', role: MessageRole.assistant, createdAt: t(7),
          content: "Bell's theorem shows that no *local hidden variable* theory can "
              'reproduce all the predictions of quantum mechanics.\n\n'
              'In plain language: there is no way to explain correlations between '
              'entangled particles by pre-assigning hidden properties at the moment '
              'of creation. The particles genuinely do not have definite values '
              "until measured — it isn't just ignorance on our part."),
      ChatMessage(id: 'q07', role: MessageRole.user, createdAt: t(9),
          content: 'What are some practical applications of entanglement?'),
      ChatMessage(id: 'q08', role: MessageRole.assistant, createdAt: t(10),
          content: 'Three major categories:\n\n'
              '**1. Quantum key distribution (QKD)**\n'
              'Entangled photons enable cryptographic keys whose security is '
              'guaranteed by physics — any eavesdropper disturbs the quantum state '
              'and is immediately detectable.\n\n'
              '**2. Quantum computing**\n'
              'Entanglement lets qubits represent correlated states exponentially '
              'more compactly than classical bits, enabling algorithms like '
              "Shor's (factoring) and Grover's (search).\n\n"
              '**3. Quantum sensing**\n'
              'Entangled probes can measure physical quantities (time, force, '
              'distance) with precision beyond classical limits.'),
      ChatMessage(id: 'q09', role: MessageRole.user, createdAt: t(12),
          content: 'How does quantum cryptography work?'),
      ChatMessage(id: 'q10', role: MessageRole.assistant, createdAt: t(13),
          content: 'The most common protocol is **BB84** (Bennett & Brassard, 1984):\n\n'
              '```\nAlice  →  photons in random bases  →  Bob\nAlice ←← "which bases did you use?" ←← Bob\n'
              'Both keep bits where bases matched → secret key\nEve\'s measurement disturbs photons → detected\n```\n\n'
              'Entanglement-based QKD (E91 protocol) goes further: both parties '
              'measure entangled photon pairs. Security is guaranteed by '
              "Bell's inequality — if the inequality holds, no eavesdropper "
              'intercepted the channel.'),
      ChatMessage(id: 'q11', role: MessageRole.user, createdAt: t(15),
          content: 'Can entangled particles actually be created in a lab?'),
      ChatMessage(id: 'q12', role: MessageRole.assistant, createdAt: t(16),
          content: 'Yes — routinely.\n\nThe most common method is **spontaneous '
              'parametric down-conversion (SPDC)**: a laser photon passes through '
              'a nonlinear crystal and splits into two lower-energy photons with '
              'correlated polarisations.\n\n'
              "Another route is **trapped ions**: two ions in an electromagnetic "
              'trap can be entangled via their shared phonon modes using laser '
              'pulses. IBM, Google, and IonQ all use variants of this for their '
              'quantum processors.'),
      ChatMessage(id: 'q13', role: MessageRole.user, createdAt: t(18),
          content: 'How do you verify that two particles are actually entangled?'),
      ChatMessage(id: 'q14', role: MessageRole.assistant, createdAt: t(19),
          content: 'Via a **Bell test experiment**:\n\n'
              '1. Prepare many pairs of particles claimed to be entangled.\n'
              '2. Measure each particle in a randomly chosen basis (angle).\n'
              '3. Compute the **CHSH correlation** S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′).\n'
              '4. Classical (local-hidden-variable) theories predict |S| ≤ 2.\n'
              '   Quantum mechanics predicts S up to 2√2 ≈ 2.83.\n\n'
              'If you measure S > 2, the particles are genuinely entangled. '
              'The 2015 Delft "loophole-free" Bell test was the first to close '
              'all classical loopholes simultaneously.'),
      ChatMessage(id: 'q15', role: MessageRole.user, createdAt: t(21),
          content: 'What is quantum teleportation?'),
      ChatMessage(id: 'q16', role: MessageRole.assistant, createdAt: t(22),
          content: 'Quantum teleportation transfers an **unknown quantum state** '
              'from one particle to another — even across a distance — using:\n\n'
              '1. A pre-shared entangled pair (one at Alice, one at Bob).\n'
              '2. Alice performs a joint measurement on her particle + the target '
              'state, collapsing both.\n'
              '3. Alice sends Bob **2 classical bits** describing the outcome.\n'
              '4. Bob applies one of 4 unitary corrections → his particle is now '
              'in the original state.\n\n'
              'No physical matter moves. The state is "teleported", not the particle.'),
      ChatMessage(id: 'q17', role: MessageRole.user, createdAt: t(24),
          content: 'What is decoherence and why does it matter?'),
      ChatMessage(id: 'q18', role: MessageRole.assistant, createdAt: t(25),
          content: 'Decoherence is the process by which a quantum system **loses '
              'its quantum character** through interaction with its environment.\n\n'
              'Every stray photon, phonon, or electromagnetic fluctuation that '
              'touches a qubit can "measure" it, collapsing its superposition and '
              'destroying entanglement. This is the central engineering challenge '
              'of quantum computing:\n\n'
              '- Superconducting qubits operate at ~15 mK (colder than outer space)\n'
              '- Coherence times: microseconds to milliseconds\n'
              '- Every gate takes ~10–50 ns, limiting circuit depth'),
      ChatMessage(id: 'q19', role: MessageRole.user, createdAt: t(27),
          content: 'How does quantum error correction help?'),
      ChatMessage(id: 'q20', role: MessageRole.assistant, createdAt: t(28),
          content: 'Quantum error correction (QEC) encodes **one logical qubit** '
              'across many physical qubits so errors can be detected and corrected '
              'without measuring (and collapsing) the logical state.\n\n'
              '```\nLogical |0⟩ → spread across 7 physical qubits (Steane code)\nSyndrome measurements detect errors without revealing the state\nCorrection unitaries restore the logical qubit\n```\n\n'
              'The **surface code** (Google, IBM) is the leading practical approach: '
              '~1000 physical qubits per error-corrected logical qubit at current '
              'error rates. At 99.9% gate fidelity that drops to ~100:1.'),
      ChatMessage(id: 'q21', role: MessageRole.user, createdAt: t(30),
          content: 'How close are we to practical quantum computers?'),
      ChatMessage(id: 'q22', role: MessageRole.assistant, createdAt: t(31),
          content: 'We are in the **NISQ era** (Noisy Intermediate-Scale Quantum) — '
              'machines of 50–1000 qubits, not yet error-corrected.\n\n'
              'Recent milestones:\n'
              '- **Google Willow (2024)**: 105 qubits, demonstrated below-threshold '
              'error correction for the first time\n'
              '- **IBM Heron (2024)**: 133 qubits, ~0.2% 2-qubit error rate\n'
              '- **Microsoft (2025)**: topological qubit prototype announced\n\n'
              'Consensus estimate for cryptographically relevant fault-tolerant '
              'quantum computers: **10–15 years** at current trajectory. '
              "Quantum advantage for useful (not just benchmark) tasks is likely "
              'within 5 years in specific domains like materials simulation.'),
    ];
  }

  static List<ChatMessage> _seedPython() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'p1', role: MessageRole.user, createdAt: t(0),
          content: 'I need a Python script to batch process CSV files — '
              'rename columns, filter rows, and output to a new folder.'),
      ChatMessage(id: 'p2', role: MessageRole.assistant, createdAt: t(3),
          content: '```python\nimport pandas as pd\nfrom pathlib import Path\n\n'
              "def process_csv(src: Path, dst: Path) -> None:\n    df = pd.read_csv(src)\n"
              "    df.rename(columns={'old_name': 'new_name'}, inplace=True)\n"
              "    df = df[df['status'] == 'active']\n    df.to_csv(dst, index=False)\n\n"
              "def batch_process(input_dir: str, output_dir: str) -> None:\n"
              '    src_dir = Path(input_dir)\n    dst_dir = Path(output_dir)\n'
              '    dst_dir.mkdir(parents=True, exist_ok=True)\n'
              "    for csv_file in src_dir.glob('*.csv'):\n"
              "        process_csv(csv_file, dst_dir / csv_file.name)\n"
              "        print(f'Processed {csv_file.name}')\n\n"
              "if __name__ == '__main__':\n    batch_process('./input', './output')\n```\n\n"
              'Want me to add async support or better error handling?'),
    ];
  }

  static List<ChatMessage> _seedReact() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'r1', role: MessageRole.user, createdAt: t(0),
          content: 'What are the most important React hooks best practices '
              'people miss?'),
      ChatMessage(id: 'r2', role: MessageRole.assistant, createdAt: t(3),
          content: 'Here are the ones I see missed most often:\n\n'
              '**1. useEffect cleanup**\n'
              'Always return a cleanup function:\n'
              '```js\nuseEffect(() => {\n  const id = setInterval(() => setCount(c => c + 1), 1000);\n'
              '  return () => clearInterval(id);\n}, []);\n```\n\n'
              '**2. Stale closures in callbacks**\n'
              'Include all values used inside an effect in the dependency array, '
              'or use `useRef` to hold the latest value.\n\n'
              '**3. Initialiser functions in useState**\n'
              '```js\n// ❌ Runs every render\nconst [s] = useState(heavyComputation());\n'
              '// ✅ Runs once\nconst [s] = useState(() => heavyComputation());\n```'),
    ];
  }

  static List<ChatMessage> _seedJapan() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'j1', role: MessageRole.user, createdAt: t(0),
          content: "I'm planning a 2-week trip to Japan. What's the best time to go "
              'and which cities should I prioritise?'),
      ChatMessage(id: 'j2', role: MessageRole.assistant, createdAt: t(4),
          content: 'For cherry blossom season, **March–April in Tokyo** is perfect — '
              'typically peak bloom is late March to early April.\n\n'
              'A solid 2-week itinerary:\n\n'
              '**Days 1–5 — Tokyo**\nShinjuku, Shibuya, Asakusa, Akihabara, Harajuku. '
              'Day trip to Nikko or Kamakura.\n\n'
              '**Days 6–8 — Kyoto**\nFushimi Inari, Arashiyama, Nishiki Market, '
              'geisha districts in Gion.\n\n'
              '**Days 9–10 — Osaka**\nDotonbori street food, Osaka Castle, day trip '
              'to Nara (free-roaming deer!).\n\n'
              '**Days 11–12 — Hiroshima & Miyajima**\nPeace Memorial Museum and the '
              'iconic floating torii gate.\n\n'
              '**Days 13–14 — back to Tokyo** for shopping and final meals.'),
      ChatMessage(id: 'j3', role: MessageRole.user, createdAt: t(8),
          content: 'What JR pass options should I consider?'),
      ChatMessage(id: 'j4', role: MessageRole.assistant, createdAt: t(11),
          content: 'For the Tokyo → Kyoto → Osaka → Hiroshima → Tokyo loop, the '
              '**14-day JR Pass** (¥50,000 / ~\$330) covers:\n\n'
              '- All Shinkansen (bullet train) legs\n'
              '- Most JR local lines\n'
              '- Miyajima ferry\n\n'
              'Break-even calculation: Tokyo–Kyoto Shinkansen alone is ¥14,000 each '
              'way → two legs = ¥28,000. Add Kyoto–Hiroshima, Hiroshima–Tokyo and '
              'you easily exceed the pass cost.\n\n'
              'Buy online before you travel — prices increased 60% in 2023 for '
              'in-country purchases. IC cards (Suica/Pasmo) still needed for '
              'subway and bus inside each city.'),
    ];
  }

  static List<ChatMessage> _seedTypeScript() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'ts1', role: MessageRole.user, createdAt: t(0),
          content: "I'm confused why my conditional type isn't distributing "
              'correctly over a union. Can you explain?'),
      ChatMessage(id: 'ts2', role: MessageRole.assistant, createdAt: t(4),
          content: "Conditional types **don't distribute over union types** the way "
              "you'd expect when the checked type is a naked type parameter.\n\n"
              '```ts\ntype IsString<T> = T extends string ? "yes" : "no";\n\n'
              '// Distributes — each member checked separately:\ntype R1 = IsString<string | number>;\n'
              '// → "yes" | "no"\n\n'
              '// No distribution — T is wrapped, not naked:\ntype IsStringArr<T> = [T] extends [string] ? "yes" : "no";\n'
              'type R2 = IsStringArr<string | number>;\n// → "no"\n```\n\n'
              'Use `[T]` wrapping to **disable distribution** when you want to treat '
              'the union as a whole.'),
      ChatMessage(id: 'ts3', role: MessageRole.user, createdAt: t(8),
          content: 'How do I extract only the string keys from an object type?'),
      ChatMessage(id: 'ts4', role: MessageRole.assistant, createdAt: t(11),
          content: '```ts\ntype StringKeys<T> = {\n  [K in keyof T]: T[K] extends string ? K : never;\n}[keyof T];\n\n'
              'type User = { id: number; name: string; email: string; age: number };\ntype StringFields = StringKeys<User>;\n'
              '// → "name" | "email"\n```\n\n'
              'The `[keyof T]` at the end is a **lookup type** that collapses the '
              'mapped object into a union — the `never` values are automatically '
              'removed from the union.'),
    ];
  }

  static List<ChatMessage> _seedCoverLetter() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'cl1', role: MessageRole.user, createdAt: t(0),
          content: 'Can you help me write a cover letter for a senior software '
              'engineer role at a Series B fintech startup?'),
      ChatMessage(id: 'cl2', role: MessageRole.assistant, createdAt: t(5),
          content: "Here's a strong opening — leading with impact rather than "
              '"I am applying for…":\n\n'
              '---\n'
              'Over the past six years I have scaled two payment platforms from '
              'prototype to millions of transactions per day, cutting p99 latency '
              'by 40% at one and reducing infrastructure cost by \$1.2 M/year at the '
              'other. When I read about [Company]\'s mission to democratise '
              'cross-border payments for SMEs, I recognised the same problem I\'ve '
              'been obsessed with solving.\n\n'
              'In my current role at [Current Company] I lead a six-engineer team '
              'responsible for the core transaction engine…\n'
              '---\n\n'
              "What's your current role and the specific company? I'll tailor this "
              'further with your real metrics.'),
      ChatMessage(id: 'cl3', role: MessageRole.user, createdAt: t(9),
          content: 'That opening paragraph is much better. Can you revise it to '
              'lead with the impact metric more boldly?'),
      ChatMessage(id: 'cl4', role: MessageRole.assistant, createdAt: t(12),
          content: "I've revised the opening paragraph to lead with impact:\n\n"
              '---\n'
              '\$1.2 M in annual infrastructure savings. 40% p99 latency reduction. '
              'Two payment platforms scaled to millions of daily transactions. '
              "These aren't lines from a résumé — they're the outcomes I delivered "
              'in my last two engineering roles, and exactly the kind of impact I '
              'want to bring to [Company].\n'
              '---\n\n'
              "This version opens with numbers, which immediately signals you're "
              'results-oriented. The rhetorical turn ("These aren\'t lines…") keeps '
              'it from feeling like a bullet-point dump.'),
    ];
  }

  static List<ChatMessage> _seedSql() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'sql1', role: MessageRole.user, createdAt: t(0),
          content: 'My JOIN query is taking 4 seconds on a table with 5M rows. '
              'Here\'s the query:\n\n'
              '```sql\nSELECT o.id, o.total, u.name\nFROM orders o\nJOIN users u ON u.id = o.user_id\n'
              "WHERE o.created_at > '2024-01-01'\nORDER BY o.created_at DESC;\n```"),
      ChatMessage(id: 'sql2', role: MessageRole.assistant, createdAt: t(5),
          content: 'A composite index on `(user_id, created_at)` should cut that '
              'from 4 s to **under 50 ms**.\n\n'
              '```sql\nCREATE INDEX idx_orders_user_created\n  ON orders (user_id, created_at DESC);\n```\n\n'
              'Why this helps:\n'
              '- The `WHERE created_at > …` filter can now use the index range scan '
              'instead of a full table scan.\n'
              '- The `ORDER BY created_at DESC` matches the index direction — '
              'no sort step needed.\n'
              '- The JOIN to `users` only runs on the already-filtered result set.\n\n'
              'Run `EXPLAIN ANALYZE` before and after to confirm. If `created_at` '
              'cardinality is low (e.g. millions of rows per day), add a partial '
              "index: `WHERE created_at > '2023-01-01'`."),
      ChatMessage(id: 'sql3', role: MessageRole.user, createdAt: t(9),
          content: 'EXPLAIN ANALYZE shows a Seq Scan on orders even with the index. Why?'),
      ChatMessage(id: 'sql4', role: MessageRole.assistant, createdAt: t(12),
          content: 'The planner chose a sequential scan because it estimated it would '
              'be cheaper — likely one of:\n\n'
              '**1. Stale statistics**\n'
              '`ANALYZE orders;` — the planner may think far fewer rows match the '
              'filter than actually do.\n\n'
              '**2. Low selectivity**\n'
              'If `created_at > 2024-01-01` matches > ~20% of rows, a seq scan + '
              'sort is often faster than random I/O through an index.\n\n'
              '**3. Index not yet used due to fill factor**\n'
              'Force the planner to test the index: '
              '`SET enable_seqscan = off;` then re-run. If it\'s dramatically '
              'faster, run `ANALYZE` and the planner should pick it naturally.'),
    ];
  }

  static List<ChatMessage> _seedMonads() {
    DateTime t(int s) => _t0.add(Duration(seconds: s));
    return [
      ChatMessage(id: 'm1', role: MessageRole.user, createdAt: t(0),
          content: "I keep hearing about monads in functional programming but I can't "
              "wrap my head around them. I'm a JavaScript dev."),
      ChatMessage(id: 'm2', role: MessageRole.assistant, createdAt: t(5),
          content: "Here's the thing: **you've been using monads already** — "
              '`Promise` is one.\n\n'
              'A monad is just a design pattern with three rules:\n\n'
              '1. **Wrap a value**: `Promise.resolve(42)`\n'
              '2. **Chain transformations**: `.then(x => x * 2)` — '
              'the callback returns either a plain value or another Promise, '
              'and `.then` "flattens" nested Promises automatically.\n'
              '3. **Preserve structure**: chaining never double-wraps '
              '(`Promise<Promise<T>>` becomes `Promise<T>`).\n\n'
              'Array is also monad-like: `flatMap` is the monadic "bind".\n\n'
              '```js\n[1, 2, 3].flatMap(x => [x, x * 2])\n// → [1, 2, 2, 4, 3, 6]\n```\n\n'
              'The formal definition adds nothing useful until you need to compose '
              'many of these patterns — then the laws (left identity, right '
              'identity, associativity) are what guarantee your chains work '
              'predictably.'),
      ChatMessage(id: 'm3', role: MessageRole.user, createdAt: t(9),
          content: 'What about the Maybe monad? When would I use that in JS?'),
      ChatMessage(id: 'm4', role: MessageRole.assistant, createdAt: t(13),
          content: 'The **Maybe monad** handles nullable values without nested `if` checks.\n\n'
              'In modern JS you get it for free with **optional chaining**:\n\n'
              '```js\n// Without Maybe:\nconst street = user && user.address && user.address.street;\n\n'
              '// With optional chaining (Maybe semantics built into the language):\nconst street = user?.address?.street;\n```\n\n'
              'If any step is `null`/`undefined`, the whole expression short-circuits '
              'to `undefined` — exactly like a Maybe chain returning `Nothing`.\n\n'
              'Libraries like `fp-ts` give you an explicit `Option<T>` type if you '
              'want the full type-safe version with `map`, `chain`, and `fold`.'),
    ];
  }
}
