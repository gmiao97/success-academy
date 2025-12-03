import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/constants.dart' as constants;
import 'package:success_academy/firebase_options.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/landing/widgets/email_verification_page.dart';
import 'package:success_academy/landing/widgets/landing_page.dart';
import 'package:success_academy/landing/widgets/terms_page.dart';
import 'package:success_academy/profile/widgets/profile_browse_page.dart';
import 'package:success_academy/profile/widgets/profile_create_page.dart';
import 'package:success_academy/scaffold/widgets/my_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  if (kDebugMode) {
    FirebaseFunctions.instanceFor(region: 'us-west2')
        .useFunctionsEmulator('localhost', 5001);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AccountModel(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AccountModel, String>((a) => a.locale);

    return MaterialApp(
      title: constants.homePageAppBarName,
      theme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.lightBlue,
          accentColor: Colors.amber,
          backgroundColor: Colors.grey[200],
          cardColor: Colors.white,
        ),
      ),
      locale: Locale(locale),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FirebaseUILocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Root(),
      routes: {
        constants.routeInfo: (context) => const TermsPage(),
        constants.routeCreateProfile: (context) => const ProfileCreatePage(),
      },
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final authStatus = context
        .select<AccountModel, AuthStatus>((account) => account.authStatus);
    final userType = context.select<AccountModel, UserType>((a) => a.userType);

    if (authStatus == AuthStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (authStatus == AuthStatus.emailVerification) {
      return const EmailVerificationPage();
    }
    if (authStatus == AuthStatus.signedOut) {
      return const LandingPage();
    }
    if (userType == UserType.studentNoProfile) {
      return const ProfileBrowsePage();
    }
    return const MyScaffold();
  }
}
