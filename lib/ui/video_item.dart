import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_video_newfeed/config/video_item_config.dart';
import 'package:flutter_video_newfeed/model/video.dart';
import 'package:video_player/video_player.dart';

import 'built_in/default_video_info.dart';

class VideoItemWidget<V extends VideoInfo> extends StatefulWidget {
  final int pageIndex;
  final int currentPageIndex;
  final bool isPaused;

  /// Video ended callback
  ///
  final void Function()? videoEnded;

  final VideoItemConfig config;

  /// Video Information: like count, like, more, name song, ....
  ///
  final V videoInfo;

//  /// Video network url
//  ///
//  final String url;

  /// Video Info Customizable
  ///
  final Widget Function(BuildContext context, V v)? customVideoInfoWidget;

  VideoItemWidget(
      {

      /// video information
      required this.videoInfo,

      /// video config
      this.config = const VideoItemConfig(
          loop: true,
          itemLoadingWidget: CircularProgressIndicator(),
          autoPlayNextVideo: true),
      required this.pageIndex,
      required this.currentPageIndex,
      required this.isPaused,
      this.customVideoInfoWidget,
      this.videoEnded})
      : assert(videoInfo.url != null);

  @override
  State<StatefulWidget> createState() => _VideoItemWidgetState<V>();
}

class _VideoItemWidgetState<V extends VideoInfo>
    extends State<VideoItemWidget<V>> {
  late VideoPlayerController _videoPlayerController;
  bool initialized = false;
  bool actualDisposed = false;
  bool isEnded = false;

  ///
  ///
  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  ///
  ///
  @override
  Widget build(BuildContext context) {
    _pauseAndPlayVideo();
    bool isLandscape = false;
    if (_videoPlayerController.value.isInitialized) {
      isLandscape = _videoPlayerController.value.size.width >
          _videoPlayerController.value.size.height;
    }

    return Center(
      child: Stack(
        children: [
          initialized
              ? isLandscape
                  ? _renderLandscapeVideo()
                  : _renderPortraitVideo()
              : Container(),
          _renderVideoInfo(),
        ],
      ),
    );
  }

  ///
  ///
  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController.removeListener(_videoListener);
      _videoPlayerController.dispose();
    }

    actualDisposed = true;
    super.dispose();
  }

  /// Video initialization
  ///
  void _initVideoController() {
    // Init video from network url
    var _videoUrl = widget.videoInfo.url;
    if (_videoUrl != null) {
      _videoPlayerController = VideoPlayerController.network(_videoUrl);
      _videoPlayerController.addListener(_videoListener);
      _videoPlayerController.initialize().then((_) {
        setState(() {
          _videoPlayerController.setLooping(widget.config.loop);
          initialized = true;
        });
      });
    }
  }

  /// Video controller listener
  ///
  void _videoListener() {
    if (_videoPlayerController.value.position != null &&
        _videoPlayerController.value.duration != null) {
      /// check if video has ended
      ///
      if (_videoPlayerController.value.position >=
          _videoPlayerController.value.duration) {
        if (widget.config.autoPlayNextVideo &&
            widget.videoEnded != null &&
            !isEnded) {
          isEnded = true;
          widget.videoEnded!();
        }
      }
    }
  }

  void _pauseAndPlayVideo() {
    if (_videoPlayerController != null) {
      if (widget.pageIndex == widget.currentPageIndex &&
          !widget.isPaused &&
          initialized) {
        _videoPlayerController.play().then((value) {});
      } else {
        _videoPlayerController.pause().then((value) {});
      }
    }
  }

  Widget _renderLandscapeVideo() {
    if (_videoPlayerController != null) {
      return Center(
        child: AspectRatio(
          child: VideoPlayer(_videoPlayerController),
          aspectRatio: _videoPlayerController.value.aspectRatio,
        ),
      );
    } else {
      return Center(
        child: Text('Error Has Occured'),
      );
    }
  }

  Widget _renderPortraitVideo() {
    var tmp = MediaQuery.of(context).size;

    var screenH = max(tmp.height, tmp.width);
    var screenW = min(tmp.height, tmp.width);
    tmp = _videoPlayerController.value.size;

    var previewH = max(tmp.height, tmp.width);
    var previewW = min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return Center(
      child: OverflowBox(
        child: VideoPlayer(_videoPlayerController),
        maxHeight: screenRatio > previewRatio
            ? screenH
            : screenW / previewW * previewH,
        maxWidth: screenRatio > previewRatio
            ? screenH / previewH * previewW
            : screenW,
      ),
    );
  }

  Widget _renderVideoInfo() {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Container(
      width: w,
      height: h,
      child: widget.customVideoInfoWidget != null
          ? widget.customVideoInfoWidget!(context, widget.videoInfo)
          : DefaultVideoInfoWidget(),
    );
  }
}
