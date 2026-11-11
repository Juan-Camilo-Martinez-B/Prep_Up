import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/shared/domain/entities/user_model.dart';

void main() {
  test('lee el nombre nuevo y una ocupación exacta', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'email': 'ana@correo.com',
      'full_name': 'Ana Ruiz',
      'occupation': 'teacher',
      'created_at': '2026-05-04T00:00:00.000Z',
    });

    expect(user.displayName, 'Ana Ruiz');
    expect(user.occupation, UserOccupation.teacher);
  });

  test('migra un texto libre antiguo a una ocupación', () {
    final student = UserModel.fromJson({
      'occupation': 'Estudiante de ingeniería',
    });
    final professional = UserModel.fromJson({
      'displayName': 'Camilo',
      'occupation': 'Desarrollador',
    });

    expect(student.occupation, UserOccupation.student);
    expect(professional.displayName, 'Camilo');
    expect(professional.occupation, UserOccupation.professional);
  });

  test('sin ocupación deja el campo vacío', () {
    final user = UserModel.fromJson({'occupation': '   '});

    expect(user.occupation, isNull);
    expect(user.id, isEmpty);
  });
}
