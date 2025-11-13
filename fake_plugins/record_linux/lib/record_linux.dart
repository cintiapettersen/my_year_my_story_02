import 'package:record_platform_interface/record_platform_interface.dart';

/// Fake plugin para ignorar o record_linux em builds não Linux.
class RecordLinux extends RecordPlatform {
  @override
  Future<Stream<List<int>>> startStream(String recorderId, RecordConfig config) async {
    return const Stream.empty();
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> create(RecordConfig config) async {}

  @override
  Future<void> dispose(String recorderId) async {}

  @override
  Stream<RecordState> onStateChanged() => const Stream.empty();

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> start(String recorderId, RecordConfig config, {required String path}) async {}

  @override
  Future<String?> stop(String recorderId) async => null;
}
