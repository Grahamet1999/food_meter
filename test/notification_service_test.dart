import 'package:flutter_test/flutter_test.dart';
import 'package:food_meter/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    test('initialize does not throw', () async {
      await NotificationService.initialize();
    });

    test('showNotification does not throw', () async {
      await NotificationService.showNotification(
        id: 123,
        title: 'Test Item expiring',
        body: 'Your Test Item expires in 1 day!',
      );
    });
  });
}
