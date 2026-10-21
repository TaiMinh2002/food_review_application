import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  dotenv.loadFromString(envString: 'APP_ENV=test');
  await testMain();
}
