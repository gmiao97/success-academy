import 'package:flutter/material.dart';
import 'package:success_academy/constants.dart';
import 'package:success_academy/generated/l10n.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.maybePop(context);
                },
                label: Text(S.of(context).goBack),
                icon: const Icon(Icons.chevron_left),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).termsOfUse,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Divider(),
                      ...termsOfUse.map(
                        (line) => Text(
                          line,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
