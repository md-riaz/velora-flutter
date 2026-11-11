/// A small Dart source scanner that reads one top-level declaration: its doc
/// comment, constructors, parameters, enum values, and static methods.
///
/// It reads the installed package's own source, so the answer always matches
/// the installed version. It is not a full parser: it understands the shapes
/// used for public widget APIs (classes, enums, extensions, mixins, typedefs,
/// top-level functions) and leaves a type `null` when it cannot read one.
library;

/// One parameter of a constructor, method, or function.
class DartParameter {
  final String name;

  /// The declared type, or `null` when it could not be determined.
  final String? type;

  /// `positional`, `optionalPositional`, or `named`.
  final String kind;
  final bool isRequired;
  final String? defaultValue;
  final String documentation;

  const DartParameter({
    required this.name,
    required this.type,
    required this.kind,
    required this.isRequired,
    required this.defaultValue,
    required this.documentation,
  });

  Map<String, Object?> toJson({bool full = true}) => {
    'name': name,
    'type': type,
    'kind': kind,
    'required': isRequired,
    if (defaultValue != null) 'default': defaultValue,
    if (full && documentation.isNotEmpty) 'documentation': documentation,
  };
}

/// A constructor, static method, or top-level function.
class DartSignature {
  /// The callable's name. For a constructor, the class name, or
  /// `Class.named` for a named constructor.
  final String name;
  final String? returnType;
  final bool isConst;
  final bool isFactory;
  final List<DartParameter> parameters;
  final String documentation;

  const DartSignature({
    required this.name,
    required this.parameters,
    this.returnType,
    this.isConst = false,
    this.isFactory = false,
    this.documentation = '',
  });

  Map<String, Object?> toJson({bool full = true}) => {
    'name': name,
    if (returnType != null) 'returns': returnType,
    if (isConst) 'const': true,
    if (isFactory) 'factory': true,
    if (full && documentation.isNotEmpty) 'documentation': documentation,
    'parameters': [for (final p in parameters) p.toJson(full: full)],
  };
}

/// An enum value and its doc comment.
class DartEnumValue {
  final String name;
  final String documentation;

  const DartEnumValue(this.name, this.documentation);
}

/// A scanned top-level declaration.
class DartDeclaration {
  /// `class`, `enum`, `mixin`, `extension`, `typedef`, or `function`.
  final String kind;
  final String name;

  /// The whole doc comment, without the `///` markers.
  final String documentation;

  /// The type an extension applies to.
  final String? on;
  final List<DartSignature> constructors;
  final List<DartSignature> staticMethods;
  final List<DartEnumValue> values;

  /// Names of an extension's or mixin's getters and methods.
  final List<String> members;

  /// The signature of a top-level function.
  final DartSignature? signature;

  const DartDeclaration({
    required this.kind,
    required this.name,
    required this.documentation,
    this.on,
    this.constructors = const [],
    this.staticMethods = const [],
    this.values = const [],
    this.members = const [],
    this.signature,
  });

