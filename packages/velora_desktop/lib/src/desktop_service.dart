import 'desktop_event.dart';

/// The tray icon and its two built-in menu entries.
final class VeloraTrayConfig {
  const VeloraTrayConfig({
    required this.iconAsset,
    this.tooltip,
    this.showLabel = 'Show',
    this.quitLabel = 'Quit',
  });

  /// Flutter asset path of the tray icon, e.g. `assets/tray.ico`.
  final String iconAsset;
  final String? tooltip;

  /// Label of the menu entry that restores and focuses the window.
  final String showLabel;

  /// Label of the menu entry that quits the app.
  final String quitLabel;
}

/// How [VeloraDesktopService] behaves for one app.
final class VeloraDesktopConfig {
  const VeloraDesktopConfig({
    required this.appId,
    required this.appName,
    this.launchArguments = const [],
    this.tray,
    this.closeToTray = false,
    this.singleInstance = true,
    this.protocolSchemes = const {},
    this.autoStartArgument = '--autostart',
    this.deduplicationWindow = const Duration(seconds: 2),
  }) : assert(
         !closeToTray || tray != null,
         'closeToTray needs a tray configuration',
       );

  /// Stable identifier of the app, used for the single-instance channel and
  /// the auto-start entry. Keep it unchanged across releases.
  final String appId;

  /// Name shown for the auto-start entry.
  final String appName;

  /// The arguments `main` received.
  final List<String> launchArguments;

  /// Tray icon to create, or `null` for none.
  final VeloraTrayConfig? tray;

  /// Hide the window to the tray when the user closes it. Applies only once
  /// the tray icon exists; otherwise the window closes normally.
  final bool closeToTray;

  /// Allow one running copy. A second launch hands its arguments to the first
  /// and exits.
  final bool singleInstance;

  /// URI schemes the app is registered for, lower case, without `://`.
  /// A secondary launch whose arguments contain a link with one of these
  /// schemes is reported as a protocol activation.
  final Set<String> protocolSchemes;

  /// Argument added to the auto-start command line, so the app can tell an
  /// automatic launch from one the user made.
  final String autoStartArgument;

  /// How long an activation is remembered for duplicate suppression.
  final Duration deduplicationWindow;

  /// Whether this process was started by the auto-start entry.
  bool get launchedByAutoStart => launchArguments.contains(autoStartArgument);
}

/// What works on this machine, known after
/// [VeloraDesktopService.initialize].
final class VeloraDesktopCapabilities {
  const VeloraDesktopCapabilities({
    this.window = false,
    this.tray = false,
    this.autoStart = false,
    this.singleInstance = false,
    this.protocolLinks = false,
    this.powerEvents = false,
    this.problems = const {},
  });

  /// Close interception and show/hide.
  final bool window;
  final bool tray;
  final bool autoStart;
  final bool singleInstance;
  final bool protocolLinks;

  /// Suspend and resume.
  final bool powerEvents;

  /// Session lock and unlock. Not provided by any selected package, so it is
  /// reported as unsupported instead of being implemented natively.
  bool get lockEvents => false;

  /// Why a capability is off, keyed by capability name.
  final Map<String, String> problems;

  @override
  String toString() =>
      'VeloraDesktopCapabilities(window: $window, tray: $tray, '
      'autoStart: $autoStart, singleInstance: $singleInstance, '
      'protocolLinks: $protocolLinks, powerEvents: $powerEvents, '
      'lockEvents: $lockEvents, problems: $problems)';
}

/// Desktop lifecycle for one app window.
abstract interface class VeloraDesktopService {
  /// Lifecycle and activation events, in the order they happened. Events that
  /// arrive before the first listener (a cold-start link, for example) are
  /// kept and delivered to it.
  Stream<VeloraDesktopEvent> get events;

  /// What works here. All `false` before [initialize] completes.
  VeloraDesktopCapabilities get capabilities;

  /// Sets up the window, tray, single instance, links, and power events.
  /// A part that fails is turned off and listed in
  /// [VeloraDesktopCapabilities.problems]; the rest keeps working.
  Future<void> initialize();

  /// Restores the window, and focuses it unless [focus] is `false`.
  Future<void> show({bool focus = true});

  /// Hides the window.
  Future<void> hide();

  /// Closes the window for real, bypassing close-to-tray.
  Future<void> quit();

  /// Turns launching at login on or off. Throws [UnsupportedError] when
  /// [VeloraDesktopCapabilities.autoStart] is `false`.
  Future<void> setAutoStart(bool enabled);

  /// Whether the app launches at login. `false` when unsupported.
  Future<bool> isAutoStartEnabled();

  Future<void> dispose();
}
