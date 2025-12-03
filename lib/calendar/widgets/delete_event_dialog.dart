import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/calendar/calendar_utils.dart';
import 'package:success_academy/calendar/data/event_model.dart';
import 'package:success_academy/calendar/services/event_service.dart'
    as event_service;
import 'package:success_academy/generated/l10n.dart';
import 'package:timezone/data/latest_10y.dart' as tz show initializeTimeZones;
import 'package:timezone/timezone.dart' as tz show getLocation;

typedef OnDeleteEventCallback = Function({
  required String eventId,
  bool isRecurrence,
  DateTime? start,
});

enum _DeleteRange {
  single,
  future,
  all;

  String getName(BuildContext context) {
    switch (this) {
      case _DeleteRange.single:
        return S.of(context).deleteSingle;
      case _DeleteRange.future:
        return S.of(context).deleteFuture;
      case _DeleteRange.all:
        return S.of(context).deleteAll;
    }
  }
}

class DeleteEventDialog extends StatefulWidget {
  const DeleteEventDialog({
    super.key,
    required this.event,
    required this.onDeleteEvent,
  });

  final EventModel event;
  final OnDeleteEventCallback onDeleteEvent;

  @override
  State<DeleteEventDialog> createState() => _DeleteEventDialogState();
}

class _DeleteEventDialogState extends State<DeleteEventDialog> {
  _DeleteRange _deleteRange = _DeleteRange.single;
  EventModel? _recurrenceEvent;
  bool _submitClicked = false;
  bool _isLoadingRecurringEvent = true;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadRecurrenceEvent();
  }

  Future<void> _loadRecurrenceEvent() async {
    final recurrenceId = widget.event.recurrenceId;
    if (recurrenceId != null) {
      try {
        final event = await event_service.getEvent(
          eventId: recurrenceId,
          location:
              tz.getLocation(context.read<AccountModel>().myUser!.timeZone),
        );
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {
            _recurrenceEvent = event;
            _isLoadingRecurringEvent = false;
          });
        });
      } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).failedGetRecurrenceEvent),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        });
      }
    } else {
      _isLoadingRecurringEvent = false;
    }
  }

  void _onDeleteRangeChanged(_DeleteRange? value) => setState(() {
        _deleteRange = value!;
      });

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRecurringEvent) {
      return AlertDialog(
        title: Text(S.of(context).deleteEvent),
        content: const SizedBox(
          width: 300,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        actions: [
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            onPressed: null,
            child: Text(S.of(context).confirm),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(S.of(context).deleteEvent),
      content: widget.event.recurrenceId == null
          ? null
          : SizedBox(
              width: 300,
              height: 200,
              child: ListView(
                children: [
                  RadioListTile<_DeleteRange>(
                    title: Text(_DeleteRange.single.getName(context)),
                    value: _DeleteRange.single,
                    groupValue: _deleteRange,
                    onChanged: _onDeleteRangeChanged,
                  ),
                  RadioListTile<_DeleteRange>(
                    title: Text(_DeleteRange.future.getName(context)),
                    value: _DeleteRange.future,
                    groupValue: _deleteRange,
                    onChanged: _onDeleteRangeChanged,
                  ),
                  RadioListTile<_DeleteRange>(
                    title: Text(_DeleteRange.all.getName(context)),
                    value: _DeleteRange.all,
                    groupValue: _deleteRange,
                    onChanged: _onDeleteRangeChanged,
                  ),
                ],
              ),
            ),
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
            child: Text(S.of(context).confirm),
            onPressed: () async {
              setState(() {
                _submitClicked = true;
              });
              try {
                switch (_deleteRange) {
                  case _DeleteRange.single:
                    await event_service.deleteEvent(
                      eventId: widget.event.eventId!,
                    );
                    widget.onDeleteEvent(
                      eventId: widget.event.eventId!,
                    );
                  case _DeleteRange.future:
                    final rrule = RecurrenceRule.fromString(
                      _recurrenceEvent!.recurrence[0],
                    );
                    final cutoff = widget.event.startTime
                        .subtract(const Duration(seconds: 1));

                    _recurrenceEvent!.recurrence = buildRecurrence(
                      frequency: rrule.frequency,
                      until: cutoff,
                    );
                    await event_service.updateEvent(_recurrenceEvent!);
                    widget.onDeleteEvent(
                      eventId: widget.event.recurrenceId!,
                      isRecurrence: true,
                      start: cutoff,
                    );
                  case _DeleteRange.all:
                    await event_service.deleteEvent(
                      eventId: widget.event.recurrenceId!,
                    );
                    widget.onDeleteEvent(
                      eventId: widget.event.recurrenceId!,
                      isRecurrence: true,
                    );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).deleteEventSuccess),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).deleteEventFailure),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } finally {
                Navigator.of(context).pop();
              }
            },
          ),
      ],
    );
  }
}
