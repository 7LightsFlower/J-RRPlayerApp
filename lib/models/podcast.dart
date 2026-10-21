class PodcastEpisode {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String? imageUrl;
  final String? channelImageUrl;
  final DateTime publishedDate;
  final Duration? duration;
  final String channelId;
  final String channelTitle;

  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.imageUrl,
    this.channelImageUrl,
    required this.publishedDate,
    this.duration,
    required this.channelId,
    required this.channelTitle,
  });

  PodcastEpisode copyWith({
    String? id,
    String? title,
    String? description,
    String? audioUrl,
    String? imageUrl,
    String? channelImageUrl,
    DateTime? publishedDate,
    Duration? duration,
    String? channelId,
    String? channelTitle,
  }) {
    return PodcastEpisode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      channelImageUrl: channelImageUrl ?? this.channelImageUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      duration: duration ?? this.duration,
      channelId: channelId ?? this.channelId,
      channelTitle: channelTitle ?? this.channelTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'channelImageUrl': channelImageUrl,
      'description': description,
      'duration': duration?.inSeconds,
      'publishedDate': publishedDate.toIso8601String(),
      'channelId': channelId,
      'channelTitle': channelTitle,
    };
  }

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    return PodcastEpisode(
      id: json['id'],
      title: json['title'],
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
      channelImageUrl: json['channelImageUrl'],
      description: json['description'],
      // duration может быть null (toJson пишет null, если длина неизвестна)
      duration: json['duration'] is int
          ? Duration(seconds: json['duration'] as int)
          : null,
      publishedDate: DateTime.parse(json['publishedDate']),
      channelId: json['channelId'],
      channelTitle: json['channelTitle'],
    );
  }
}