  /// The first paragraph of [documentation] on one line.
  String get summary => documentation
      .split(RegExp(r'\n\s*\n'))
      .first
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Scans [source] for the top-level declaration called [name]. Returns
/// `null` when there is none.
DartDeclaration? scanDeclaration(String source, String name) {
  final code = _codeMask(source);
  final escaped = RegExp.escape(name);

  final typeLike = RegExp(
    r'^(?:(?:abstract|final|sealed|base|interface|mixin)[ \t]+)*'
    '(class|enum|mixin|extension|typedef)[ \\t]+$escaped\\b',
    multiLine: true,
  );
  for (final match in typeLike.allMatches(source)) {
    if (!code[match.start]) continue;
    final kind = match.group(1)!;
    final documentation = _docBefore(source, match.start);
    if (kind == 'typedef') {
      return DartDeclaration(
        kind: kind,
        name: name,
        documentation: documentation,
      );
    }
    final open = _nextCode(source, code, match.end, '{;');
    if (open < 0 || source[open] == ';') {
      return DartDeclaration(
        kind: kind,
        name: name,
        documentation: documentation,
      );
    }
    final close = _matching(source, code, open);
    final header = source.substring(match.end, open);
    final body = source.substring(open + 1, close);
    return switch (kind) {
      'enum' => DartDeclaration(
        kind: kind,
        name: name,
        documentation: documentation,
        values: _enumValues(body),
        staticMethods: _staticMethods(body),
      ),
      'extension' || 'mixin' => DartDeclaration(
        kind: kind,
        name: name,
        documentation: documentation,
        on: RegExp(
          r'\bon\s+(.+?)\s*$',
          dotAll: true,
        ).firstMatch(header)?.group(1)?.replaceAll(RegExp(r'\s+'), ' '),
        members: _memberNames(body),
      ),
      _ => DartDeclaration(
        kind: kind,
        name: name,
        documentation: documentation,
        constructors: _constructors(body, name),
        staticMethods: _staticMethods(body),
      ),
    };
  }

  final function = RegExp(
    '^(?:([\\w<>?,.\\[\\] ]+?)[ \\t]+)?$escaped[ \\t]*(?:<[^>\\n]*>)?\\(',
    multiLine: true,
  );
  for (final match in function.allMatches(source)) {
    if (!code[match.start]) continue;
    final open = match.end - 1;
    final close = _matching(source, code, open);
    return DartDeclaration(
      kind: 'function',
      name: name,
      documentation: _docBefore(source, match.start),
      signature: DartSignature(
        name: name,
        returnType: match.group(1)?.trim(),
        parameters: _parameters(source.substring(open + 1, close), ''),
      ),
    );
  }
  return null;
}

// --- lexical helpers -------------------------------------------------------

/// For each character of [s]: `true` when it is code, `false` when it is
/// inside a comment or a string literal.
List<bool> _codeMask(String s) {
  final mask = List<bool>.filled(s.length, true);
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      var end = s.indexOf('\n', i);
      if (end < 0) end = s.length;
      mask.fillRange(i, end, false);
      i = end;
    } else if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      var end = s.indexOf('*/', i + 2);
      end = end < 0 ? s.length : end + 2;
      mask.fillRange(i, end, false);
      i = end;
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && s[i - 1] == 'r';
      final end = _skipString(s, i, raw);
      mask.fillRange(i, end, false);
      i = end;
    } else {
      i++;
    }
  }
  return mask;
}

/// Index just past the string literal that opens at [i].
int _skipString(String s, int i, bool raw) {
  final quote = s[i];
  final close = s.startsWith(quote * 3, i) ? quote * 3 : quote;
  var j = i + close.length;
  while (j < s.length) {
    if (!raw && s[j] == r'\') {
      j += 2;
    } else if (!raw && s[j] == r'$' && j + 1 < s.length && s[j + 1] == '{') {
      j += 2;
      var depth = 1;
      while (j < s.length && depth > 0) {
        final c = s[j];
        if (c == "'" || c == '"') {
          j = _skipString(s, j, false);
          continue;
        }
        if (c == '{') depth++;
        if (c == '}') depth--;
        j++;
      }
    } else if (s.startsWith(close, j)) {
      return j + close.length;
    } else {
      j++;
    }
  }
  return s.length;
}

/// Index of the first code character at or after [from] that is in [chars],
/// or -1.
int _nextCode(String s, List<bool> code, int from, String chars) {
  for (var i = from; i < s.length; i++) {
    if (code[i] && chars.contains(s[i])) return i;
  }
  return -1;
}

/// Index of the bracket closing the one at [open]; `s.length` if unbalanced.
int _matching(String s, List<bool> code, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (!code[i]) continue;
    final c = s[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return s.length;
}

/// Bracket depth of each character of [s] (0 at the top level). Angle
/// brackets count only where they read as type arguments.
List<int> _depths(String s, List<bool> code) {
  final depths = List<int>.filled(s.length, 0);
  var depth = 0;
  var angle = 0;
  for (var i = 0; i < s.length; i++) {
    if (!code[i]) {
      depths[i] = depth + angle;
      continue;
    }
    final c = s[i];
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == '>' && angle > 0 && (i == 0 || s[i - 1] != '=')) angle--;
    depths[i] = depth + angle;
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == '<' && i > 0 && RegExp(r'\w').hasMatch(s[i - 1])) angle++;
  }
  return depths;
}

/// Splits [s] on top-level commas that are code.
List<String> _splitTopLevel(String s) {
  final code = _codeMask(s);
  final depths = _depths(s, code);
  final parts = <String>[];
  var start = 0;
  for (var i = 0; i < s.length; i++) {
    if (code[i] && s[i] == ',' && depths[i] == 0) {
      parts.add(s.substring(start, i));
      start = i + 1;
    }
  }
  parts.add(s.substring(start));
  return parts;
}

