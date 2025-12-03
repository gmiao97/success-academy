import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/account/services/user_service.dart'
    as user_service;
import 'package:success_academy/generated/l10n.dart';
import 'package:timezone/data/latest_10y.dart' as tz show initializeTimeZones;
import 'package:timezone/timezone.dart' as tz show timeZoneDatabase;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _timeZoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedTimeZone;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();
    _timeZoneController.text = account.myUser!.timeZone.replaceAll('_', ' ');

    return Center(
      child: Container(
        width: 700,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).settings,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 25),
              Text(S.of(context).timeZoneLabel),
              Autocomplete(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return tz.timeZoneDatabase.locations.keys;
                  }
                  return tz.timeZoneDatabase.locations.keys.where(
                    (timeZone) => timeZone.toLowerCase().contains(
                          textEditingValue.text
                              .toLowerCase()
                              .replaceAll(' ', '_'),
                        ),
                  );
                },
                initialValue: TextEditingValue(text: account.myUser!.timeZone),
                onSelected: (selection) {
                  _selectedTimeZone = selection;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FilledButton.tonal(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final timeZone = _selectedTimeZone?.replaceAll(' ', '_');
                      try {
                        await user_service.updateMyUser(
                          userId: account.firebaseUser!.uid,
                          timeZone: timeZone,
                        );
                        final updatedMyUser = account.myUser!
                          ..timeZone = timeZone ?? account.myUser!.timeZone;
                        account.myUser = updatedMyUser;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).accountUpdated),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(S.of(context).failedAccountUpdate),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                        debugPrint('Failed to update account settings: $e');
                      }
                    }
                  },
                  child: Text(S.of(context).confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
