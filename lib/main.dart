import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state/library_store.dart';
import 'state/music_controller.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';
import 'data/youtube_audio_source.dart';
import 'state/discovery_store.dart';
import 'offline/native_music.dart';
import 'offline/download_store.dart';
import 'package:audio_session/audio_session.dart';
import 'data/ios_player_script.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final native = IosMusic();
  final source = YoutubeAudioSource(
      playerScript: native.supported ? IosPlayerScript() : null);
  final downloads = DownloadStore(native, source);
  try {
    await downloads.initialize();
  } catch (_) {
    downloads.error = 'No se pudo abrir la biblioteca local.';
  }
  if (native.supported) {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
  runApp(AleksoundApp(
      controller: MusicController(LibraryStore(preferences),
          source: source,
          downloads: downloads,
          discovery: DiscoveryStore(source))));
}

class AleksoundApp extends StatefulWidget {
  const AleksoundApp({super.key, required this.controller});
  final MusicController controller;
  @override
  State<AleksoundApp> createState() => _AleksoundAppState();
}

class _AleksoundAppState extends State<AleksoundApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller.library,
        builder: (context, _) => MaterialApp(
          title: 'Aleksound',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: switch (widget.controller.library.appearance) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          home: AppShell(controller: widget.controller),
        ),
      );
}
