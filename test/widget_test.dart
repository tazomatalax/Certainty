import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Certainty/widgets/music_sidebar.dart';
import 'package:Certainty/services/music_player.dart';
import 'package:mockito/mockito.dart';
import 'package:audioplayers/audioplayers.dart'; // Importing PlayerState
import 'dart:async';

// Create a MockMusicPlayer using Mockito
class MockMusicPlayer extends Mock implements MusicPlayer {}

void main() {
  late MockMusicPlayer mockMusicPlayer;
  late ScrollController testScrollController;

  // StreamControllers for mocking streams
  late StreamController<int> currentIndexController;
  late StreamController<Duration> positionController;
  late StreamController<Duration> durationController;
  late StreamController<PlayerState> playerStateController;

  setUp(() {
    mockMusicPlayer = MockMusicPlayer();
    testScrollController = ScrollController();

    // Initialize StreamControllers
    currentIndexController = StreamController<int>.broadcast();
    positionController = StreamController<Duration>.broadcast();
    durationController = StreamController<Duration>.broadcast();
    playerStateController = StreamController<PlayerState>.broadcast();

    // Mock the streams to return the StreamControllers' streams
    when(mockMusicPlayer.currentIndexStream)
        .thenAnswer((_) => currentIndexController.stream);
    when(mockMusicPlayer.onPositionChanged)
        .thenAnswer((_) => positionController.stream);
    when(mockMusicPlayer.onDurationChanged)
        .thenAnswer((_) => durationController.stream);
    when(mockMusicPlayer.playerStateStream)
        .thenAnswer((_) => playerStateController.stream);

    // Mock initial values if necessary
    when(mockMusicPlayer.playerState).thenReturn(PlayerState.paused);

    // Optionally, add initial data to streams
    currentIndexController.add(0);
    positionController.add(Duration.zero);
    durationController.add(Duration(minutes: 3));
    playerStateController.add(PlayerState.paused);
  });

  tearDown(() {
    // Dispose StreamControllers to prevent memory leaks
    currentIndexController.close();
    positionController.close();
    durationController.close();
    playerStateController.close();
    testScrollController.dispose();
  });

  testWidgets('MusicSidebar maintains scroll position after reopening',
      (WidgetTester tester) async {
    // Build the widget tree with MusicSidebar inside a Scaffold
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
            scrollController: testScrollController, // Injecting the ScrollController
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

    // Find the ListView in the MusicSidebar
    final listViewFinder = find.byType(ListView);
    expect(listViewFinder, findsOneWidget);

    // Scroll down by 300 pixels
    await tester.fling(listViewFinder, const Offset(0, -300), 1000);
    await tester.pumpAndSettle();

    // Capture the current scroll position
    final double scrollOffsetAfterScroll = testScrollController.offset;
    print('Scroll Offset After Scroll: $scrollOffsetAfterScroll');

    // Close the drawer by tapping the back button
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Reopen the drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify the drawer is open again
    expect(find.byType(Drawer), findsOneWidget);

    // Ensure the ScrollController's offset is preserved
    expect(testScrollController.offset, equals(scrollOffsetAfterScroll));

    // Optionally, attempt to scroll again to ensure scrolling is still active
    await tester.fling(listViewFinder, const Offset(0, -100), 1000);
    await tester.pumpAndSettle();

    // Verify the new scroll position has increased
    expect(testScrollController.offset, greaterThan(scrollOffsetAfterScroll));
  });
}