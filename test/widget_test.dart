import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:certainty/widgets/music_sidebar.dart';
import 'package:certainty/widgets/settings_sidebar.dart';
import 'package:certainty/services/music_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class FakeMusicPlayer extends Fake implements MusicPlayer {
  final StreamController<int> currentIndexController;
  final StreamController<Duration> positionController;
  final StreamController<Duration> durationController;
  final StreamController<PlayerState> playerStateController;

  FakeMusicPlayer({
    required this.currentIndexController,
    required this.positionController,
    required this.durationController,
    required this.playerStateController,
  });

  @override
  Stream<int> get currentIndexStream => currentIndexController.stream;

  @override
  Stream<Duration> get onPositionChanged => positionController.stream;

  @override
  Stream<Duration> get onDurationChanged => durationController.stream;

  @override
  Stream<PlayerState> get playerStateStream => playerStateController.stream;

  @override
  PlayerState get playerState => PlayerState.paused;

  @override
  bool get isPlaying => false;

  @override
  void selectTrack(int index) {}

  @override
  Future<void> togglePlayPause() async {}

  @override
  void playNext() {}

  @override
  void playPrevious() {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

void main() {
  late FakeMusicPlayer mockMusicPlayer;
  late ScrollController testScrollController;

  late StreamController<int> currentIndexController;
  late StreamController<Duration> positionController;
  late StreamController<Duration> durationController;
  late StreamController<PlayerState> playerStateController;

  setUp(() {
    currentIndexController = StreamController<int>.broadcast();
    positionController = StreamController<Duration>.broadcast();
    durationController = StreamController<Duration>.broadcast();
    playerStateController = StreamController<PlayerState>.broadcast();

    mockMusicPlayer = FakeMusicPlayer(
      currentIndexController: currentIndexController,
      positionController: positionController,
      durationController: durationController,
      playerStateController: playerStateController,
    );
    testScrollController = ScrollController();

    currentIndexController.add(0);
    positionController.add(Duration.zero);
    durationController.add(const Duration(minutes: 3));
    playerStateController.add(PlayerState.paused);
  });

  tearDown(() {
    currentIndexController.close();
    positionController.close();
    durationController.close();
    playerStateController.close();
    testScrollController.dispose();
  });

  testWidgets('MusicSidebar maintains scroll position after reopening',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Test App'),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
          ),
          drawer: MusicSidebar(
            musicPlayer: mockMusicPlayer,
            scrollController: testScrollController,
          ),
          body: const Center(child: Text('Home')),
        ),
      ),
    );

    // Ensure the drawer is closed initially
    expect(find.byType(Drawer), findsNothing);

    // Open the drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify the drawer is open
    expect(find.byType(Drawer), findsOneWidget);

    final listViewFinder = find.byType(ListView);
    expect(listViewFinder, findsOneWidget);

    // Scroll down by 300 pixels
    await tester.fling(listViewFinder, const Offset(0, -300), 1000);
    await tester.pumpAndSettle();

    final double scrollOffsetAfterScroll = testScrollController.offset;

    // Close the drawer by tapping the scrim / popping
    await tester.tapAt(const Offset(700, 300));
    await tester.pumpAndSettle();

    // Reopen the drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify the drawer is open again
    expect(find.byType(Drawer), findsOneWidget);

    // Ensure the ScrollController's offset is preserved
    expect(testScrollController.offset, equals(scrollOffsetAfterScroll));
  });

  testWidgets('SettingsSidebar displays options and triggers callback',
      (WidgetTester tester) async {
    bool favoritesToggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: SettingsSidebar(
            currentShareMessage: 'Test message',
            onUpdateShareMessage: (_) {},
            onToggleFavorites: () {
              favoritesToggled = true;
            },
            onAddNewTruth: (_) {},
            onToggleCustomTruths: () {},
            showingFavorites: false,
            showingCustomTruths: false,
          ),
          body: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
    );

    // Open settings drawer
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Certainty'), findsOneWidget);
    expect(find.text('Your personal truth compass'), findsOneWidget);
    expect(find.text('Toggle Favorites'), findsOneWidget);
    expect(find.text('Toggle Custom Truths'), findsOneWidget);
    expect(find.text('Add New Truth'), findsOneWidget);
    expect(find.text('Edit Share Message'), findsOneWidget);

    // Tap toggle favorites
    await tester.tap(find.text('Toggle Favorites'));
    await tester.pumpAndSettle();

    expect(favoritesToggled, isTrue);
  });
}
