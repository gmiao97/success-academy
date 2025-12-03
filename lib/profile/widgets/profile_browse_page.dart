import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/constants.dart' as constants;
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;

class ProfileBrowsePage extends StatefulWidget {
  const ProfileBrowsePage({super.key});

  @override
  State<ProfileBrowsePage> createState() => _ProfileBrowsePageState();
}

class _ProfileBrowsePageState extends State<ProfileBrowsePage> {
  static const maxProfiles = 5;
  List<StudentProfileModel> _studentProfiles = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initProfiles();
  }

  Future<void> initProfiles() async {
    final account = context.watch<AccountModel>();
    final studentProfiles = await profile_service
        .getStudentProfilesForUser(account.firebaseUser!.uid);
    setState(() {
      _studentProfiles = studentProfiles;
    });
  }

  Widget _buildProfileCard(BuildContext context, StudentProfileModel profile) {
    final account = context.watch<AccountModel>();

    return CircleAvatar(
      radius: 100,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: InkWell(
        onTap: () {
          account.studentProfile = profile;
        },
        child: Text(
          profile.firstName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  S.of(context).selectProfile,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 20),
                OverflowBar(
                  alignment: MainAxisAlignment.center,
                  overflowAlignment: OverflowBarAlignment.center,
                  spacing: 10,
                  overflowSpacing: 10,
                  children: [
                    for (final profile in _studentProfiles)
                      _buildProfileCard(context, profile),
                    if (_studentProfiles.length < maxProfiles)
                      const _AddProfileWidget(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProfileWidget extends StatelessWidget {
  const _AddProfileWidget();

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 100,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, constants.routeCreateProfile);
          },
          child: const Icon(
            Icons.add,
            size: 50,
          ),
        ),
      );
}
