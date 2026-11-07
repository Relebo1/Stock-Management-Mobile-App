import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate_mobile/main.dart';

void main() {
  testWidgets('shows the StockMate home page', (tester) async {
    await tester.pumpWidget(const StockMateApp());

    expect(find.text('StockMate'), findsOneWidget);
  });
}
