import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/generated/l10n.dart';

class AdminProfileView extends StatelessWidget {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            S.of(context).profile,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(
                        account.adminProfile!.lastName[0],
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${account.adminProfile!.lastName}, ${account.adminProfile!.firstName}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      S.of(context).admin,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '${S.of(context).myCode} - ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: account.myUser?.referralCode,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: account.myUser!.referralCode,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context).copied),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
