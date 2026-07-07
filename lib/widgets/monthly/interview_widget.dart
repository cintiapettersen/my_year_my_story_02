import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/services/interview_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';
import 'package:myyearmystory/services/interview_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storage_client/storage_client.dart' show FileOptions;

class AppConfig {
  static bool isDev = true;
  static bool isAdmin(String? email) =>
      email != null && email.endsWith("@sonhodepapel.com");
}

class InterviewScreen extends StatefulWidget {
  final int? month;
  final int? year;

  const InterviewScreen({super.key, this.month, this.year});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with AutomaticKeepAliveClientMixin {
  final supabase = SupabaseConfig.client;

  static const int _freeTranscriptionsMonthlyLimit = 5;
  static const int _freeAudioMonthlyLimit = 5;
  static const int _answerMaxChars = 1200;
  static const Duration _listenFor = Duration(seconds: 40);
  static const Duration _pauseFor = Duration(seconds: 2);
  static const Duration _maxAudioDuration = Duration(seconds: 60);
  static const String _audioBucket = 'interview_audios';
  static const Duration _autosaveDebounce = Duration(seconds: 2);

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  bool _isAutoSaving = false;
  DateTime? _lastSavedAt;
  String? _lastSaveError;
  DateTime? _momentCreatedAt;

  bool _isPremiumUser = false;
  final bool _showAllQuestions = false;

  final List<TextEditingController> _controllers = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  List<String> _questions = [];
  String _description = '';

  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  String? _speechLocaleId;
  int? _listeningIndex;
  final Map<int, String> _dictationBaseText = {};
  SpeechRecognitionError? _lastSpeechError;
  bool _userStoppedDictation = false;
  bool _receivedAnyResult = false;
  String? _lastLanguageCode;
  bool _didInit = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  int? _recordingIndex;
  int? _playingIndex;
  StreamSubscription<ProcessingState>? _audioProcessingSub;
  bool _isUploadingAudio = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  final Map<int, _InterviewAudioInfo> _audioByQuestion = {};

  Timer? _autosaveTimer;
  bool _initializingControllers = false;

  @override
  bool get wantKeepAlive => true;

  bool get isGuest => supabase.auth.currentUser == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final lang = context.locale.languageCode;
    final prevLang = _lastLanguageCode;
    _lastLanguageCode = lang;

    // EasyLocalization depende de InheritedWidget; não pode ser lido no initState.
    if (!_didInit) {
      _didInit = true;
      _audioProcessingSub ??= _audioPlayer.processingStateStream.listen((ps) {
        if (!mounted) return;
        if (ps == ProcessingState.completed) {
          _audioPlayer.stop();
          setState(() => _playingIndex = null);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initializeFor(lang);
      });
      return;
    }

    // Se o idioma mudar, recarrega perguntas/descrição.
    if (!_isLoading && prevLang != null && prevLang != lang) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initializeFor(lang);
      });
    }
  }

  // ---------------- INIT ----------------

  Future<void> _initializeFor(String languageCode) async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Failsafe: nunca ficar preso em loading eterno.
      Future.delayed(const Duration(seconds: 15), () {
        if (!mounted) return;
        if (_isLoading) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      });

      await _checkPremiumStatus();

      final data = await InterviewService.getInterviewData(
        widget.month ?? DateTime.now().month,
        languageCode,
      ).timeout(const Duration(seconds: 10));

      _questions = List<String>.from(data['questions'] ?? []);
      _description = "interview.fixed_description".tr();

      _initializingControllers = true;
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers
        ..clear()
        ..addAll(
          List.generate(_questions.length, (_) => TextEditingController()),
        );

      await _loadSavedAnswers();
      await _loadDraftIfNeeded();
      _attachAutosaveListeners();
      _initializingControllers = false;
      await _loadSavedAudios();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPremiumStatus() async {
    final user = supabase.auth.currentUser;
    final email = user?.email;
    bool isPremium = false;
    try {
      isPremium = await AccessControl.isPremium()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
    } catch (_) {
      isPremium = false;
    }

    if (!mounted) return;
    setState(() {
      _isPremiumUser = isPremium || AppConfig.isAdmin(email) || AppConfig.isDev;
    });
  }

  Future<void> _loadSavedAnswers() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await InterviewService.getInterviewDataFromEntries(
      widget.month ?? DateTime.now().month,
      widget.year ?? DateTime.now().year,
      userId,
    ).timeout(const Duration(seconds: 10));

    final person = data['person'] ?? {};
    final questionsData = List<Map<String, dynamic>>.from(
      data['questions'] ?? [],
    );

    _nameController.text = person['name'] ?? '';
    _relationController.text = person['relation'] ?? '';
    _ageController.text = person['age'] ?? '';

    final createdRaw = data['created_at'] ?? data['updated_at'];
    if (_momentCreatedAt == null && createdRaw != null) {
      final parsed = DateTime.tryParse(createdRaw.toString());
      if (parsed != null) _momentCreatedAt = parsed.toLocal();
    }

    for (int i = 0; i < _controllers.length; i++) {
      if (i < questionsData.length) {
        _controllers[i].text = questionsData[i]['a'] ?? '';
      }
    }
  }

  String _draftKey({
    required String userKey,
    required int month,
    required int year,
  }) =>
      'interview_draft_${userKey}_${year}_${month.toString().padLeft(2, '0')}';

  String get _draftUserKey => supabase.auth.currentUser?.id ?? 'guest';

  Future<void> _saveDraftLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final key = _draftKey(userKey: _draftUserKey, month: month, year: year);

    _momentCreatedAt ??= DateTime.now();

    final payload = <String, dynamic>{
      'created_at': _momentCreatedAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'person': {
        'name': _nameController.text,
        'relation': _relationController.text,
        'age': _ageController.text,
      },
      'answers': _controllers.map((c) => c.text).toList(growable: false),
    };

    await prefs.setString(key, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> _loadDraftLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final key = _draftKey(userKey: _draftUserKey, month: month, year: year);
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearDraftLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final key = _draftKey(userKey: _draftUserKey, month: month, year: year);
    await prefs.remove(key);
  }

  bool _hasAnyAnswer() {
    if (_nameController.text.trim().isNotEmpty) return true;
    if (_relationController.text.trim().isNotEmpty) return true;
    if (_ageController.text.trim().isNotEmpty) return true;
    return _controllers.any((c) => c.text.trim().isNotEmpty);
  }

  Future<void> _loadDraftIfNeeded() async {
    final draft = await _loadDraftLocal();
    if (draft == null) return;

    // Se já tem algo vindo do servidor, não sobrescreve.
    if (_hasAnyAnswer()) return;

    final person = (draft['person'] is Map) ? Map<String, dynamic>.from(draft['person']) : <String, dynamic>{};
    final answers = draft['answers'];
    final createdRaw = draft['created_at'];
    if (_momentCreatedAt == null && createdRaw != null) {
      final parsed = DateTime.tryParse(createdRaw.toString());
      if (parsed != null) _momentCreatedAt = parsed.toLocal();
    }

    _nameController.text = (person['name'] ?? '').toString();
    _relationController.text = (person['relation'] ?? '').toString();
    _ageController.text = (person['age'] ?? '').toString();

    if (answers is List) {
      for (int i = 0; i < _controllers.length; i++) {
        if (i < answers.length) {
          _controllers[i].text = (answers[i] ?? '').toString();
        }
      }
    }
  }

  void _attachAutosaveListeners() {
    // Evita duplicar listeners se reinicializar.
    for (final c in _controllers) {
      c.removeListener(_scheduleAutosave);
      c.addListener(_scheduleAutosave);
    }
    _nameController.removeListener(_scheduleAutosave);
    _relationController.removeListener(_scheduleAutosave);
    _ageController.removeListener(_scheduleAutosave);

    _nameController.addListener(_scheduleAutosave);
    _relationController.addListener(_scheduleAutosave);
    _ageController.addListener(_scheduleAutosave);
  }

  void _scheduleAutosave() {
    if (!mounted) return;
    if (_initializingControllers) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDebounce, () async {
      await _autosaveNow();
    });
  }

  Future<void> _autosaveNow() async {
    if (!mounted) return;

    // Sempre mantém rascunho local para prevenir perdas.
    try {
      await _saveDraftLocal();
    } catch (_) {
      // ignore
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _lastSaveError = null);
      return;
    }

    // Só salva no Supabase se premium (ou dev/admin).
    if (!_isPremiumUser) {
      if (mounted) setState(() => _lastSaveError = null);
      return;
    }

    if (_isSaving || _isAutoSaving) return;

    setState(() {
      _isAutoSaving = true;
      _lastSaveError = null;
    });

    final answers = _controllers.map((c) => c.text.trim()).toList();
    final hasContent =
        answers.any((a) => a.isNotEmpty) ||
        _nameController.text.trim().isNotEmpty ||
        _relationController.text.trim().isNotEmpty ||
        _ageController.text.trim().isNotEmpty;

    if (!hasContent) {
      setState(() => _isAutoSaving = false);
      return;
    }

    try {
      _momentCreatedAt ??= DateTime.now();
      await InterviewService.saveInterviewAnswers(
        questions: _questions,
        answers: answers,
        month: widget.month ?? DateTime.now().month,
        year: widget.year ?? DateTime.now().year,
        userId: user.id,
        interviewName: _nameController.text.trim(),
        interviewRelation: _relationController.text.trim(),
        interviewAge: _ageController.text.trim(),
        createdAtIso: _momentCreatedAt!.toIso8601String(),
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;
      setState(() {
        _isAutoSaving = false;
        _lastSavedAt = DateTime.now();
        _lastSaveError = null;
      });
      await _clearDraftLocal();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAutoSaving = false;
        _lastSaveError = 'Falha ao salvar';
      });
    }
  }

  Future<void> _loadSavedAudios() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;

    final rows = await InterviewAudioService.listForMonth(
      userId: userId,
      month: month,
      year: year,
    ).timeout(const Duration(seconds: 10), onTimeout: () => <Map<String, dynamic>>[]);

    if (!mounted) return;
    setState(() {
      _audioByQuestion.clear();
      for (final row in rows) {
        final q = row['question_index'];
        final path = row['storage_path'];
        if (q is int && path is String && path.trim().isNotEmpty) {
          _audioByQuestion[q] = _InterviewAudioInfo(
            storagePath: path,
            mimeType: row['mime_type']?.toString(),
            durationSeconds: row['duration_seconds'] is int
                ? row['duration_seconds'] as int
                : int.tryParse((row['duration_seconds'] ?? '').toString()),
          );
        }
      }
    });
  }

  String _sttCountPrefsKey({
    required String userId,
    required int month,
    required int year,
  }) =>
      'interview_stt_count_${userId}_${year}_${month.toString().padLeft(2, '0')}';

  Future<int> _getMonthlyTranscriptionsCount({
    required String userId,
    required int month,
    required int year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(
          _sttCountPrefsKey(userId: userId, month: month, year: year),
        ) ??
        0;
  }

  String _audioCountPrefsKey({
    required String userId,
    required int month,
    required int year,
  }) =>
      'interview_audio_count_${userId}_${year}_${month.toString().padLeft(2, '0')}';

  Future<int> _getMonthlyAudioCount({
    required String userId,
    required int month,
    required int year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_audioCountPrefsKey(userId: userId, month: month, year: year)) ?? 0;
  }

  Future<void> _incrementMonthlyAudioCount({
    required String userId,
    required int month,
    required int year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _audioCountPrefsKey(userId: userId, month: month, year: year);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  Future<void> _incrementMonthlyTranscriptionsCount({
    required String userId,
    required int month,
    required int year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _sttCountPrefsKey(userId: userId, month: month, year: year);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  Future<void> _ensureSpeechReady() async {
    if (_speechReady) return;
    try {
      final ok =
          await _speech
              .initialize(
                onStatus: (status) {
                  if (!mounted) return;
                  if (status == 'listening') {
                    // ok
                    return;
                  }
                  if ((status == 'notListening' || status == 'done') &&
                      _listeningIndex != null) {
                    final shouldNotifyNoResult =
                        !_userStoppedDictation && !_receivedAnyResult;
                    setState(() => _listeningIndex = null);
                    if (shouldNotifyNoResult) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Não consegui captar sua voz. Tente de novo.'),
                        ),
                      );
                    }
                  }
                },
                onError: (error) {
                  if (!mounted) return;
                  _lastSpeechError = error;
                  setState(() => _listeningIndex = null);
                },
              )
              .timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (!ok) return;
      final hasPerm = await _speech.hasPermission
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!hasPerm) return;
      final system = await _speech
          .systemLocale()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      _speechLocaleId = system?.localeId;
      if (!mounted) return;
      setState(() => _speechReady = true);

      // Logs úteis no `flutter run` pra diagnóstico em device.
      // ignore: avoid_print
      print('[InterviewSTT] ready=true locale=${_speechLocaleId ?? 'default'}');
    } catch (_) {
      // ignore: stay disabled
    }
  }

  Future<void> _toggleDictationFor(int index) async {
    if (_listeningIndex == index) {
      await _stopDictation();
      return;
    }
    await _startDictation(index);
  }

  Future<void> _startDictation(int index) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    if (!_isPremiumUser) {
      final month = widget.month ?? DateTime.now().month;
      final year = widget.year ?? DateTime.now().year;
      final count = await _getMonthlyTranscriptionsCount(
        userId: user.id,
        month: month,
        year: year,
      );
      if (count >= _freeTranscriptionsMonthlyLimit) {
        if (!mounted) return;
        showPremiumPopup(context);
        return;
      }
    }

    await _ensureSpeechReady();
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Transcrição não disponível neste dispositivo.'),
        ),
      );
      return;
    }

    if (_listeningIndex != null) {
      await _stopDictation();
    }

    _dictationBaseText[index] = _controllers[index].text.trimRight();
    _lastSpeechError = null;
    _userStoppedDictation = false;
    _receivedAnyResult = false;

    if (!mounted) return;
    setState(() => _listeningIndex = index);

    bool started = false;
    try {
      await _speech.listen(
        localeId: _speechLocaleId,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
        onSoundLevelChange: (level) {
          // ignore: avoid_print
          // print('[InterviewSTT] level=$level');
        },
        onResult: (result) {
          _receivedAnyResult = _receivedAnyResult || result.recognizedWords.trim().isNotEmpty;
          final base = _dictationBaseText[index] ?? '';
          final words = (result.recognizedWords).trim();
          final combined =
              words.isEmpty
                  ? base
                  : base.isEmpty
                      ? words
                      : '$base $words';

          final clamped =
              combined.length <= _answerMaxChars
                  ? combined
                  : combined.substring(0, _answerMaxChars);

          final controller = _controllers[index];
          controller.value = controller.value.copyWith(
            text: clamped,
            selection: TextSelection.collapsed(offset: clamped.length),
            composing: TextRange.empty,
          );
        },
      );
    } catch (_) {
      started = false;
    }

    // `SpeechToText.listen` não retorna bool; valida pelo estado do plugin.
    await Future.delayed(const Duration(milliseconds: 250));
    started = _speech.isListening;

    if (!started) {
      if (!mounted) return;
      setState(() => _listeningIndex = null);
      final err = _lastSpeechError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            err == null
                ? 'Não foi possível iniciar o microfone. Verifique permissões e o serviço de Reconhecimento de Fala do Android.'
                : 'Não foi possível iniciar: ${err.errorMsg} (${err.permanent ? 'permanente' : 'temporário'}).',
          ),
        ),
      );
      return;
    }

    if (!_isPremiumUser) {
      final month = widget.month ?? DateTime.now().month;
      final year = widget.year ?? DateTime.now().year;
      await _incrementMonthlyTranscriptionsCount(
        userId: user.id,
        month: month,
        year: year,
      );
    }
  }

  Future<void> _stopDictation() async {
    _userStoppedDictation = true;
    try {
      await _speech.stop();
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() => _listeningIndex = null);
  }

  String _audioObjectPath({
    required String userId,
    required int month,
    required int year,
    required int questionIndex,
  }) {
    final mm = month.toString().padLeft(2, '0');
    return '$userId/$year/$mm/q$questionIndex.m4a';
  }

  String _publicAudioUrl(String storagePath) {
    return supabase.storage.from(_audioBucket).getPublicUrl(storagePath);
  }

  Future<File> _localAudioFile({
    required int month,
    required int year,
    required int questionIndex,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final mm = month.toString().padLeft(2, '0');
    final folder = Directory('${dir.path}/interview_audio/$year/$mm');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/q$questionIndex.m4a');
  }

  Future<void> _toggleRecordingFor(int index) async {
    if (_recordingIndex == index) {
      await _stopRecording();
      return;
    }
    await _startRecording(index);
  }

  Future<void> _startRecording(int index) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    if (_isUploadingAudio) return;
    if (_listeningIndex != null) await _stopDictation();
    if (_recordingIndex != null) await _stopRecording();

    if (!_isPremiumUser) {
      final month = widget.month ?? DateTime.now().month;
      final year = widget.year ?? DateTime.now().year;
      final count = await _getMonthlyAudioCount(userId: user.id, month: month, year: year);
      if (count >= _freeAudioMonthlyLimit) {
        if (!mounted) return;
        showPremiumPopup(context);
        return;
      }
    }

    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Permissão de microfone negada.'),
        ),
      );
      return;
    }

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final file = await _localAudioFile(month: month, year: year, questionIndex: index);

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: file.path,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível iniciar a gravação.'),
        ),
      );
      return;
    }

    _recordTimer?.cancel();
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _recordSeconds++;
      if (_recordSeconds >= _maxAudioDuration.inSeconds) {
        await _stopRecording();
      } else {
        if (mounted) setState(() {});
      }
    });

    if (!mounted) return;
    setState(() => _recordingIndex = index);
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    final idx = _recordingIndex;
    if (idx == null) return;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }

    if (!mounted) return;
    setState(() => _recordingIndex = null);

    if (path == null || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Gravação não salva.'),
        ),
      );
      return;
    }

    await _uploadAndPersistAudio(idx, File(path), durationSeconds: _recordSeconds);
  }

  Future<void> _uploadAndPersistAudio(
    int questionIndex,
    File file, {
    required int durationSeconds,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final storagePath = _audioObjectPath(
      userId: user.id,
      month: month,
      year: year,
      questionIndex: questionIndex,
    );

    setState(() => _isUploadingAudio = true);
    try {
      final bytes = await file.readAsBytes();
      await supabase.storage.from(_audioBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'audio/mp4',
            ),
          );

      final ok = await InterviewAudioService.upsertAudio(
        userId: user.id,
        month: month,
        year: year,
        questionIndex: questionIndex,
        storagePath: storagePath,
        mimeType: 'audio/mp4',
        durationSeconds: durationSeconds,
      );

      if (!_isPremiumUser) {
        await _incrementMonthlyAudioCount(userId: user.id, month: month, year: year);
      }

      if (!mounted) return;
      if (ok) {
        setState(() {
          _audioByQuestion[questionIndex] = _InterviewAudioInfo(
            storagePath: storagePath,
            mimeType: 'audio/mp4',
            durationSeconds: durationSeconds,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Áudio salvo!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Áudio enviado, mas falhou ao registrar no banco.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Falha ao enviar o áudio. Verifique sua conexão.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  Future<void> _deleteAudioFor(int index) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    final info = _audioByQuestion[index];
    if (info == null) return;
    if (_isUploadingAudio) return;
    if (_recordingIndex == index) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir áudio?'),
            content: const Text(
              'Isso remove o áudio gravado desta pergunta. Você pode gravar novamente depois.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;

    if (_playingIndex == index) {
      try {
        await _audioPlayer.stop();
      } catch (_) {
        // ignore
      }
      _playingIndex = null;
    }

    // Optimistic UI.
    if (mounted) {
      setState(() {
        _audioByQuestion.remove(index);
      });
    }

    bool storageOk = true;
    bool dbOk = true;

    try {
      await supabase.storage.from(_audioBucket).remove([info.storagePath]);
    } catch (_) {
      storageOk = false;
    }

    dbOk = await InterviewAudioService.deleteAudio(
      userId: user.id,
      month: month,
      year: year,
      questionIndex: index,
    );

    try {
      final local = await _localAudioFile(
        month: month,
        year: year,
        questionIndex: index,
      );
      if (await local.exists()) {
        await local.delete();
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          (storageOk && dbOk)
              ? 'Áudio excluído.'
              : 'Áudio removido localmente, mas houve falha ao excluir no servidor. Tente novamente.',
        ),
      ),
    );
  }

  Future<void> _togglePlay(int index) async {
    final info = _audioByQuestion[index];
    if (info == null) return;

    // Se está tocando o mesmo áudio, para. Se é outro, troca.
    if (_audioPlayer.playing && _playingIndex == index) {
      await _audioPlayer.stop();
      _playingIndex = null;
      if (mounted) setState(() {});
      return;
    }
    if (_audioPlayer.playing) {
      await _audioPlayer.stop();
    }

    final url = _publicAudioUrl(info.storagePath);
    try {
      await _audioPlayer.setUrl(url);
      _playingIndex = index;
      if (mounted) setState(() {});
      await _audioPlayer.play();
    } catch (_) {
      _playingIndex = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível reproduzir o áudio.'),
        ),
      );
    }
  }

  // ---------------- SAVE ----------------

  Future<void> _saveInterview() async {
    final user = supabase.auth.currentUser;

    if (isGuest) {
      showLoginPrompt(context);
      return;
    }

    if (!_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    final visibleCount =
        _isPremiumUser || _showAllQuestions ? _questions.length : 5;

    final answers =
        _controllers.take(visibleCount).map((c) => c.text.trim()).toList();

    if (!answers.any((a) => a.isNotEmpty)) {
      _showEmptyWarning();
      return;
    }

    await _saveInterviewAnswers(user!.id, answers);
  }

  Future<void> _saveInterviewAnswers(
    String userId,
    List<String> answers,
  ) async {
    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      _momentCreatedAt ??= DateTime.now();
      await InterviewService.saveInterviewAnswers(
        questions: _questions,
        answers: answers,
        month: widget.month ?? DateTime.now().month,
        year: widget.year ?? DateTime.now().year,
        userId: userId,
        interviewName: _nameController.text.trim(),
        interviewRelation: _relationController.text.trim(),
        interviewAge: _ageController.text.trim(),
        createdAtIso: _momentCreatedAt!.toIso8601String(),
      );

      if (!mounted) return;
      _showSuccessSnack();
      await _clearDraftLocal();
      if (mounted) {
        setState(() {
          _lastSavedAt = DateTime.now();
          _lastSaveError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------- UI HELPERS ----------------

  void _showEmptyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFF3D6E4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          "interview.empty_warning".tr(),
          style: const TextStyle(
            color: Color(0xFF6D2C4A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFA1A8F0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          "interview.saved_success".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showErrorSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text("interview.save_error".tr()),
      ),
    );
  }

  // ---------------- BUILD ----------------

  String _formatMomentDate(DateTime dt) {
    try {
      return DateFormat.yMMMMd(context.locale.toString()).add_Hm().format(dt);
    } catch (_) {
      final local = dt.toLocal();
      return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMomentCaption() {
    final dt = _momentCreatedAt;
    if (dt == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        'Momento registrado em ${_formatMomentDate(dt)}',
        style: TextStyle(
          fontSize: 12.5,
          color: Colors.black.withValues(alpha: 0.55),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _iconAction({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    required String tooltip,
  }) => Tooltip(
    message: tooltip,
    waitDuration: const Duration(milliseconds: 250),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;

    final visibleQuestions =
        _isPremiumUser || _showAllQuestions
            ? _questions
            : _questions.take(5).toList();

    return MonthPageTemplate(
      month: month,
      year: year,
      title: "",
      pageLabel: "interview.page_label".tr(),
      labelColor: const Color(0xFFa1a8f0),
      description: _description,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          // Flush rápido quando sair.
          _autosaveTimer?.cancel();
          await _autosaveNow();
        },
        child: RemoteDataWrapper(
          isLoading: _isLoading,
          hasError: _hasError,
          onRetry: () =>
              _initializeFor(_lastLanguageCode ?? context.locale.languageCode),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildPersonForm(),
                _buildMomentCaption(),
                const SizedBox(height: 20),
                _buildQuestions(visibleQuestions),
                const SizedBox(height: 20),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- SUB WIDGETS ----------------

  Widget _buildHeader() => Center(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        "interview.who_prompt".tr(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(221, 149, 41, 110),
        ),
      ),
    ),
  );

  Widget _buildPersonForm() {
    const accent = Color(0xFFA1A8F0);
    const frame = Color(0xFFDAD6FF);
    const inner = Color(0xFFFFFBFF);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: frame.withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.40), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: inner.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "interview.identification_title".tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6D5C74),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: "interview.name_label".tr(),
              controller: _nameController,
              hint: "interview.name_hint".tr(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFieldBase(
                    controller: _relationController,
                    hint: "interview.relation_hint".tr(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildFieldBase(
                    controller: _ageController,
                    hint: "interview.age_hint".tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestions(List<String> questions) => Column(
    children:
        questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final isListening = _listeningIndex == index;
          final isRecording = _recordingIndex == index;
          final hasAudio = _audioByQuestion.containsKey(index);
          final isPlayingThis = _audioPlayer.playing && _playingIndex == index;
          final audioInfo = _audioByQuestion[index];
          final audioDuration = audioInfo?.durationSeconds;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2D7E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6D5C74),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _iconAction(
                      onPressed: () => _toggleDictationFor(index),
                      icon: isListening ? Icons.stop_circle : Icons.mic_none,
                      color:
                          isListening
                              ? const Color(0xFFC881D5)
                              : const Color(0xFF6D5C74),
                      tooltip:
                          isListening ? 'Parar transcrição' : 'Transcrever áudio',
                    ),
                    _iconAction(
                      onPressed:
                          _isUploadingAudio ? null : () => _toggleRecordingFor(index),
                      icon:
                          isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                      color:
                          isRecording
                              ? const Color(0xFFE25BA6)
                              : const Color(0xFFB00020),
                      tooltip:
                          isRecording
                              ? 'Parar gravação'
                              : 'Gravar áudio (até 60s)',
                    ),
                    _iconAction(
                      onPressed: hasAudio ? () => _togglePlay(index) : null,
                      icon: isPlayingThis ? Icons.stop : Icons.play_arrow_rounded,
                      color: hasAudio ? const Color(0xFF6D5C74) : Colors.black26,
                      tooltip:
                          hasAudio
                              ? (audioDuration == null
                                  ? 'Reproduzir'
                                  : 'Reproduzir (${audioDuration}s)')
                              : 'Sem áudio',
                    ),
                    if (hasAudio)
                      _iconAction(
                        onPressed: () => _deleteAudioFor(index),
                        icon: Icons.delete_outline,
                        color: Colors.black54,
                        tooltip: 'Excluir áudio',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controllers[index],
                  autocorrect: true,
                  enableSuggestions: true,
                  smartQuotesType: SmartQuotesType.enabled,
                  smartDashesType: SmartDashesType.enabled,
                  readOnly: isListening,
                  maxLines: null,
                  maxLength: _answerMaxChars,
                  decoration: InputDecoration(
                    hintText: "interview.answer_hint".tr(),
                    filled: true,
                    fillColor: Colors.white,
                    helperText:
                        isRecording
                            ? 'Gravando… ${_recordSeconds}s / ${_maxAudioDuration.inSeconds}s'
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
  );

  Widget _buildButtons() => Column(
    children: [
      AppPillButton(
        expand: true,
        text: "interview.save_button".tr(),
        onPressed: _isSaving ? null : _saveInterview,
      ),
      const SizedBox(height: 8),
      Text(
        _isAutoSaving
            ? 'Salvando…'
            : _lastSaveError != null
                ? _lastSaveError!
                : (_lastSavedAt != null
                    ? 'Salvo às ${_lastSavedAt!.hour.toString().padLeft(2, '0')}:${_lastSavedAt!.minute.toString().padLeft(2, '0')}'
                    : 'Áudio e transcrição são feitos pelos ícones em cada pergunta (passe o mouse, ou toque e segure).'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color:
              _lastSaveError != null
                  ? Colors.redAccent
                  : Colors.black.withValues(alpha: 0.55),
        ),
      ),
    ],
  );

  Widget _buildFieldBase({
    required TextEditingController controller,
    required String hint,
  }) => TextField(
    controller: controller,
    autocorrect: true,
    enableSuggestions: true,
    smartQuotesType: SmartQuotesType.enabled,
    smartDashesType: SmartDashesType.enabled,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      _buildFieldBase(controller: controller, hint: hint),
    ],
  );

  @override
  void dispose() {
    _recordTimer?.cancel();
    _autosaveTimer?.cancel();
    _audioProcessingSub?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

class _InterviewAudioInfo {
  final String storagePath;
  final String? mimeType;
  final int? durationSeconds;

  _InterviewAudioInfo({
    required this.storagePath,
    this.mimeType,
    this.durationSeconds,
  });
}
