import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/constants.dart' as constants;
import 'package:success_academy/generated/l10n.dart';

// TODO: Make refresh after email verification automatic.
class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
            ),
            Text(
              constants.homePageAppBarName,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              account.locale = account.locale == 'en' ? 'ja' : 'en';
            },
            child: Text(account.locale == 'en' ? 'US' : 'JP'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: Text(S.of(context).signOut),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 300, maxHeight: 300),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Text(
                      S.of(context).verifyEmailMessage(
                            account.firebaseUser!.email!,
                          ),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(S.of(context).verifyEmailAction),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        // BUG: Only reloads when clicked twice.
                        final firebaseUser = FirebaseAuth.instance.currentUser!;
                        await firebaseUser.reload();
                        if (firebaseUser.emailVerified) {
                          account.authStatus = AuthStatus.signedIn;
                        }
                      },
                      child: Text(S.of(context).reloadPage),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
