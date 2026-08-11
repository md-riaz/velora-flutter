import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

/// Showcases velora_ui's Layer 3 form-input components:
/// [VeloraTextField], [VeloraSelect], [VeloraCheckbox], [VeloraSwitch], and
/// [VeloraRadioGroup].
///
/// Every control here is controlled by local state and wired through
/// `setState`, so typing, selecting, checking, and toggling all actually
/// work when you interact with the gallery.
class InputsSection extends StatefulWidget {
  /// Creates the form-inputs showcase section.
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  final _nameController = TextEditingController(text: 'Ada Lovelace');
  final _bioController = TextEditingController();

  String _email = '';
  String _password = '';
  String? _role = 'engineer';
  bool _agreedToTerms = false;
  bool _notificationsEnabled = true;
  String _plan = 'pro';

  static const _roleOptions = [
    VeloraSelectOption(value: 'engineer', label: 'Engineer'),
    VeloraSelectOption(value: 'designer', label: 'Designer'),
    VeloraSelectOption(value: 'manager', label: 'Manager'),
  ];

  static const _planOptions = [
    VeloraRadioOption(
      value: 'free',
      label: 'Free',
      subtitle: 'Basic features for individuals',
    ),
    VeloraRadioOption(
      value: 'pro',
      label: 'Pro',
      subtitle: 'Everything in Free, plus team collaboration',
    ),
    VeloraRadioOption(
      value: 'enterprise',
      label: 'Enterprise',
      subtitle: 'Custom limits and dedicated support',
    ),
  ];

  String? get _emailError {
    if (_email.isEmpty || _email.contains('@')) return null;
    return 'Enter a valid email address';
  }

  String get _passwordHelper {
    if (_password.isEmpty) return 'At least 8 characters';
    return _password.length >= 8
        ? 'Strong enough'
        : '${_password.length}/8 characters';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VeloraSectionHeader(
          title: 'Text fields',
          subtitle: 'Single-line, password, multi-line, and validated',
        ),
        VeloraTextField(
          controller: _nameController,
          label: 'Full name',
          hint: 'Jane Doe',
          prefixIcon: Icons.person_outline,
        ),
        SizedBox(height: tokens.spacingMd),
        VeloraTextField(
          label: 'Email',
          hint: 'jane@example.com',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (value) => setState(() => _email = value),
        ),
        SizedBox(height: tokens.spacingMd),
        VeloraTextField(
          label: 'Password',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          helperText: _passwordHelper,
          onChanged: (value) => setState(() => _password = value),
        ),
        SizedBox(height: tokens.spacingMd),
        VeloraTextField(
          controller: _bioController,
          label: 'Bio',
          hint: 'Tell us about yourself',
          maxLines: 4,
          minLines: 3,
          maxLength: 160,
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Select',
          subtitle: 'A token-styled dropdown field',
        ),
        VeloraSelect<String>(
          label: 'Role',
          hint: 'Choose a role',
          options: _roleOptions,
          value: _role,
          onChanged: (value) => setState(() => _role = value),
          prefixIcon: Icons.badge_outlined,
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Checkbox & switch',
          subtitle: 'Labeled boolean rows',
        ),
        VeloraCheckbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value),
          label: 'I agree to the terms of service',
          subtitle: 'Required to create an account',
        ),
        VeloraSwitch(
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
          label: 'Email notifications',
          subtitle: 'Get a weekly digest of activity',
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Radio group',
          subtitle: 'Single-select plan picker',
        ),
        VeloraRadioGroup<String>(
          label: 'Plan',
          options: _planOptions,
          groupValue: _plan,
          onChanged: (value) => setState(() => _plan = value),
        ),
      ],
    );
  }
}
