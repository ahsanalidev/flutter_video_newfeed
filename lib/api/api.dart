import '../model/video.dart';

abstract class VideoNewFeedApi<V extends VideoInfo> {
  Stream<List<V>> getListVideo();
}
