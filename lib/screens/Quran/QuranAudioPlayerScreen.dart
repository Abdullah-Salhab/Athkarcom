import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:athkar/models/quran_model.dart';
import 'package:athkar/models/quran_audio_service.dart';
import 'package:athkar/models/SettingsProvider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class QuranAudioPlayerScreen extends StatefulWidget {
  const QuranAudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<QuranAudioPlayerScreen> createState() => _QuranAudioPlayerScreenState();
}

class _QuranAudioPlayerScreenState extends State<QuranAudioPlayerScreen> with SingleTickerProviderStateMixin {
  final QuranAudioService _audioService = QuranAudioService();
  List<QuranSurah> _surahs = [];
  List<QuranSurah> _filteredSurahs = [];
  bool _isLoading = true;
  Timer? _uiTimer;
  QuranReciter _selectedReciter = QuranAudioService.reciters.first;
  bool _isFocusMode = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;

  // Nature background features
  int _natureSeed = 0;
  Timer? _natureTimer;

  @override
  void initState() {
    super.initState();
    _initService();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _natureTimer?.cancel();
    _pulseController.dispose();
    _searchController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initService() async {
    await _audioService.loadSavedReciter();
    _selectedReciter = _audioService.currentReciter;
    final surahs = await QuranData.loadSurahs();
    setState(() {
      _surahs = surahs;
      _filteredSurahs = surahs;
      _isLoading = false;
    });
  }

  void _toggleFocusMode([bool? forceVal]) {
    final nextVal = forceVal ?? !_isFocusMode;
    setState(() => _isFocusMode = nextVal);
    
    if (_isFocusMode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _natureSeed = DateTime.now().millisecondsSinceEpoch;
      _natureTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          setState(() => _natureSeed = DateTime.now().millisecondsSinceEpoch);
        }
      });
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      _natureTimer?.cancel();
    }
  }

  void _showSleepTimerDialog(Color primaryGreen, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final options = [
          {'label': 'إيقاف المؤقت', 'duration': null},
          {'label': '٥ دقائق', 'duration': const Duration(minutes: 5)},
          {'label': '١٥ دقيقة', 'duration': const Duration(minutes: 15)},
          {'label': '٣٠ دقيقة', 'duration': const Duration(minutes: 30)},
          {'label': '٤٥ دقيقة', 'duration': const Duration(minutes: 45)},
          {'label': 'ستون دقيقة (ساعة)', 'duration': const Duration(minutes: 60)},
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مؤقت النوم', style: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final dur = opt['duration'] as Duration?;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                  leading: Icon(dur == null ? Icons.timer_off_outlined : Icons.timer_outlined, color: primaryGreen),
                  title: Text(opt['label'] as String, style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                  onTap: () {
                    _audioService.setSleepTimer(dur);
                    Navigator.pop(context);
                    setState(() {});
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showReciterGridPicker(Color primaryGreen, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('اختر القارئ', style: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: QuranAudioService.reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = QuranAudioService.reciters[index];
                    final isSelected = reciter.id == _selectedReciter.id;
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() => _selectedReciter = reciter);
                        await _audioService.setReciter(reciter.id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGreen.withOpacity(0.1) : (isDark ? Colors.grey[900] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? primaryGreen : Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: isSelected ? primaryGreen : Colors.grey.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(Icons.person_rounded, color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(reciter.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryGreen : (isDark ? Colors.white70 : Colors.black87)))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _cycleSpeed() {
    double current = _audioService.playbackSpeed;
    double next = 1.0;
    if (current == 1.0) next = 1.25;
    else if (current == 1.25) next = 1.5;
    else if (current == 1.5) next = 2.0;
    else next = 1.0;
    _audioService.setSpeed(next);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 0) return '00:00';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  String _formatClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _buildTopHeader(Color primaryGreen, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showReciterGridPicker(primaryGreen, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: primaryGreen.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.spatial_audio_off_rounded, color: primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('القارئ الحالي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: primaryGreen, fontWeight: FontWeight.w600)),
                        Text(_selectedReciter.name, style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, color: isDark ? Colors.white54 : Colors.black54),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (val) {
              String removeHarakat(String input) {
                // Removes Arabic diacritics (Tashkeel)
                return input.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
              }
              setState(() {
                final normalizedVal = removeHarakat(val);
                _filteredSurahs = _surahs.where((s) {
                  return removeHarakat(s.name).contains(normalizedVal);
                }).toList();
              });
            },
            style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'ابحث عن سورة...',
              hintStyle: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white54 : Colors.black38),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.black38),
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: SpinKitFadingCube(color: Color.fromRGBO(12, 151, 159, 1.0))),
      );
    }
    
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isNight;
    const primaryGreen = Color.fromRGBO(12, 151, 159, 1.0);
    const accentGold = Color(0xFFD4AF37);
    final sleepRemaining = _audioService.sleepTimerRemaining;

    return PopScope(
      canPop: !_isFocusMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFocusMode) {
          _toggleFocusMode(false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8),
        appBar: _isFocusMode 
          ? null 
          : AppBar(
              backgroundColor: primaryGreen,
              elevation: 0,
              centerTitle: true,
              title: const Text('صوتيات القرآن', style: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: _isFocusMode 
            ? _buildZenMode(primaryGreen, accentGold) 
            : Column(
                key: const ValueKey('ListMode'),
                children: [
                  _buildTopHeader(primaryGreen, isDark),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: _filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = _filteredSurahs[index];
                        return StreamBuilder<PlayerState>(
                          stream: _audioService.playerStateStream,
                          builder: (context, snapshot) {
                            final isThisPlaying = _audioService.currentSurahNumber == surah.number;
                            final isSpinning = isThisPlaying && (_audioService.player.playing || _audioService.player.processingState == ProcessingState.loading);
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isThisPlaying ? primaryGreen.withOpacity(0.05) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isThisPlaying ? primaryGreen.withOpacity(0.5) : Colors.transparent),
                                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    gradient: isThisPlaying ? LinearGradient(colors: [primaryGreen, primaryGreen.withBlue(180)]) : null,
                                    color: isThisPlaying ? null : (isDark ? Colors.grey[800] : Colors.grey[100]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isSpinning 
                                      ? const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20) 
                                      : Text('${surah.number}', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: isThisPlaying ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                                  ),
                                ),
                                title: Text(surah.name, style: TextStyle(fontFamily: 'Amiri', fontSize: 19, fontWeight: isThisPlaying ? FontWeight.bold : FontWeight.normal, color: isThisPlaying ? primaryGreen : (isDark ? Colors.white : Colors.black87))),
                                subtitle: Text('${surah.ayahs.length} آية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400])),
                                trailing: isThisPlaying 
                                  ? Icon(Icons.play_circle_fill_rounded, color: primaryGreen, size: 28) 
                                  : Icon(Icons.play_arrow_rounded, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                                onTap: () async {
                                  if (isThisPlaying) {
                                    if (_audioService.player.playing) await _audioService.pause();
                                    else await _audioService.resume();
                                  } else {
                                    try { await _audioService.play(surah.number); }
                                    catch (e) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصوت غير متوفر حالياً', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.redAccent));
                                    }
                                  }
                                },
                              ),
                            );
                          }
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
        bottomNavigationBar: !_isFocusMode ? _buildModernBottomPlayer(primaryGreen, isDark, sleepRemaining) : null,
      ),
    );
  }

  Widget _buildModernBottomPlayer(Color primaryGreen, bool isDark, Duration? sleepRemaining) {
    return StreamBuilder<PlayerState>(
      stream: _audioService.playerStateStream,
      builder: (context, stateSnapshot) {
        final state = stateSnapshot.data;
        if (state == null) return const SizedBox.shrink();
        final surahNum = _audioService.currentSurahNumber;
        if (surahNum == null) return const SizedBox.shrink();
        final surahName = _surahs.firstWhere((s) => s.number == surahNum, orElse: () => _surahs.first).name;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E).withOpacity(0.9) : Colors.white.withOpacity(0.95),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  
                  // Top info row + status icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              sleepRemaining != null ? Icons.timer : Icons.timer_off_rounded,
                              color: sleepRemaining != null ? const Color(0xFFD4AF37) : (isDark ? Colors.white54 : Colors.black54),
                            ),
                            onPressed: () => _showSleepTimerDialog(primaryGreen, isDark),
                          ),
                          if (sleepRemaining != null)
                             Text(_formatDuration(sleepRemaining), style: const TextStyle(fontFamily: 'Tajawal', color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                        ]
                      ),
                      
                      Row(
                        children: [
                          InkWell(
                            onTap: _cycleSpeed,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text('${_audioService.playbackSpeed}x', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: primaryGreen)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.center_focus_strong_rounded , color: Colors.deepPurple, size: 28),
                            onPressed: () => _toggleFocusMode(true),
                          ),
                        ]
                      ),
                    ],
                  ),
                  
                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(surahName, style: TextStyle(fontFamily: 'Amiri', fontSize: 24, color: primaryGreen, fontWeight: FontWeight.bold)),
                      Text(_selectedReciter.name, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  StreamBuilder<Duration>(
                    stream: _audioService.positionStream,
                    builder: (context, posSnapshot) {
                      final position = posSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: _audioService.durationStream,
                        builder: (context, durSnapshot) {
                          final duration = durSnapshot.data ?? Duration.zero;
                          final posVal = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                                child: Slider(
                                  activeColor: primaryGreen,
                                  inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
                                  value: posVal.clamp(0.0, 1.0),
                                  onChanged: (v) {
                                    final newPos = Duration(milliseconds: (v * duration.inMilliseconds).round());
                                    _audioService.seekTo(newPos);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position), style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[500], fontWeight: FontWeight.w600)),
                                    Text(_formatDuration(duration), style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[500], fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )
                            ],
                          );
                        }
                      );
                    }
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.stop_rounded, size: 36, color: Colors.orange[400]),
                        onPressed: () { _audioService.stop(); setState((){}); },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded, size: 36, color: isDark ? Colors.white70 : Colors.black87),
                        onPressed: () async {
                          if (surahNum < 114) {
                            try { await _audioService.play(surahNum + 1); } catch (e) {}
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryGreen, primaryGreen.withBlue(180)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: IconButton(
                          icon: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.white),
                          onPressed: () {
                            if (state.playing) _audioService.pause();
                            else _audioService.resume();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded, size: 36, color: isDark ? Colors.white70 : Colors.black87),
                        onPressed: () async {
                          if (surahNum > 1) {
                            try { await _audioService.play(surahNum - 1); } catch (e) {}
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildZenMode(Color primaryGreen, Color accentGold) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Container(
          key: const ValueKey('ZenMode'),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: NetworkImage('https://picsum.photos/1080/1920?nature&t=$_natureSeed'),
              fit: BoxFit.cover,
            )
          ),
          child: Stack(
            children: [
              // Dark elegant overlay blending with the animated primary color
              Container(color: Colors.black.withOpacity(0.55)),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          primaryGreen.withOpacity(0.3 + (_pulseController.value * 0.2)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              StreamBuilder<PlayerState>(
                stream: _audioService.playerStateStream,
                builder: (context, stateSnapshot) {
                  final surahNum = _audioService.currentSurahNumber;
                  final surahName = surahNum != null ? _surahs.firstWhere((s) => s.number == surahNum, orElse: () => _surahs.first).name : 'لم يتم تحديده';
                  final isPlaying = stateSnapshot.data?.playing ?? false;
                  final sleepRemaining = _audioService.sleepTimerRemaining;

                  final contentWidgets = <Widget>[
                    // Beautiful Clock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Text(_formatClock(), style: const TextStyle(fontFamily: 'Tajawal', fontSize: 32, letterSpacing: 4, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(surahName, style: const TextStyle(fontFamily: 'Amiri', fontSize: 52, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 4))])),
                    const SizedBox(height: 8),
                    Text(_selectedReciter.name, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 20, color: Colors.white70, shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))])),
                    const SizedBox(height: 48),
                    
                    // Focus Player Settings
                    Container(
                      width: orientation == Orientation.landscape ? MediaQuery.of(context).size.width * 0.45 : double.infinity,
                      margin: orientation == Orientation.landscape ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StreamBuilder<Duration>(
                            stream: _audioService.positionStream,
                            builder: (context, posSnapshot) {
                              final position = posSnapshot.data ?? Duration.zero;
                              return StreamBuilder<Duration?>(
                                stream: _audioService.durationStream,
                                builder: (context, durSnapshot) {
                                  final duration = durSnapshot.data ?? Duration.zero;
                                  final posVal = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;
                                  return Column(
                                    children: [
                                      SliderTheme(
                                        data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                                        child: Slider(
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white24,
                                          value: posVal.clamp(0.0, 1.0),
                                          onChanged: (v) {
                                            final newPos = Duration(milliseconds: (v * duration.inMilliseconds).round());
                                            _audioService.seekTo(newPos);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_formatDuration(position), style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                                            Text(_formatDuration(duration), style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                    ],
                                  );
                                }
                              );
                            }
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.stop_rounded, size: 36, color: Colors.orangeAccent),
                                onPressed: () { _audioService.stop(); setState((){}); },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded, size: 36, color: Colors.white),
                                onPressed: () async {
                                  if (surahNum != null && surahNum < 114) try { await _audioService.play(surahNum + 1); } catch(e){}
                                },
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
                                child: IconButton(
                                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.black),
                                  onPressed: () {
                                    if (isPlaying) _audioService.pause();
                                    else _audioService.resume();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded, size: 36, color: Colors.white),
                                onPressed: () async {
                                  if (surahNum != null && surahNum > 1) try { await _audioService.play(surahNum - 1); } catch(e){}
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ];

                  return Stack(
                    children: [
                      // Top Row
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                                onPressed: () => _toggleFocusMode(false),
                              ),
                            ),
                            // Sleep Timer badge
                            if (sleepRemaining != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: accentGold.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text('إيقاف خلال ${_formatDuration(sleepRemaining)}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              )
                            else
                              const SizedBox(),
                          ],
                        ),
                      ),
                      
                      // Central Content oriented conditionally
                      Center(
                        child: orientation == Orientation.landscape
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    contentWidgets[0], // Clock
                                    contentWidgets[1], // Spacing
                                    contentWidgets[2], // Surah
                                    contentWidgets[3], // Spacing
                                    contentWidgets[4], // Reciter
                                  ],
                                ),
                                contentWidgets[6], // Media Player
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Use all generated spacing
                                  for (var widget in contentWidgets) widget,
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        );
      }
    );
  }
}
