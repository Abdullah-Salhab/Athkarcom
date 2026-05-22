import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_model.dart';

Future<Uri?> _cachedArtUri() async {
  try {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/App_Icon.jpg';
    final file = File(filePath);
    if (!await file.exists()) {
      final byteData = await rootBundle.load('assets/images/App_Icon.jpg');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }
    return Uri.file(filePath);
  } catch (e) {
    return null;
  }
}


class QuranReciter {
  final String id;
  final String name;
  final String server;

  /// Folder name on everyayah.com for verse-by-verse audio (null if not available)
  final String? verseAudioFolder;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.server,
    this.verseAudioFolder,
  });
}

/// Repeat mode for verse playback
enum VerseRepeatMode { none, one, two, infinite }

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && !_isVerseMode) {
        if (_currentSurahNumber != null && _currentSurahNumber! < 114) {
          play(_currentSurahNumber! + 1);
        }
      }
    });
  }

  static const _selectedReciterKey = 'quran_selected_reciter';
  static const _playbackSpeedKey = 'quran_playback_speed';

  final AudioPlayer _player = AudioPlayer();
  int? _currentSurahNumber;
  String _currentReciterId = 'afs';
  double _playbackSpeed = 1.0;
  bool _isVerseMode = false;
  VerseRepeatMode _repeatMode = VerseRepeatMode.none;
  int _repeatCount = 0;
  int _totalVerses = 0;
  bool _isHandlingRepeat = false; // guard against repeat recursion

  AudioPlayer get player => _player;
  int? get currentSurahNumber => _currentSurahNumber;
  bool get isPlaying => _player.playing;
  bool get isPaused =>
      !_player.playing && _player.processingState == ProcessingState.ready;
  String get currentReciterId => _currentReciterId;
  double get playbackSpeed => _playbackSpeed;
  bool get isVerseMode => _isVerseMode;
  VerseRepeatMode get repeatMode => _repeatMode;
  int get totalVerses => _totalVerses;
  int? get currentIndex => _player.currentIndex;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  /// Available reciters from mp3quran.net + everyayah.com verse mapping
  static const List<QuranReciter> reciters = [
    QuranReciter(
      id: 'maher',
      name: 'ماهر المعيقلي',
      server: 'server12.mp3quran.net',
      verseAudioFolder: 'MaherAlMuaiqly128kbps',
    ),
    QuranReciter(
      id: 'maher/Almusshaf-Al-Mojawwad',
      name: 'ماهر المعيقلي مجود',
      server: 'server12.mp3quran.net',
    ),
    QuranReciter(
      id: 'nufais/Rewayat-Hafs-A-n-Assem',
      name: 'أحمد النفيس',
      server: 'server16.mp3quran.net',
    ),
    QuranReciter(
      id: 'islam/Rewayat-Hafs-A-n-Assem',
      name: 'إسلام صبحي',
      server: 'server14.mp3quran.net',
    ),
    QuranReciter(
      id: 'h_dukhain/Rewayat-Hafs-A-n-Assem',
      name: 'هيثم الدخين',
      server: 'server16.mp3quran.net',
    ),
    QuranReciter(
      id: 'kurdi',
      name: 'رعد الكردي',
      server: 'server6.mp3quran.net',
    ),
    QuranReciter(
      id: 'qtm',
      name: 'ناصر القطامي',
      server: 'server6.mp3quran.net',
      verseAudioFolder: 'Nasser_Alqatami_128kbps',
    ),
    QuranReciter(
      id: 'wdee3',
      name: 'وديع اليمني',
      server: 'server6.mp3quran.net',
    ),
    QuranReciter(
      id: 'soufi/Rewayat-Hafs-A-n-Assem',
      name: 'عبدالرشيد صوفي',
      server: 'server16.mp3quran.net',
    ),
    QuranReciter(
      id: 'hthfi',
      name: 'علي الحذيفي',
      server: 'server9.mp3quran.net',
      verseAudioFolder: 'Hudhaify_128kbps',
    ),
    QuranReciter(
      id: 'minsh',
      name: 'محمد المنشاوي',
      server: 'server10.mp3quran.net',
      verseAudioFolder: 'Minshawy_Murattal_128kbps',
    ),
    QuranReciter(
      id: 'husr',
      name: 'محمود الحصري',
      server: 'server13.mp3quran.net',
      verseAudioFolder: 'Husary_128kbps',
    ),
    QuranReciter(
      id: 'afs',
      name: 'مشاري العفاسي',
      server: 'server8.mp3quran.net',
      verseAudioFolder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      id: 's_gmd',
      name: 'سعد الغامدي',
      server: 'server7.mp3quran.net',
      verseAudioFolder: 'Ghamadi_40kbps',
    ),
    QuranReciter(
      id: 'yasser',
      name: 'ياسر الدوسري',
      server: 'server11.mp3quran.net',
    ),
    QuranReciter(
      id: 'hazza',
      name: 'هزاع البلوشي',
      server: 'server11.mp3quran.net',
    ),
    QuranReciter(
      id: 'balilah',
      name: 'بندر بليله',
      server: 'server6.mp3quran.net',
    ),
    QuranReciter(
      id: 'basit',
      name: 'عبد الباسط عبد الصمد',
      server: 'server7.mp3quran.net',
      verseAudioFolder: 'Abdul_Basit_Murattal_192kbps',
    ),
  ];

  QuranReciter get currentReciter =>
      reciters.firstWhere((r) => r.id == _currentReciterId,
          orElse: () => reciters.first);

  QuranReciter get currentVerseReciter {
    final reciter = currentReciter;
    if (reciter.verseAudioFolder == null) {
      return reciters.firstWhere((r) => r.id == 'afs',
          orElse: () => reciters.first);
    }
    return reciter;
  }

  String get _verseAudioFolder =>
      currentVerseReciter.verseAudioFolder ?? 'Alafasy_128kbps';

  Future<void> loadSavedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_selectedReciterKey);
    if (saved != null && reciters.any((r) => r.id == saved)) {
      _currentReciterId = saved;
    }
    _playbackSpeed = prefs.getDouble(_playbackSpeedKey) ?? 1.0;
    await _player.setSpeed(_playbackSpeed);
  }

  Future<void> setReciter(String reciterId) async {
    if (_currentReciterId == reciterId) return;
    _currentReciterId = reciterId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedReciterKey, reciterId);
    if (_player.playing) {
      final surah = _currentSurahNumber;
      await stop();
      if (surah != null) await play(surah);
    }
  }

  String _buildUrl(int surahNumber) {
    final reciter = currentReciter;
    final paddedNum = surahNumber.toString().padLeft(3, '0');
    return 'https://${reciter.server}/${reciter.id}/$paddedNum.mp3';
  }

  String _buildVerseUrl(int surahNumber, int verseNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final verse = verseNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$_verseAudioFolder/$surah$verse.mp3';
  }

  Future<void> play(int surahNumber) async {
    if (_currentSurahNumber == surahNumber && _player.playing) return;

    final surahs = await QuranData.loadSurahs();
    final surah = surahs.firstWhere((s) => s.number == surahNumber);

    _isVerseMode = false;
    _currentSurahNumber = surahNumber;
    try {
      final artUri = await _cachedArtUri();
      final mediaItem = MediaItem(
        id: 'surah_$surahNumber',
        title: surah.name,
        artist: currentReciter.name,
        artUri: artUri,
      );
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(_buildUrl(surahNumber)),
        tag: mediaItem,
      ));
      await _player.play();
    } catch (e) {
      _currentSurahNumber = null;
      rethrow;
    }
  }

  /// Play verse-by-verse audio (used for pages or full surahs)
  Future<void> playPageVerses(
    List<({int surah, int verse})> verses, {
    int startIndex = 0,
    bool isFullSurah = false,
    String? surahName,
  }) async {
    _isVerseMode = true;
    if (!isFullSurah) _currentSurahNumber = null;
    _totalVerses = verses.length;
    _repeatCount = 0;
    _isHandlingRepeat = false;

    try {
      final artUri = await _cachedArtUri();
      final sources = verses.map((v) {
        return AudioSource.uri(
          Uri.parse(_buildVerseUrl(v.surah, v.verse)),
          tag: MediaItem(
            id: '${v.surah}_${v.verse}',
            title: isFullSurah && surahName != null
                ? surahName
                : 'الآية ${v.verse}',
            artist: currentVerseReciter.name,
            artUri: artUri,
          ),
        );
      }).toList();

      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist,
          initialIndex: startIndex, initialPosition: Duration.zero);
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  /// Handle repeat when verse changes. Returns true if verse was repeated.
  bool handleVerseChange(int oldIndex, int newIndex) {
    if (!_isVerseMode || _isHandlingRepeat) return false;
    // Only handle natural forward progression (next verse)
    if (oldIndex < 0 || newIndex != oldIndex + 1) return false;

    switch (_repeatMode) {
      case VerseRepeatMode.none:
        _repeatCount = 0;
        return false;
      case VerseRepeatMode.one:
        if (_repeatCount < 1) {
          _repeatCount++;
          _isHandlingRepeat = true;
          Future.delayed(Duration.zero, () async {
            try {
              await _player.seek(Duration.zero, index: oldIndex);
            } finally {
              _isHandlingRepeat = false;
            }
          });
          return true;
        }
        _repeatCount = 0;
        return false;
      case VerseRepeatMode.two:
        if (_repeatCount < 2) {
          _repeatCount++;
          _isHandlingRepeat = true;
          Future.delayed(Duration.zero, () async {
            try {
              await _player.seek(Duration.zero, index: oldIndex);
            } finally {
              _isHandlingRepeat = false;
            }
          });
          return true;
        }
        _repeatCount = 0;
        return false;
      case VerseRepeatMode.infinite:
        _isHandlingRepeat = true;
        Future.delayed(Duration.zero, () async {
          try {
            await _player.seek(Duration.zero, index: oldIndex);
          } finally {
            _isHandlingRepeat = false;
          }
        });
        return true;
    }
  }

  /// Seek to specific verse
  Future<void> seekToVerse(int index) async {
    if (index >= 0 && index < _totalVerses) {
      _repeatCount = 0;
      await _player.seek(Duration.zero, index: index);
    }
  }

  /// Next verse
  Future<void> nextVerse() async {
    final current = _player.currentIndex ?? 0;
    if (current < _totalVerses - 1) {
      _repeatCount = 0;
      _isHandlingRepeat = true;
      await _player.seek(Duration.zero, index: current + 1);
      _isHandlingRepeat = false;
    }
  }

  /// Previous verse
  Future<void> previousVerse() async {
    final current = _player.currentIndex ?? 0;
    if (current > 0) {
      _repeatCount = 0;
      _isHandlingRepeat = true;
      await _player.seek(Duration.zero, index: current - 1);
      _isHandlingRepeat = false;
    }
  }

  /// Cycle repeat mode
  VerseRepeatMode cycleRepeatMode() {
    switch (_repeatMode) {
      case VerseRepeatMode.none:
        _repeatMode = VerseRepeatMode.one;
        break;
      case VerseRepeatMode.one:
        _repeatMode = VerseRepeatMode.two;
        break;
      case VerseRepeatMode.two:
        _repeatMode = VerseRepeatMode.infinite;
        break;
      case VerseRepeatMode.infinite:
        _repeatMode = VerseRepeatMode.none;
        break;
    }
    _repeatCount = 0;
    return _repeatMode;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSurahNumber = null;
    _isVerseMode = false;
    _repeatCount = 0;
    _isHandlingRepeat = false;
    setSleepTimer(null);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_playbackSpeedKey, speed);
  }

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      _sleepTimerEndTime = null;
      return;
    }
    _sleepTimerEndTime = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      stop();
      _sleepTimerEndTime = null;
    });
  }

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEndTime == null) return null;
    final remaining = _sleepTimerEndTime!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  void dispose() {
    _player.dispose();
  }
}
