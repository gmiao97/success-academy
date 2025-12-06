class LessonModel {
  String id;
  String name;
  String visibility;
  String zoomLink;
  String zoomId;
  String zoomPassword;

  LessonModel.fromJson(Map<String, Object?> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        visibility = json['visibility'] as String,
        zoomLink = json['zoom_link'] as String,
        zoomId = json['zoom_id'] as String,
        zoomPassword = json['zoom_pw'] as String;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'visibility': visibility,
        'zoom_link': zoomLink,
        'zoom_id': zoomId,
        'zoom_pw': zoomPassword,
      };
}
