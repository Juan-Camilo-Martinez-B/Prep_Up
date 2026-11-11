import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Comprueba que el workflow que ve Linear sigue lanzando la suite.
void main() {
  test('Actions ejecuta flutter test en cada pull request', () {
    final workflow = File('.github/workflows/pruebas.yml').readAsStringSync();

    expect(workflow, contains('name: Pruebas'));
    expect(workflow, contains('pull_request'));
    expect(workflow, contains('flutter test'));
    expect(workflow, contains('Unidad, integración y carga'));
  });
}