/// [s] with comments removed and strings kept.
String _stripComments(String s) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      final end = s.indexOf('\n', i);
      i = end < 0 ? s.length : end;
    } else if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final end = s.indexOf('*/', i + 2);
      i = end < 0 ? s.length : end + 2;
    } else if (c == "'" || c == '"') {
      final end = _skipString(s, i, i > 0 && s[i - 1] == 'r');
      buffer.write(s.substring(i, end));
      i = end;
    } else {
      buffer.write(c);
      i++;
    }
  }
  return buffer.toString();
}

String _docLines(Iterable<String> lines) => lines
    .map((line) => line.trimLeft())
    .where((line) => line.startsWith('///'))
    .map((line) => line.substring(3).replaceFirst(RegExp('^ '), ''))
    .join('\n')
    .trim();

/// The `///` comment directly above the declaration that starts on the line
/// containing [offset], skipping annotations in between.
String _docBefore(String source, int offset) {
  final lineStart = source.lastIndexOf('\n', offset == 0 ? 0 : offset - 1) + 1;
  final before = source.substring(0, lineStart).split('\n');
  if (before.isNotEmpty && before.last.isEmpty) before.removeLast();
  final doc = <String>[];
  for (final line in before.reversed) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('///')) {
      doc.insert(0, line);
    } else if (trimmed.startsWith('@') && doc.isEmpty) {
      continue;
    } else {
      break;
    }
  }
  return _docLines(doc);
}

// --- members ---------------------------------------------------------------

List<DartEnumValue> _enumValues(String body) {
  final code = _codeMask(body);
  final depths = _depths(body, code);
  var end = body.length;
  for (var i = 0; i < body.length; i++) {
    if (code[i] && body[i] == ';' && depths[i] == 0) {
      end = i;
      break;
    }
  }
  final values = <DartEnumValue>[];
  for (final part in _splitTopLevel(body.substring(0, end))) {
    final name = RegExp(r'^(?:@\w+(?:\([^)]*\))?\s*)*(\w+)')
        .firstMatch(_stripComments(part).trim())
        ?.group(1);
    if (name == null) continue;
    values.add(DartEnumValue(name, _docLines(part.split('\n'))));
  }
  return values;
}

/// Whether the member starting at [index] of a class [body] is a
/// declaration: it sits at the top level of the body and follows the end of
/// another member (or nothing).
bool _startsMember(String body, List<bool> code, List<int> depths, int index) {
  if (!code[index] || depths[index] != 0) return false;
  for (var i = index - 1; i >= 0; i--) {
    if (!code[i] || body[i].trim().isEmpty) continue;
    return body[i] == ';' || body[i] == '}' || body[i] == ')';
  }
  return true;
}

List<DartSignature> _constructors(String body, String className) {
  final code = _codeMask(body);
  final depths = _depths(body, code);
  final pattern = RegExp(
    '(?:\\bconst\\s+)?(?:\\bfactory\\s+)?\\b'
    '${RegExp.escape(className)}(?:\\.(\\w+))?\\s*\\(',
  );
  final found = <DartSignature>[];
  for (final match in pattern.allMatches(body)) {
    if (!_startsMember(body, code, depths, match.start)) continue;
    final named = match.group(1);
    if (named != null && named.startsWith('_')) continue;
    final open = match.end - 1;
    final close = _matching(body, code, open);
    final text = match.group(0)!;
    found.add(
      DartSignature(
        name: named == null ? className : '$className.$named',
        isConst: text.startsWith('const'),
        isFactory: text.contains('factory'),
        documentation: _docBefore(body, match.start),
        parameters: _parameters(body.substring(open + 1, close), body),
      ),
    );
  }
  return found;
}

List<DartSignature> _staticMethods(String body) {
  final code = _codeMask(body);
  final depths = _depths(body, code);
  final pattern = RegExp(
    r'\bstatic\s+(?!const\b|final\b|late\b)([\w<>?,.\[\] ]+?)\s+(\w+)\s*'
    r'(?:<[^>(]*>)?\(',
  );
  final found = <DartSignature>[];
  for (final match in pattern.allMatches(body)) {
    if (!_startsMember(body, code, depths, match.start)) continue;
    final name = match.group(2)!;
    if (name.startsWith('_')) continue;
    final open = match.end - 1;
    final close = _matching(body, code, open);
    found.add(
      DartSignature(
        name: name,
        returnType: match.group(1)!.trim(),
        documentation: _docBefore(body, match.start),
        parameters: _parameters(body.substring(open + 1, close), ''),
      ),
    );
  }
  return found;
}

