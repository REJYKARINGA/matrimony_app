enum AppEnvironment { local, dev, test, prod }

class AppConfig {
  // Current environment - CHANGE THIS TO SWITCH URLS
  static AppEnvironment _environment = AppEnvironment.prod;
//   static AppEnvironment _environment = AppEnvironment.local;

  static void setEnvironment(AppEnvironment env) {
    _environment = env;
  }

  static AppEnvironment get environment => _environment;

  static String get baseUrl {
    switch (_environment) {
      case AppEnvironment.prod:
        return 'http://43.205.99.214/api';
      case AppEnvironment.test:
        return 'https://matrimonybackend-test.up.railway.app/api'; // Change this as needed
      case AppEnvironment.dev:
        return 'https://matrimonybackend-dev.up.railway.app/api'; // Change this as needed
      case AppEnvironment.local:
      default:
        return 'http://localhost:8000/api';
    }
  }
  
  // Helper to get raw base URL (without /api)
  static String get rawBaseUrl => baseUrl.replaceAll('/api', '');

  // Helper to get Reverb host (just the domain/IP)
  static String get reverbHost {
    return Uri.parse(baseUrl).host;
  }
}
