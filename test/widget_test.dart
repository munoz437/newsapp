import 'package:flutter_test/flutter_test.dart';
import 'package:newsapp/main.dart';
import 'package:newsapp/screens/news_feed_screen.dart';

void main() {
  testWidgets('NewsApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our NewsFeedScreen is loaded as the home widget.
    expect(find.byType(NewsFeedScreen), findsOneWidget);
  });
}
