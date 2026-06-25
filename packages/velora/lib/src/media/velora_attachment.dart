import 'dart:math' as math;

/// Upload lifecycle of a single [VeloraAttachment].
enum AttachmentStatus { pending, uploading, done, error }

/// Picker options passed to [VeloraAttachmentsMixin.showAttachmentPicker].
class VeloraPickerConfig {
  final bool allowCamera;
  final bool allowGallery;
  final bool allowFiles;
  final bool allowMultiple;
  final List<String>? allowedFileExtensions;
  final int imageQuality;

  /// When true, picked files are uploaded immediately via [VeloraAttachmentsMixin.uploadAll].
  final bool uploadImmediately;

  const VeloraPickerConfig({
    this.allowCamera = true,
    this.allowGallery = true,
    this.allowFiles = true,
    this.allowMultiple = true,
    this.allowedFileExtensions,
    this.imageQuality = 85,
    this.uploadImmediately = false,
  });
}

/// Immutable model representing a local or remote file attachment.
///
/// Use [VeloraAttachment.local] when a file has just been picked from the
/// device and is pending upload.  Use [VeloraAttachment.remote] for
/// pre-existing server attachments (e.g. loaded from an API).
///
/// [VeloraAttachmentsMixin] manages a reactive list of these and drives
/// uploads via [VeloraUploadAdapter].
class VeloraAttachment {
  final String id;
  final String name;
  final String? localPath;
  final String? mimeType;
  final int? sizeBytes;
  final String? remoteUrl;

  /// Server-assigned numeric media ID (e.g. from Spatie Laravel Media Library).
  /// Available after a successful upload via [LaravelMediaAdapter].
  final String? mediaId;

  /// Server-assigned UUID (e.g. `uuid` field from Spatie Laravel Media Library).
  final String? mediaUuid;

  final AttachmentStatus status;
  final double progress;
  final String? errorMessage;

  const VeloraAttachment._({
    required this.id,
    required this.name,
    this.localPath,
    this.mimeType,
    this.sizeBytes,
    this.remoteUrl,
    this.mediaId,
    this.mediaUuid,
    required this.status,
    required this.progress,
    this.errorMessage,
  });

  factory VeloraAttachment.local({
    required String path,
    required String name,
    String? mimeType,
    int? sizeBytes,
  }) =>
      VeloraAttachment._(
        id: _uid(),
        name: name,
        localPath: path,
        mimeType: mimeType ?? _mimeOf(name),
        sizeBytes: sizeBytes,
        status: AttachmentStatus.pending,
        progress: 0,
      );

  factory VeloraAttachment.remote({
    required String id,
    required String name,
    required String url,
    String? mimeType,
    int? sizeBytes,
    String? mediaId,
    String? mediaUuid,
  }) =>
      VeloraAttachment._(
        id: id,
        name: name,
        remoteUrl: url,
        mimeType: mimeType ?? _mimeOf(name),
        sizeBytes: sizeBytes,
        mediaId: mediaId,
        mediaUuid: mediaUuid,
        status: AttachmentStatus.done,
        progress: 1,
      );

  bool get isImage => mimeType?.startsWith('image/') == true;
  bool get isPdf => mimeType == 'application/pdf';
  bool get isVideo => mimeType?.startsWith('video/') == true;
  bool get isAudio => mimeType?.startsWith('audio/') == true;

  String get ext {
    final i = name.lastIndexOf('.');
    return i < 0 ? '' : name.substring(i + 1).toLowerCase();
  }

  String get displaySize {
    final b = sizeBytes;
    if (b == null) return '';
    if (b < 1024) return '${b}B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1048576).toStringAsFixed(1)}MB';
  }

  /// Returns a copy with the specified fields replaced.
  ///
  /// Passing `errorMessage: null` explicitly clears any previous error —
  /// this is intentional so transitions to [AttachmentStatus.uploading]
  /// automatically reset the error state.
  VeloraAttachment copyWith({
    String? name,
    String? localPath,
    String? mimeType,
    int? sizeBytes,
    String? remoteUrl,
    String? mediaId,
    String? mediaUuid,
    AttachmentStatus? status,
    double? progress,
    String? errorMessage,
  }) =>
      VeloraAttachment._(
        id: id,
        name: name ?? this.name,
        localPath: localPath ?? this.localPath,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        mediaId: mediaId ?? this.mediaId,
        mediaUuid: mediaUuid ?? this.mediaUuid,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage,
      );

  static final _rng = math.Random();

  static String _uid() {
    const c = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (_) => c[_rng.nextInt(c.length)]).join();
  }

  static String? _mimeOf(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0) return null;
    switch (name.substring(i + 1).toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return null;
    }
  }
}
