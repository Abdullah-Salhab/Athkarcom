import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/AnalyticsMixin.dart';

class WirdMusafaReader extends StatefulWidget {
  const WirdMusafaReader({super.key});

  @override
  State<WirdMusafaReader> createState() => _WirdMusafaReaderState();
}

class _WirdMusafaReaderState extends State<WirdMusafaReader> with AnalyticsMixin {
  @override
  String get screenName => 'WirdMusafaTextScreen';

  List<WirdLine> _lines = [];
  bool _isLoading = true;
  double _fontSize = 18.0;
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // YouTube Player State Variables
  YoutubePlayerController? _youtubeController;
  bool _showPlayerPanel = false;
  bool _isLoadingAudio = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Speed and Scroll Tracking Variables
  final List<double> _playbackSpeeds = [1.0, 1.25, 1.5, 1.75, 2.0];
  double _currentSpeed = 1.0;
  int _lastReadIndex = -1;
  List<double> _accumulatedHeights = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTextData();
    _initYoutubePlayer();
  }

  void _initYoutubePlayer() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: 'vNJUs0Gl7ZQ',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
        startAt: 125, // Start at 2:05 (125 seconds)
      ),
    );

    _youtubeController!.addListener(() {
      if (mounted && _youtubeController != null) {
        setState(() {
          _position = _youtubeController!.value.position;
          _duration = _youtubeController!.metadata.duration;
          _isPlaying = _youtubeController!.value.isPlaying;
          _isLoadingAudio = _youtubeController!.value.playerState == PlayerState.buffering;
        });
      }
    });
  }

  void _initAudioStream() {
    if (_youtubeController == null) {
      _initYoutubePlayer();
    }
    _youtubeController!.play();
    setState(() {
      _showPlayerPanel = true;
    });
  }

  void _closeAudioPanel() {
    _youtubeController?.pause();
    setState(() {
      _showPlayerPanel = false;
    });
  }

  void _cyclePlaybackSpeed() {
    if (_youtubeController == null) return;
    int currentIndex = _playbackSpeeds.indexOf(_currentSpeed);
    int nextIndex = (currentIndex + 1) % _playbackSpeeds.length;
    double nextSpeed = _playbackSpeeds[nextIndex];
    _youtubeController!.setPlaybackRate(nextSpeed);
    setState(() {
      _currentSpeed = nextSpeed;
    });
  }

  Future<void> _loadLastReadIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _lastReadIndex = prefs.getInt('wird_musafa_last_index') ?? -1;
      });
    } catch (e) {
      debugPrint("Error loading last read index: $e");
    }
  }

  Future<void> _saveLastReadIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastReadIndex == index) {
        await prefs.remove('wird_musafa_last_index');
        setState(() {
          _lastReadIndex = -1;
        });
      } else {
        await prefs.setInt('wird_musafa_last_index', index);
        setState(() {
          _lastReadIndex = index;
        });
      }
    } catch (e) {
      debugPrint("Error saving last read index: $e");
    }
  }

  void _precomputeHeights() {
    _accumulatedHeights = [];
    double accumulated = 0;
    final scaleFactor = _fontSize / 18.0;
    for (var line in _lines) {
      double cardHeight = line.isHeader 
          ? 70.0 
          : (line.text.length < 100 
              ? 130.0 
              : (line.text.length < 250 ? 195.0 : 300.0)) * scaleFactor;
      accumulated += cardHeight;
      _accumulatedHeights.add(accumulated);
    }
  }

  void _scrollToLastRead() {
    if (_lastReadIndex == -1 || !_scrollController.hasClients || _accumulatedHeights.isEmpty) return;
    
    double targetOffset = _lastReadIndex == 0 ? 0.0 : _accumulatedHeights[_lastReadIndex - 1];
    
    // Scroll 60px further down to ensure card is fully in view below the progress header
    targetOffset += 60.0;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (targetOffset > maxScroll) targetOffset = maxScroll;
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  Future<void> _loadTextData() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/files/wird_musafa.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _lines = jsonData.map((item) => WirdLine.fromJson(item)).toList();
        _isLoading = false;
        _precomputeHeights();
      });
      await _loadLastReadIndex();
    } catch (e) {
      setState(() {
        _lines = [WirdLine(text: "حدث خطأ أثناء تحميل النص: $e", isHeader: false)];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _youtubeController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<TextSpan> _highlightSpans(String text, String query, bool isDark) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();

    int start = 0;
    int index = lowercaseText.indexOf(lowercaseQuery);

    final Color highlightColor =
        isDark ? Colors.teal.shade700 : Colors.yellow.shade200;
    final Color highlightTextColor = isDark ? Colors.white : Colors.black87;

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: highlightColor,
          color: highlightTextColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
      index = lowercaseText.indexOf(lowercaseQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          if (_youtubeController != null)
            Offstage(
              offstage: true,
              child: YoutubePlayer(
                controller: _youtubeController!,
                onReady: () {
                  // Ready
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTextContent(isDark),
          ),
          if (_showPlayerPanel) _buildAudioControlPanel(isDark),
        ],
      ),
      floatingActionButton: _showPlayerPanel
          ? null
          : FloatingActionButton.extended(
              onPressed: _initAudioStream,
              icon: const Icon(Icons.headphones),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              label: const Text(
                'استماع',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text(
        "الذكر المطول",
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 22.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        _buildFontSizeControl(),
        IconButton(
          icon: Icon(_showPlayerPanel
              ? (_isPlaying ? Icons.pause_circle : Icons.play_circle)
              : Icons.play_circle),
          iconSize: 32,
          tooltip: 'استماع',
          onPressed: () {
            if (_showPlayerPanel) {
              if (_isPlaying) {
                _youtubeController?.pause();
              } else {
                _youtubeController?.play();
              }
            } else {
              _initAudioStream();
            }
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchQuery = "";
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          hintText: 'بحث في الذكر...',
          hintStyle: TextStyle(color: Colors.white60, fontFamily: 'Tajawal'),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = "";
                _searchController.clear();
              });
            },
          ),
      ],
    );
  }

  Widget _buildFontSizeControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _fontSize > 18 ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {
            if (_fontSize == 16.0) {
              _fontSize = 18.0;
            } else if (_fontSize == 18.0) {
              _fontSize = 22.0;
            } else if (_fontSize == 22.0) {
              _fontSize = 26.0;
            } else if (_fontSize == 26.0) {
              _fontSize = 30.0;
            } else {
              _fontSize = 16.0;
            }
            _precomputeHeights();
          });
        },
        child: const Text(
          "+ ع",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(bool isDark) {
    if (_lines.isEmpty) {
      return const Center(
        child: Text(
          "لا يوجد نص متاح",
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      );
    }

    return Column(
      children: [
        ReadingProgressHeader(
          scrollController: _scrollController,
          lines: _lines,
          accumulatedHeights: _accumulatedHeights,
          lastReadIndex: _lastReadIndex,
          onScrollToLastRead: _scrollToLastRead,
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding at bottom to avoid control panel overlap
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                if (line.isHeader) {
                  return _buildSectionHeader(line.text, isDark);
                }
                return _buildLitanyCard(line.text, index, isDark);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text, bool isDark) {
    const accentColor = Colors.teal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: accentColor.withOpacity(0.3),
              thickness: 1.0,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: accentColor.withOpacity(0.3),
              thickness: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLitanyCard(String text, int index, bool isDark) {
    final isBookmarked = _lastReadIndex == index;
    const accentColor = Colors.teal;
    
    final cardBgColor = isDark
        ? (isBookmarked ? const Color(0xFF1E3532) : const Color(0xFF1C2826))
        : (isBookmarked ? const Color(0xFFE8F5E9) : Colors.white);

    final borderColor = isBookmarked
        ? accentColor.withOpacity(0.7)
        : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200);

    final shadowColor = isBookmarked
        ? accentColor.withOpacity(0.15)
        : Colors.black.withOpacity(0.03);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isBookmarked ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isBookmarked ? 10.0 : 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isBookmarked)
                Container(
                  width: 5,
                  color: accentColor,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "ذكر ${index + 1}",
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? accentColor : (isDark ? Colors.white60 : Colors.grey.shade400),
                              size: 20,
                            ),
                            tooltip: "تحديد كموضع وقوف",
                            onPressed: () => _saveLastReadIndex(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: _fontSize,
                            height: 1.8,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                          children: _highlightSpans(text, _searchQuery, isDark),
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControlPanel(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E2D2B) : Colors.white;
    const primaryColor = Colors.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "استماع للذكر المطول",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _closeAudioPanel,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingAudio)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: primaryColor.withOpacity(0.2),
                        thumbColor: primaryColor,
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.toDouble().clamp(
                          0.0,
                          _duration.inMilliseconds.toDouble() > 0.0
                              ? _duration.inMilliseconds.toDouble()
                              : 1.0,
                        ),
                        min: 0.0,
                        max: _duration.inMilliseconds.toDouble() > 0.0
                            ? _duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          _youtubeController?.seekTo(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Playback Speed Button
                  TextButton(
                    onPressed: _cyclePlaybackSpeed,
                    child: Text(
                      "${_currentSpeed}x",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: isDark ? Colors.teal.shade300 : Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      final newPosition = _position - const Duration(seconds: 10);
                      _youtubeController?.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                    },
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor,
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        if (_isPlaying) {
                          _youtubeController?.pause();
                        } else {
                          _youtubeController?.play();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      final newPosition = _position + const Duration(seconds: 10);
                      _youtubeController?.seekTo(newPosition > _duration ? _duration : newPosition);
                    },
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WirdLine {
  final String text;
  final bool isHeader;

  WirdLine({required this.text, required this.isHeader});

  factory WirdLine.fromJson(Map<String, dynamic> json) {
    return WirdLine(
      text: json['text'] as String,
      isHeader: json['isHeader'] as bool,
    );
  }
}

class ReadingProgressHeader extends StatefulWidget {
  final ScrollController scrollController;
  final List<WirdLine> lines;
  final List<double> accumulatedHeights;
  final int lastReadIndex;
  final VoidCallback onScrollToLastRead;

  const ReadingProgressHeader({
    super.key,
    required this.scrollController,
    required this.lines,
    required this.accumulatedHeights,
    required this.lastReadIndex,
    required this.onScrollToLastRead,
  });

  @override
  State<ReadingProgressHeader> createState() => _ReadingProgressHeaderState();
}

class _ReadingProgressHeaderState extends State<ReadingProgressHeader> {
  int _currentVisibleIndex = 0;
  double _scrollPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  @override
  void didUpdateWidget(ReadingProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    if (oldWidget.accumulatedHeights != widget.accumulatedHeights ||
        oldWidget.lines != widget.lines) {
      _onScroll();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || widget.lines.isEmpty || widget.accumulatedHeights.isEmpty) return;

    final controller = widget.scrollController;
    if (!controller.hasClients) return;

    final currentOffset = controller.offset;
    final maxScroll = controller.position.maxScrollExtent;
    final percent = maxScroll > 0 ? (currentOffset / maxScroll).clamp(0.0, 1.0) : 0.0;

    int visibleIndex = 0;
    int low = 0;
    int high = widget.accumulatedHeights.length - 1;
    while (low <= high) {
      int mid = (low + high) >> 1;
      if (widget.accumulatedHeights[mid] >= currentOffset) {
        visibleIndex = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    if (percent != _scrollPercentage || visibleIndex != _currentVisibleIndex) {
      setState(() {
        _scrollPercentage = percent;
        _currentVisibleIndex = visibleIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    const accentColor = Colors.teal;
    final headerBgColor = isDark ? const Color(0xFF162523) : Colors.teal.shade50;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final progressPercentage = widget.lastReadIndex == -1
        ? 0.0
        : (widget.lastReadIndex + 1) / widget.lines.length;
    final progressPercentString = (progressPercentage * 100).toStringAsFixed(0);

    final scrollPercentString = (_scrollPercentage * 100).toStringAsFixed(0);
    
    final bool hasScroll = widget.scrollController.hasClients && widget.scrollController.position.maxScrollExtent > 0;
    final actualPercentage = hasScroll ? _scrollPercentage : progressPercentage;
    final actualPercentString = hasScroll ? scrollPercentString : progressPercentString;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerBgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.shade100,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories, color: accentColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.lastReadIndex == -1
                            ? "اضغط على العلامة لحفظ موضع القراءة"
                            : "موضع الوقوف: ذكر ${widget.lastReadIndex + 1} من ${widget.lines.length}",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade100.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty, size: 12, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      "المتبقي: ${widget.lines.length - _currentVisibleIndex} ذكر",
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: actualPercentage,
                    backgroundColor: isDark ? Colors.teal.withOpacity(0.1) : Colors.teal.shade100.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 5.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$actualPercentString%",
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          if (widget.lastReadIndex != -1) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: widget.onScrollToLastRead,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark, color: accentColor, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "الانتقال إلى موضع الوقوف الأخير",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.0,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
