import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import '../models/recording.dart';

/// 한국 시간대(UTC+9)로 현재 시간 반환
DateTime getKoreaTime() {
  // UTC 시간을 가져와서 한국 시간대(UTC+9)로 변환
  final utcNow = DateTime.now().toUtc();
  return utcNow.add(const Duration(hours: 9));
}

/// 오디오 녹음/재생 서비스
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Uuid _uuid = const Uuid();

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  /// 현재 재생 중인 녹음 ID
  String? currentPlayingId;

  /// 녹음 시작
  Future<bool> startRecording() async {
    try {
      // 마이크 권한 확인
      if (!await _recorder.hasPermission()) {
        return false;
      }

      // 녹음 파일 경로 생성
      final dir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(dir.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final fileName = '${_uuid.v4()}.m4a';
      _currentRecordingPath = p.join(recordingsDir.path, fileName);
      _recordingStartTime = getKoreaTime();

      // 녹음 시작
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      return true;
    } catch (e) {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return false;
    }
  }

  /// 녹음 중지 및 Recording 객체 반환
  Future<Recording?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null || _currentRecordingPath == null || _recordingStartTime == null) {
        return null;
      }

      // 파일 존재 확인
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        return null;
      }

      final duration = getKoreaTime().difference(_recordingStartTime!);

      final recording = Recording(
        id: _uuid.v4(),
        filePath: _currentRecordingPath!,
        createdAt: _recordingStartTime!,
        duration: duration,
      );

      _currentRecordingPath = null;
      _recordingStartTime = null;

      return recording;
    } catch (e) {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return null;
    }
  }

  /// 녹음 중인지 확인
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// 녹음 취소
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // 무시
    } finally {
      _currentRecordingPath = null;
      _recordingStartTime = null;
    }
  }

  /// 재생 시작
  Future<void> play(Recording recording) async {
    if (recording.filePath.isEmpty) return;
    try {
      await _player.stop();
      currentPlayingId = recording.id;
      await _player.play(DeviceFileSource(recording.filePath));
    } catch (e) {
      currentPlayingId = null;
    }
  }

  /// 재생 중지
  Future<void> stop() async {
    currentPlayingId = null;
    await _player.stop();
  }

  /// 일시정지
  Future<void> pause() async {
    await _player.pause();
  }

  /// 재개
  Future<void> resume() async {
    await _player.resume();
  }

  /// 재생 상태 스트림
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// 재생 위치 스트림
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// 녹음 파일 삭제
  Future<void> deleteRecordingFile(String filePath) async {
    if (filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 삭제 실패해도 무시
    }
  }

  /// 리소스 해제
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
