// Entry point for driving the app from tools (flutter_driver). Same app as lib/main.dart,
// plus the driver extension that lets a test tool tap, type and read widgets.
import 'package:chat_app/main.dart' as app;
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  app.main();
}