List<String> _memberNames(String body) {
  final code = _codeMask(body);
  final depths = _depths(body, code);
  final pattern = RegExp(
    r'^[ \t]*(?:static[ \t]+)?[\w<>?,.\[\] ]+?[ \t]+(?:get[ \t]+)?(\w+)[ \t]*'
    r'(?:<[^>(]*>)?(?:\(|=>|\{)',
    multiLine: true,
  );
  final names = <String>[];
  for (final match in pattern.allMatches(body)) {
    final start =
        match.start +
        (match.group(0)!.length - match.group(0)!.trimLeft().length);
    if (!_startsMember(body, code, depths, start)) continue;
    final name = match.group(1)!;
    if (!name.startsWith('_') && !names.contains(name)) names.add(name);
  }
  return names;
}

/// Parses a parameter list (the text between the parentheses). [classBody]
/// resolves the type and docs of `this.x` parameters from the class fields.
List<DartParameter> _parameters(String text, String classBody) {
  final code = _codeMask(text);
  final depths = _depths(text, code);
  var sectionOpen = -1;
  for (var i = 0; i < text.length; i++) {
    if (code[i] && depths[i] == 0 && (text[i] == '{' || text[i] == '[')) {
      sectionOpen = i;
      break;
    }
  }
  final parameters = <DartParameter>[];
  void addAll(String list, String kind) {
    for (final part in _splitTopLevel(list)) {
      final parameter = _parameter(part, kind, classBody);
      if (parameter != null) parameters.add(parameter);
    }
  }

  if (sectionOpen < 0) {
    addAll(text, 'positional');
  } else {
    addAll(text.substring(0, sectionOpen), 'positional');
    final close = _matching(text, code, sectionOpen);
    addAll(
      text.substring(sectionOpen + 1, close),
      text[sectionOpen] == '{' ? 'named' : 'optionalPositional',
    );
  }
  return parameters;
}

DartParameter? _parameter(String raw, String kind, String classBody) {
  var text = _stripComments(raw).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return null;
  text = text.replaceAll(RegExp(r'^(?:@\w+(?:\([^)]*\))? )+'), '');

  String? defaultValue;
  final code = _codeMask(text);
  final depths = _depths(text, code);
  for (var i = 0; i < text.length; i++) {
    if (!code[i] || depths[i] != 0 || text[i] != '=') continue;
    final next = i + 1 < text.length ? text[i + 1] : '';
    final previous = i > 0 ? text[i - 1] : '';
    if (next == '=' || next == '>' || '=!<>'.contains(previous)) continue;
    defaultValue = text.substring(i + 1).trim();
    text = text.substring(0, i).trim();
    break;
  }

  var isRequired = kind == 'positional';
  for (final keyword in const ['required ', 'covariant ', 'final ']) {
    if (text.startsWith(keyword)) {
      if (keyword == 'required ') isRequired = true;
      text = text.substring(keyword.length).trim();
    }
  }

  final match = RegExp(r'^(.*?)((?:this|super)\.)?(\w+)$').firstMatch(text);
  if (match == null) return null;
  final name = match.group(3)!;
  String? type = match.group(1)!.trim();
  if (type.isEmpty) type = null;
  var documentation = '';
  if (match.group(2) == 'this.') {
    final field = _field(classBody, name);
    type ??= field?.$1;
    documentation = field?.$2 ?? '';
  } else if (match.group(2) == 'super.' && name == 'key') {
    type ??= 'Key?';
  }
  return DartParameter(
    name: name,
    type: type,
    kind: kind,
    isRequired: isRequired,
    defaultValue: defaultValue,
    documentation: documentation,
  );
}

/// The declared type and doc comment of the field [name] in a class [body].
(String type, String documentation)? _field(String body, String name) {
  if (body.isEmpty) return null;
  final code = _codeMask(body);
  final depths = _depths(body, code);
  final pattern = RegExp(
    '^[ \\t]*(?:@\\w+[ \\t]+)*(?:late[ \\t]+)?(?:final[ \\t]+)?'
    '([^\\n;=]+?)[ \\t]+${RegExp.escape(name)}[ \\t]*[;=]',
    multiLine: true,
  );
  for (final match in pattern.allMatches(body)) {
    final start =
        match.start +
        (match.group(0)!.length - match.group(0)!.trimLeft().length);
    if (!_startsMember(body, code, depths, start)) continue;
    final type = match.group(1)!.trim();
    if (type == 'static' || type.startsWith('static ')) continue;
    return (type, _docBefore(body, start));
  }
  return null;
}
