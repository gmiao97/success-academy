import 'package:editable/editable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/generated/l10n.dart';
import 'package:success_academy/lesson_info/data/lesson_model.dart';
import 'package:success_academy/lesson_info/services/lesson_info_service.dart'
    as lesson_info_service;
import 'package:success_academy/profile/data/profile_model.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonInfoPage extends StatefulWidget {
  const LessonInfoPage({super.key});

  @override
  State<LessonInfoPage> createState() => _LessonInfoPageState();
}

class _LessonInfoPageState extends State<LessonInfoPage> {
  bool _zoomInfoLoaded = false;
  List<LessonModel> _zoomInfo = [];

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    final account = context.watch<AccountModel>();
    final lessons = await lesson_info_service.getLessons(
      includePreschool: account.userType != UserType.student ||
          account.subscriptionPlan == SubscriptionPlan.minimumPreschool,
    );
    setState(() {
      _zoomInfo = lessons;
      _zoomInfoLoaded = true;
    });
  }

  Widget _getZoomInfoTable(
    UserType userType,
    SubscriptionPlan? subscriptionPlan,
  ) {
    if (userType == UserType.admin) {
      return EditableZoomInfo(
        zoomInfo: _zoomInfo,
      );
    }
    if (userType == UserType.teacher ||
        (subscriptionPlan != null &&
            subscriptionPlan != SubscriptionPlan.monthly)) {
      return ZoomInfo(
        zoomInfo: _zoomInfo,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            S.of(context).lessonInfo,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        Expanded(
          child: Card(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            if (!await launchUrl(
                              Uri.parse(
                                'https://drive.google.com/embeddedfolderview?id=1z5WUmx_lFVRy3YbmtEUH-tIqrwsaP8au#grid',
                              ),
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    content:
                                        Text(S.of(context).openLinkFailure),
                                  ),
                                );
                              }
                            }
                          },
                          label: Text(S.of(context).freeLessonTimeTable),
                          icon: const Icon(Icons.exit_to_app),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            if (!await launchUrl(
                              Uri.parse(
                                'https://drive.google.com/embeddedfolderview?id=1EMhq3GkTEfsk5NiSHpqyZjS4H2N_aSak#grid',
                              ),
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    content:
                                        Text(S.of(context).openLinkFailure),
                                  ),
                                );
                              }
                            }
                          },
                          label: Text(S.of(context).freeLessonMaterials),
                          icon: const Icon(Icons.exit_to_app),
                        ),
                      ],
                    ),
                  ),
                  if (!_zoomInfoLoaded)
                    const CircularProgressIndicator()
                  else
                    _getZoomInfoTable(
                      account.userType,
                      account.subscriptionPlan,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;

  const ZoomInfo({
    super.key,
    required this.zoomInfo,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            S.of(context).freeLessonZoomInfo,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(
            width: 1000,
            child: PaginatedDataTable(
              rowsPerPage: 3,
              columns: <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      S.of(context).lesson,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      S.of(context).link,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      S.of(context).meetingId,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      S.of(context).password,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              source: _ZoomInfoDataSource(context: context, data: zoomInfo),
            ),
          ),
          InkWell(
            onTap: () async {
              if (!await launchUrl(
                Uri.parse(
                  'https://docs.google.com/document/d/1gJuGiJUm85nC0s5WUD_daaOz7JNz0dOQCCKuy2oHckw/edit?usp=sharing',
                ),
              )) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      content: Text(S.of(context).openLinkFailure),
                    ),
                  );
                }
              }
            },
            child: Text(
              S.of(context).lessonRules,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      );
}

class _ZoomInfoDataSource extends DataTableSource {
  final BuildContext context;
  final List<LessonModel> data;

  _ZoomInfoDataSource({
    required this.context,
    required this.data,
  });

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int i) => DataRow(
        cells: [
          DataCell(Text(data[i].name)),
          DataCell(
            InkWell(
              child: const Text(
                'Zoom',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
              onTap: () async {
                if (!await launchUrl(Uri.parse(data[i].zoomLink))) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        content: Text(S.of(context).openLinkFailure),
                      ),
                    );
                  }
                }
              },
            ),
          ),
          DataCell(Text(data[i].zoomId)),
          DataCell(Text(data[i].zoomPassword)),
        ],
      );
}

class EditableZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;

  const EditableZoomInfo({
    super.key,
    required this.zoomInfo,
  });

  @override
  Widget build(BuildContext context) {
    final headers = [
      {
        'title': S.of(context).lesson,
        'widthFactor': 0.15,
        'index': 1,
        'key': 'name',
      },
      {
        'title': S.of(context).link,
        'widthFactor': 0.3,
        'index': 2,
        'key': 'zoom_link',
      },
      {
        'title': S.of(context).meetingId,
        'widthFactor': 0.1,
        'index': 3,
        'key': 'zoom_id',
      },
      {
        'title': S.of(context).password,
        'index': 4,
        'key': 'zoom_pw',
      },
    ];

    return Column(
      children: [
        Text(
          S.of(context).freeLessonZoomInfo,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(
          height: 500,
          child: Editable(
            columns: headers,
            rows: zoomInfo.map((lesson) => lesson.toJson()).toList(),
            // showCreateButton: true,
            showSaveIcon: true,
            saveIconColor: Theme.of(context).primaryColor,
            onRowSaved: (value) async {
              if (value == 'no edit') {
                return;
              }

              final i = value['row'];
              value.remove('row');

              value.forEach((k, v) {
                switch (k) {
                  case 'name':
                    zoomInfo[i].name = v;
                  case 'zoom_link':
                    zoomInfo[i].zoomLink = v;
                  case 'zoom_id':
                    zoomInfo[i].zoomId = v;
                  case 'zoom_pw':
                    zoomInfo[i].zoomPassword = v;
                }
              });
              try {
                await lesson_info_service.updateLesson(
                  zoomInfo[i].id,
                  zoomInfo[i],
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        S.of(context).lessonInfoUpdated,
                      ),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Failed to update lesson info: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).lessonInfoUpdateFailed),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            onSubmitted: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    S.of(context).promptSave,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
