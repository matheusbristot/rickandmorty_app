import 'app.dart';
import 'core/environment/app_environment.dart';

Future<void> main() => bootstrap(
  appEnvironmentFromDefine(
    const String.fromEnvironment('APP_ENV', defaultValue: 'prd'),
    fallback: AppEnvironment.prd,
  ),
);
