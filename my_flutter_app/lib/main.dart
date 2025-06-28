import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen_professional.dart';
import 'screens/onboarding_account_screen_professional.dart';
import 'screens/personality_test_disclaimer_screen_professional.dart';
import 'screens/personality_test_screen_professional_fixed_v2.dart';
import 'screens/personality_results_screen_professional.dart';
import 'screens/premium_screen_professional.dart';
import 'screens/keyboard_intro_screen_professional.dart';
import 'screens/relationship_questionnaire_screen_professional.dart';
import 'screens/relationship_profile_screen_professional.dart';
// import 'screens/analyze_tone_screen_professional.dart';
import 'screens/settings_screen_professional.dart';
import 'screens/keyboard_setup_screen.dart';
import 'screens/tone_indicator_demo_screen.dart';
import 'screens/tone_indicator_test_screen.dart';
import 'screens/tone_indicator_tutorial_screen.dart';
import 'screens/tutorial_demo_screen.dart';
import 'screens/color_test_screen.dart';
import 'screens/main_shell.dart';
import 'data/randomized_personality_questions.dart';
import 'screens/relationship_insights_dashboard.dart';
import 'screens/smart_message_templates.dart';
import 'screens/secure_attachment_coaching.dart';
import 'screens/predictive_ai_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Load environment variables
  // await Firebase.initializeApp(); // Uncomment when ready

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Optionally send to crash reporting
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Something went wrong.\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const UnsaidApp());
}

class UnsaidApp extends StatelessWidget {
  const UnsaidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // This ensures the app is accessible at the root level.
      label: 'Unsaid communication and relationship app',
      child: MaterialApp(
        title: 'Unsaid',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        navigatorObservers: [MyNavigatorObserver()],
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/splash':
              return MaterialPageRoute(
                builder: (context) => const SplashScreenProfessional(),
              );
            case '/onboarding':
              return MaterialPageRoute(
                builder: (context) => OnboardingAccountScreenProfessional(
                  onContinueAsGuest: () => Navigator.pushReplacementNamed(
                    context,
                    '/personality_test_disclaimer',
                  ),
                  onSignInWithApple: () => Navigator.pushReplacementNamed(
                    context,
                    '/personality_test_disclaimer',
                  ),
                  onSignInWithGoogle: () => Navigator.pushReplacementNamed(
                    context,
                    '/personality_test_disclaimer',
                  ),
                ),
              );
            case '/personality_test_disclaimer':
              return MaterialPageRoute(
                builder: (context) =>
                    PersonalityTestDisclaimerScreenProfessional(
                      onAgree: () => Navigator.pushReplacementNamed(
                        context,
                        '/personality_test',
                      ),
                    ),
              );
            case '/personality_test':
              final randomizedQuestions =
                  RandomizedPersonalityTest.getRandomizedQuestions();
              return MaterialPageRoute(
                builder: (context) => PersonalityTestScreenProfessional(
                  currentIndex: 0,
                  answers: List<String?>.filled(
                    randomizedQuestions.length,
                    null,
                  ),
                  questions: randomizedQuestions
                      .map(
                        (q) => {'question': q.question, 'options': q.options},
                      )
                      .toList(),
                ),
              );
            case '/personality_results':
              final args = settings.arguments as List<String>? ?? [];
              return MaterialPageRoute(
                builder: (context) =>
                    PersonalityResultsScreenProfessional(answers: args),
              );
            case '/premium':
              return MaterialPageRoute(
                builder: (context) => PremiumScreenProfessional(
                  onContinue: () =>
                      Navigator.pushReplacementNamed(context, '/tone_tutorial'),
                ),
              );
            case '/keyboard_intro':
              return MaterialPageRoute(
                builder: (context) => KeyboardIntroScreenProfessional(
                  onSkip: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                ),
              );
            case '/home':
              return MaterialPageRoute(builder: (context) => const MainShell());
            case '/relationship_questionnaire':
              return MaterialPageRoute(
                builder: (context) =>
                    const RelationshipQuestionnaireScreenProfessional(),
              );
            case '/relationship_profile':
              return MaterialPageRoute(
                builder: (context) =>
                    const RelationshipProfileScreenProfessional(),
              );
            // case '/analyze_tone':
            //   return MaterialPageRoute(builder: (context) => const AnalyzeToneScreenProfessional());
            case '/settings':
              return MaterialPageRoute(
                builder: (context) => SettingsScreenProfessional(
                  sensitivity: 0.5,
                  onSensitivityChanged: (value) {},
                  tone: 'Polite',
                  onToneChanged: (tone) {},
                ),
              );
            case '/keyboard_setup':
              return MaterialPageRoute(
                builder: (context) => const KeyboardSetupScreen(),
              );
            case '/tone_demo':
              return MaterialPageRoute(
                builder: (context) => const ToneIndicatorDemoScreen(),
              );
            case '/tone_test':
              return MaterialPageRoute(
                builder: (context) => const ToneIndicatorTestScreen(),
              );
            case '/tone_tutorial':
              return MaterialPageRoute(
                builder: (context) => ToneIndicatorTutorialScreen(
                  onComplete: () => Navigator.pushReplacementNamed(
                    context,
                    '/keyboard_intro',
                  ),
                ),
              );
            case '/tutorial_demo':
              return MaterialPageRoute(
                builder: (context) => const TutorialDemoScreen(),
              );
            case '/color_test':
              return MaterialPageRoute(
                builder: (context) => const ColorTestScreen(),
              );
            case '/relationship_insights':
              return MaterialPageRoute(
                builder: (context) => const RelationshipInsightsDashboard(
                  // Example: Pass attachment/communication style if needed
                  // attachmentStyle: ...,
                  // communicationStyle: ...,
                ),
              );
            case '/communication_coach':
              return MaterialPageRoute(
                builder: (context) => const RealTimeCommunicationCoach(),
              );
            case '/message_templates':
              return MaterialPageRoute(
                builder: (context) => const SmartMessageTemplates(),
              );
            case '/secure_attachment_coaching':
              return MaterialPageRoute(
                builder: (context) => const SecureAttachmentCoachingPage(),
              );
            case '/predictive_ai':
              return MaterialPageRoute(
                builder: (context) => const PredictiveAITab(),
              );
            default:
              return MaterialPageRoute(
                builder: (context) =>
                    Scaffold(body: Center(child: Text('404 - Page not found'))),
              );
          }
        },
      ),
    );
  }
}

class RealTimeCommunicationCoach extends StatelessWidget {
  const RealTimeCommunicationCoach({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with your actual UI
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Communication Coach')),
      body: const Center(child: Text('Real-Time Communication Coach Content')),
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // Send analytics event here
    super.didPush(route, previousRoute);
  }
}
