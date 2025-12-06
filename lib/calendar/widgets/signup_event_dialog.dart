import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/calendar/calendar_utils.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/calendar/services/event_service.dart'
    as event_service;
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;

class SignupEventDialog extends StatefulWidget {
  final EventModel event;
  final VoidCallback refresh;

  const SignupEventDialog({
    super.key,
    required this.event,
    required this.refresh,
  });

  @override
  State<SignupEventDialog> createState() => _SignupEventDialogState();
}

class _SignupEventDialogState extends State<SignupEventDialog> {
  bool _submitClicked = false;

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();
    final studentProfile = context
        .select<AccountModel, StudentProfileModel>((a) => a.studentProfile!);
    final canSignUp = widget.event.eventType == EventType.private
        ? widget.event.startTime.difference(DateTime.now()) >
            const Duration(hours: 24)
        : widget.event.startTime.difference(DateTime.now()) >
            const Duration(minutes: 5);
    final numPoints = account.hasPointsDiscount()
        ? (widget.event.numPoints * .9).floor()
        : widget.event.numPoints;
    final enoughPoints = account.studentProfile!.numPoints >= numPoints;

    return AlertDialog(
      title: Text(S.of(context).signup),
      content: !canSignUp
          ? Text(S.of(context).signupWindowPassed)
          : enoughPoints
              ? Text(
                  S
                      .of(context)
                      .usePoints(numPoints, account.studentProfile!.numPoints),
                )
              : Text(S.of(context).notEnoughPoints),
      actions: [
        TextButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        if (_submitClicked)
          Transform.scale(
            scale: 0.5,
            child: const CircularProgressIndicator(),
          )
        else
          TextButton(
            onPressed: !canSignUp || !enoughPoints
                ? null
                : () async {
                    setState(() {
                      _submitClicked = true;
                    });
                    if (!isStudentInEvent(
                      studentProfile.profileId,
                      widget.event,
                    )) {
                      widget.event.studentIdList.add(studentProfile.profileId);
                      try {
                        await event_service.updateEvent(widget.event);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).signupSuccess),
                            ),
                          );
                          // TODO: Handle/log error.
                          studentProfile.numPoints -= numPoints;
                          account.studentProfile = studentProfile;
                          profile_service.updateStudentProfile(
                            account.firebaseUser!.uid,
                            studentProfile,
                          );
                          event_service.emailAttendees(
                            widget.event,
                            studentProfile.profileId,
                          );
                        }
                      } catch (e) {
                        widget.event.studentIdList.removeWhere(
                          (id) => id == studentProfile.profileId,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(S.of(context).signupFailure),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      } finally {
                        Navigator.of(context).pop();
                        widget.refresh();
                      }
                    }
                  },
            child: Text(S.of(context).confirm),
          ),
      ],
    );
  }
}
