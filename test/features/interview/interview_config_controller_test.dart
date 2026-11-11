import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/features/interview/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/shared/domain/entities/interview_config.dart';
import 'package:prep_up/shared/domain/entities/interview_tags.dart';

void main() {
  test('empieza incompleta y avisa en cada cambio', () {
    final controller = InterviewConfigController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    expect(controller.isComplete, isFalse);
    expect(controller.config.missingFields, [
      InterviewConfigField.type,
      InterviewConfigField.jobRole,
      InterviewConfigField.duration,
    ]);

    controller.setType(InterviewType.technical);
    controller.setJobRole(JobRole.mobileDeveloper);
    controller.setDurationMinutes(0);
    expect(controller.isComplete, isFalse);

    controller.setDurationMinutes(15);
    expect(controller.isComplete, isTrue);
    expect(notifications, 4);

    controller.reset();
    expect(controller.isComplete, isFalse);
    expect(notifications, 5);
  });
}
