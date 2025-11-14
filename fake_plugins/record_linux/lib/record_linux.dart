import 'package:record_platform_interface/record_platform_interface.dart';

/// Fake plugin para ignorar o record_linux em builds não Linux.
class RecordLinux extends RecordPlatform {
  @override
  Future<Stream<Uint8List>> startStream(String recorderId, RecordConfig config) async {
    return const Stream.empty();
  }

  @override
  Future<void> cancel(String recorderId) async {}

  @override
  Future<void> create(RecordConfig config) async {}

  @override
  Future<void> dispose(String recorderId) async {}

  @override
  Stream<RecordState> onStateChanged(String recorderId) => const Stream.empty();

  @override
  Future<void> pause(String recorderId) async {}

  @override
  Future<void> resume(String recorderId) async {}

  @override
  Future<void> start(String recorderId, RecordConfig config, {required String path}) async {}

  @override
  Future<String?> stop(String recorderId) async => null;
}
