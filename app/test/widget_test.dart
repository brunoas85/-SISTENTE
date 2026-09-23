import 'package:asistente/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La pantalla de inicio muestra el nombre de la app', (tester) async {
    await tester.pumpWidget(const AsistenteApp());
    expect(find.text('@sistente'), findsWidgets);
  });
}
