import 'package:flutter_test/flutter_test.dart';
import 'package:carnetizacion/main.dart';
import 'package:carnetizacion/config/provider/auth_provider.dart';

void main() {
  testWidgets('Prueba de arranque de la aplicación', (
    WidgetTester tester,
  ) async {
    // 1. Creamos una instancia vacía de tu AuthProvider solo para la prueba
    final authProvider = AuthProvider();

    // 2. Construimos tu app y le pasamos el provider requerido (¡Adiós error!)
    await tester.pumpWidget(MyApp(authProvider: authProvider));

    // 3. Simplemente verificamos que el widget MyApp se haya renderizado en pantalla
    expect(find.byType(MyApp), findsOneWidget);
  });
}
