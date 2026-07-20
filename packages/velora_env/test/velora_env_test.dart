import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_env/velora_env.dart';

void main() {
  group('parseEnv', () {
    test('ignores blank lines and full-line comments', () {
      final result = parseEnv('''
# this is a comment
FOO=bar

# another comment
BAZ=qux
''');
      expect(result, {'FOO': 'bar', 'BAZ': 'qux'});
    });

    test('strips an optional leading "export " prefix', () {
      final result = parseEnv('export FOO=bar\nexport   BAZ=qux');
      expect(result, {'FOO': 'bar', 'BAZ': 'qux'});
    });

    test('strips matching single quotes literally (no escape processing)', () {
      // A plain (non-raw) Dart string: `\\n` and `\\\"` each collapse to the
      // two literal characters backslash+n / backslash+quote, which is
      // exactly the raw .env text parseEnv should see -- and, since this is
      // a *single*-quoted .env value, pass through completely unprocessed.
      final content = "FOO='bar \\n baz \\\" qux'";
      final result = parseEnv(content);
      expect(result['FOO'], r'bar \n baz \" qux');
    });

    test('strips matching double quotes and interprets escapes', () {
      final result = parseEnv(r'FOO="line1\nline2\ttabbed\"quoted\"\\slash"');
      expect(result['FOO'], 'line1\nline2\ttabbed"quoted"\\slash');
    });

    test('strips a trailing inline comment on unquoted values', () {
      final result = parseEnv('FOO=bar # this is a comment');
      expect(result['FOO'], 'bar');
    });

    test(
      'does not strip a "#" that is part of a quoted value',
      () {
        final result = parseEnv('FOO="bar # not a comment"');
        expect(result['FOO'], 'bar # not a comment');
      },
    );

    test('skips malformed lines instead of throwing', () {
      final result = parseEnv('''
this is not valid
=noKey
1BAD=starts-with-digit
FOO=bar
''');
      expect(result, {'FOO': 'bar'});
    });

    test('later duplicate keys override earlier ones', () {
      final result = parseEnv('FOO=first\nFOO=second');
      expect(result['FOO'], 'second');
    });

    test('trims unquoted values', () {
      final result = parseEnv('FOO=   bar   ');
      expect(result['FOO'], 'bar');
    });
  });

  group('VeloraEnv', () {
    tearDown(VeloraEnv.reset);

    test('get returns the value or fallback', () {
      VeloraEnv.loadFromMap({'FOO': 'bar'});
      expect(VeloraEnv.get('FOO'), 'bar');
      expect(VeloraEnv.get('MISSING'), isNull);
      expect(VeloraEnv.get('MISSING', fallback: 'default'), 'default');
    });

    test('require returns the value or throws StateError when absent', () {
      VeloraEnv.loadFromMap({'FOO': 'bar', 'EMPTY': ''});
      expect(VeloraEnv.require('FOO'), 'bar');
      expect(() => VeloraEnv.require('MISSING'), throwsStateError);
      expect(() => VeloraEnv.require('EMPTY'), throwsStateError);
    });

    test('has reflects presence of a non-empty value', () {
      VeloraEnv.loadFromMap({'FOO': 'bar', 'EMPTY': ''});
      expect(VeloraEnv.has('FOO'), isTrue);
      expect(VeloraEnv.has('EMPTY'), isFalse);
      expect(VeloraEnv.has('MISSING'), isFalse);
    });

    test('getBool recognizes truthy variants case-insensitively', () {
      VeloraEnv.loadFromMap({
        'A': 'true',
        'B': '1',
        'C': 'yes',
        'D': 'on',
        'E': 'TRUE',
        'F': 'false',
        'G': '0',
        'H': 'nah',
      });
      expect(VeloraEnv.getBool('A'), isTrue);
      expect(VeloraEnv.getBool('B'), isTrue);
      expect(VeloraEnv.getBool('C'), isTrue);
      expect(VeloraEnv.getBool('D'), isTrue);
      expect(VeloraEnv.getBool('E'), isTrue);
      expect(VeloraEnv.getBool('F'), isFalse);
      expect(VeloraEnv.getBool('G'), isFalse);
      expect(VeloraEnv.getBool('H'), isFalse);
      expect(VeloraEnv.getBool('MISSING'), isFalse);
      expect(VeloraEnv.getBool('MISSING', fallback: true), isTrue);
    });

    test('getInt parses ints and falls back otherwise', () {
      VeloraEnv.loadFromMap({'PORT': '8080', 'BAD': 'nope'});
      expect(VeloraEnv.getInt('PORT'), 8080);
      expect(VeloraEnv.getInt('MISSING'), isNull);
      expect(VeloraEnv.getInt('MISSING', fallback: 42), 42);
      expect(VeloraEnv.getInt('BAD', fallback: 7), 7);
    });

    test('getDouble parses doubles and falls back otherwise', () {
      VeloraEnv.loadFromMap({'RATE': '1.5', 'BAD': 'nope'});
      expect(VeloraEnv.getDouble('RATE'), 1.5);
      expect(VeloraEnv.getDouble('MISSING'), isNull);
      expect(VeloraEnv.getDouble('MISSING', fallback: 2.5), 2.5);
      expect(VeloraEnv.getDouble('BAD', fallback: 9.9), 9.9);
    });

    test('all is unmodifiable and reflects loaded values', () {
      VeloraEnv.loadFromMap({'FOO': 'bar'});
      final all = VeloraEnv.all;
      expect(all, {'FOO': 'bar'});
      expect(() => all['NEW'] = 'value', throwsUnsupportedError);
    });

    test('reset clears loaded values and isLoaded', () {
      VeloraEnv.loadFromMap({'FOO': 'bar'});
      expect(VeloraEnv.isLoaded, isTrue);
      VeloraEnv.reset();
      expect(VeloraEnv.isLoaded, isFalse);
      expect(VeloraEnv.all, isEmpty);
      expect(VeloraEnv.get('FOO'), isNull);
    });

    test('loadFromMap without merge replaces prior values', () {
      VeloraEnv.loadFromMap({'FOO': 'bar', 'KEEP': 'no'});
      VeloraEnv.loadFromMap({'FOO': 'baz'});
      expect(VeloraEnv.get('FOO'), 'baz');
      expect(VeloraEnv.get('KEEP'), isNull);
    });

    test('loadFromMap with merge: true merges over prior values', () {
      VeloraEnv.loadFromMap({'FOO': 'bar', 'KEEP': 'yes'});
      VeloraEnv.loadFromMap({'FOO': 'baz'}, merge: true);
      expect(VeloraEnv.get('FOO'), 'baz');
      expect(VeloraEnv.get('KEEP'), 'yes');
    });

    test('loadFromString parses and stores parsed values', () {
      VeloraEnv.loadFromString('FOO=bar\nBAZ=qux');
      expect(VeloraEnv.get('FOO'), 'bar');
      expect(VeloraEnv.get('BAZ'), 'qux');
      expect(VeloraEnv.isLoaded, isTrue);
    });

    test('loadFromString merge: true merges over prior values', () {
      VeloraEnv.loadFromString('FOO=bar\nKEEP=yes');
      VeloraEnv.loadFromString('FOO=baz', merge: true);
      expect(VeloraEnv.get('FOO'), 'baz');
      expect(VeloraEnv.get('KEEP'), 'yes');
    });
  });

  group('VeloraEnv.pickFor / pick', () {
    tearDown(VeloraEnv.reset);

    test('returns the per-environment value when supplied', () {
      final value = VeloraEnv.pickFor(
        VeloraEnvironment.staging,
        dev: 'dev-url',
        staging: 'staging-url',
        prod: 'prod-url',
      );
      expect(value, 'staging-url');
    });

    test('staging/prod fall back to dev when not supplied', () {
      expect(
        VeloraEnv.pickFor(VeloraEnvironment.staging, dev: 'dev-url'),
        'dev-url',
      );
      expect(
        VeloraEnv.pickFor(VeloraEnvironment.prod, dev: 'dev-url'),
        'dev-url',
      );
    });

    test('dev environment always returns dev', () {
      expect(
        VeloraEnv.pickFor(
          VeloraEnvironment.dev,
          dev: 'dev-url',
          staging: 'staging-url',
        ),
        'dev-url',
      );
    });
  });

  group('VeloraEnvironment.parse', () {
    test('recognizes canonical names and aliases case-insensitively', () {
      expect(VeloraEnvironment.parse('dev'), VeloraEnvironment.dev);
      expect(VeloraEnvironment.parse('DEV'), VeloraEnvironment.dev);
      expect(
        VeloraEnvironment.parse('development'),
        VeloraEnvironment.dev,
      );
      expect(VeloraEnvironment.parse('staging'), VeloraEnvironment.staging);
      expect(VeloraEnvironment.parse('Stag'), VeloraEnvironment.staging);
      expect(VeloraEnvironment.parse('prod'), VeloraEnvironment.prod);
      expect(
        VeloraEnvironment.parse('PRODUCTION'),
        VeloraEnvironment.prod,
      );
    });

    test('falls back to the given fallback (default dev) for unknown input', () {
      expect(VeloraEnvironment.parse(null), VeloraEnvironment.dev);
      expect(VeloraEnvironment.parse(''), VeloraEnvironment.dev);
      expect(VeloraEnvironment.parse('nonsense'), VeloraEnvironment.dev);
      expect(
        VeloraEnvironment.parse(
          'nonsense',
          fallback: VeloraEnvironment.prod,
        ),
        VeloraEnvironment.prod,
      );
    });
  });

  group('VeloraEnv.load', () {
    tearDown(VeloraEnv.reset);

    test('resolves base + flavor assets and merges flavor over base', () async {
      final bundle = _FakeAssetBundle({
        'assets/env/.env': 'SHARED=base\nAPI_URL=https://dev.example.test',
        'assets/env/.env.staging':
            'API_URL=https://staging.example.test\nSTAGING_ONLY=yes',
      });

      await VeloraEnv.load(
        environment: VeloraEnvironment.staging,
        bundle: bundle,
      );

      expect(VeloraEnv.get('SHARED'), 'base');
      expect(VeloraEnv.get('API_URL'), 'https://staging.example.test');
      expect(VeloraEnv.get('STAGING_ONLY'), 'yes');
    });

    test('a missing flavor asset is tolerated', () async {
      final bundle = _FakeAssetBundle({
        'assets/env/.env': 'SHARED=base',
      });

      await VeloraEnv.load(
        environment: VeloraEnvironment.prod,
        bundle: bundle,
      );

      expect(VeloraEnv.get('SHARED'), 'base');
      expect(VeloraEnv.isLoaded, isTrue);
    });

    test('a missing base asset is also tolerated', () async {
      final bundle = _FakeAssetBundle({
        'assets/env/.env.dev': 'ONLY=dev-value',
      });

      await VeloraEnv.load(environment: VeloraEnvironment.dev, bundle: bundle);

      expect(VeloraEnv.get('ONLY'), 'dev-value');
    });

    test('an explicit asset path is loaded exactly as given', () async {
      final bundle = _FakeAssetBundle({
        'assets/custom.env': 'CUSTOM=1',
      });

      await VeloraEnv.load(asset: 'assets/custom.env', bundle: bundle);

      expect(VeloraEnv.get('CUSTOM'), '1');
    });

    test('an explicit missing asset surfaces its error', () async {
      final bundle = _FakeAssetBundle({});

      expect(
        () => VeloraEnv.load(asset: 'assets/missing.env', bundle: bundle),
        throwsA(anything),
      );
    });
  });

  group('VeloraEnvPlugin', () {
    setUp(() => Get.testMode = true);
    tearDown(() {
      Get.reset();
      VeloraEnv.reset();
    });

    test(
      'register() loads env via the injected bundle/environment and puts a '
      'resolvable VeloraEnvService',
      () async {
        final bundle = _FakeAssetBundle({
          'assets/env/.env.staging': 'API_URL=https://staging.example.test',
        });

        const config = VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        );
        final context = VeloraContext(config);

        final plugin = VeloraEnvPlugin(
          environment: VeloraEnvironment.staging,
          bundle: bundle,
        );
        await plugin.register(context);

        expect(VeloraEnv.get('API_URL'), 'https://staging.example.test');
        final service = Get.find<VeloraEnvService>();
        expect(service.environment, VeloraEnvironment.staging);
        expect(service.get('API_URL'), 'https://staging.example.test');
      },
    );

    test(
      'register() does not throw when loadIfNeeded is true and no assets '
      'exist -- boot continues without crashing',
      () async {
        const config = VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        );
        final context = VeloraContext(config);

        final plugin = VeloraEnvPlugin(
          asset: 'assets/definitely-missing.env',
        );

        await plugin.register(context);

        expect(Get.find<VeloraEnvService>(), isA<VeloraEnvService>());
      },
    );

    test(
      'register() with loadIfNeeded: false does not call load, but still '
      'registers the service',
      () async {
        const config = VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        );
        final context = VeloraContext(config);

        final plugin = VeloraEnvPlugin(loadIfNeeded: false);
        await plugin.register(context);

        expect(VeloraEnv.isLoaded, isFalse);
        expect(Get.find<VeloraEnvService>(), isA<VeloraEnvService>());
      },
    );

    test(
      'register() skips loading when VeloraEnv is already loaded',
      () async {
        VeloraEnv.loadFromMap({'ALREADY': 'loaded'});

        const config = VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        );
        final context = VeloraContext(config);

        final plugin = VeloraEnvPlugin(
          asset: 'assets/definitely-missing.env',
        );
        await plugin.register(context);

        // Still loaded with the pre-existing value -- the plugin didn't
        // attempt (and fail/override via) its own load call.
        expect(VeloraEnv.get('ALREADY'), 'loaded');
      },
    );
  });
}

/// A minimal in-memory [AssetBundle] for tests, backed by a fixed map of
/// asset key -> string content. Throws a [FlutterError] for unknown keys,
/// matching the "throws if not found" contract real asset bundles follow.
class _FakeAssetBundle extends AssetBundle {
  final Map<String, String> _assets;

  _FakeAssetBundle(this._assets);

  @override
  Future<ByteData> load(String key) async {
    final content = _assets[key];
    if (content == null) {
      throw FlutterError('Fake asset not found: $key');
    }
    final bytes = Uint8List.fromList(content.codeUnits);
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = _assets[key];
    if (content == null) {
      throw FlutterError('Fake asset not found: $key');
    }
    return content;
  }
}
