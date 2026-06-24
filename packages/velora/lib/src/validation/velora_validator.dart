class VeloraValidator {
  const VeloraValidator();

  String? required(String? value, {String message = 'This field is required.'}) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? email(String? value, {String message = 'Enter a valid email.'}) {
    if (value == null || value.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return valid ? null : message;
  }

  String? min(String? value, int length, {String? message}) {
    if (value == null) return null;
    return value.length < length ? message ?? 'Minimum length is $length.' : null;
  }

  String? max(String? value, int length, {String? message}) {
    if (value == null) return null;
    return value.length > length ? message ?? 'Maximum length is $length.' : null;
  }

  String? confirmed(String? value, String? other, {String message = 'Values do not match.'}) {
    return value == other ? null : message;
  }
}
