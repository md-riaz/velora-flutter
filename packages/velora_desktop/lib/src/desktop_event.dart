/// What a [VeloraDesktopEvent] reports.
enum VeloraDesktopEventType {
  /// The user asked to close the window. `data['hidden']` is `true` when the
  /// window was hidden to the tray instead of closed.
  closeRequested,

  /// The system is about to sleep or hibernate.
  suspending,

  /// The system woke up. Reported once per sleep.
  resumed,

  /// A second copy of the app was started; its command line is in
  /// [VeloraDesktopEvent.arguments].
  secondaryLaunch,

  /// The app was opened through a registered URI scheme;
  /// [VeloraDesktopEvent.uri] holds the link.
  protocolActivation,

  /// The user activated a notification; [VeloraDesktopEvent.id] and
  /// [VeloraDesktopEvent.data] identify it.
  notificationActivation,
}

/// One desktop lifecycle or activation event.
final class VeloraDesktopEvent {
  const VeloraDesktopEvent({
    required this.type,
    this.id,
    this.arguments = const [],
    this.uri,
    this.data = const {},
  });

  final VeloraDesktopEventType type;

  /// Identifies an activation, so the same one delivered twice is reported
  /// once. `null` for lifecycle events.
  final String? id;

  /// The command line of a secondary launch, exactly as it was passed.
  final List<String> arguments;

  /// The link of a protocol activation.
  final Uri? uri;

  /// Extra JSON-compatible details.
  final Map<String, Object?> data;

  @override
  String toString() =>
      'VeloraDesktopEvent(${type.name}'
      '${id == null ? '' : ', id: $id'}'
      '${arguments.isEmpty ? '' : ', arguments: $arguments'}'
      '${uri == null ? '' : ', uri: $uri'}'
      '${data.isEmpty ? '' : ', data: $data'})';
}
