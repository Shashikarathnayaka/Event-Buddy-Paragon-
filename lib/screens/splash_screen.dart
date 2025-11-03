import 'dart:async';
import 'dart:developer';
import 'package:event_buddy/services/routes.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SplashStatus { initial, loading, videoReady, imageReady, error, completed }

class SplashConstants {
  static const String videoPath = 'assets/videos/splash_video.mp4';
  static const String imagePath = 'assets/images/splash.png';
  static const int maxVideoWaitTime = 5;
  static const int fallbackWaitTime = 3;
}

class SplashState {
  final SplashStatus status;
  final VideoPlayerController? videoController;
  final String? errorMessage;
  final bool shouldNavigate;

  const SplashState({
    this.status = SplashStatus.initial,
    this.videoController,
    this.errorMessage,
    this.shouldNavigate = false,
  });

  SplashState copyWith({
    SplashStatus? status,
    VideoPlayerController? videoController,
    String? errorMessage,
    bool? shouldNavigate,
  }) {
    return SplashState(
      status: status ?? this.status,
      videoController: videoController ?? this.videoController,
      errorMessage: errorMessage,
      shouldNavigate: shouldNavigate ?? this.shouldNavigate,
    );
  }

  bool get isVideoReady => status == SplashStatus.videoReady;
  bool get hasError => status == SplashStatus.error;
  bool get showImage => status == SplashStatus.imageReady || hasError;
}

class SplashNotifier extends StateNotifier<SplashState> {
  Timer? _navigationTimer;

  SplashNotifier() : super(const SplashState());

  Future<void> initializeVideo() async {
    state = state.copyWith(status: SplashStatus.loading);

    try {
      final controller = VideoPlayerController.asset(SplashConstants.videoPath);

      await controller.initialize();

      state = state.copyWith(
        status: SplashStatus.videoReady,
        videoController: controller,
      );

      controller.play();
      controller.setLooping(false);

      _setNavigationTimer(controller.value.duration.inSeconds);
    } catch (e) {
      log('Video initialization error: $e');
      state = state.copyWith(
        status: SplashStatus.error,
        errorMessage: e.toString(),
      );

      _setNavigationTimer(SplashConstants.fallbackWaitTime);
    }
  }

  void showImageFallback() {
    state = state.copyWith(status: SplashStatus.imageReady);
    _setNavigationTimer(SplashConstants.fallbackWaitTime);
  }

  void _setNavigationTimer(int duration) {
    final waitTime = duration > SplashConstants.maxVideoWaitTime
        ? SplashConstants.maxVideoWaitTime
        : duration;

    _navigationTimer?.cancel();
    _navigationTimer = Timer(Duration(seconds: waitTime), () {
      state = state.copyWith(
        status: SplashStatus.completed,
        shouldNavigate: true,
      );
    });
  }

  void resetNavigation() {
    state = state.copyWith(shouldNavigate: false);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    state.videoController?.dispose();
    super.dispose();
  }
}

final splashProvider =
    StateNotifierProvider.autoDispose<SplashNotifier, SplashState>((ref) {
      final notifier = SplashNotifier();

      Future.microtask(() => notifier.initializeVideo());

      return notifier;
    });

final systemUiModeProvider = Provider<void>((ref) {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  ref.onDispose(() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });

  return;
});

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(systemUiModeProvider);
  }

  void _navigateToLogin() {
    if (mounted) {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashState = ref.watch(splashProvider);

    ref.listen<SplashState>(splashProvider, (previous, next) {
      if (next.shouldNavigate) {
        _navigateToLogin();
        ref.read(splashProvider.notifier).resetNavigation();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.card,
      body: Center(
        child: splashState.isVideoReady && splashState.videoController != null
            ? _VideoSplash(controller: splashState.videoController!)
            : _ImageSplash(hasError: splashState.hasError),
      ),
    );
  }
}

class _VideoSplash extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoSplash({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Welcome to Event Buddy',
          style: TextStyle(
            color: Color.fromARGB(255, 14, 12, 12),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ImageSplash extends StatelessWidget {
  final bool hasError;

  const _ImageSplash({this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              SplashConstants.imagePath,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _ErrorFallback();
              },
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Welcome to Event Buddy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 10),
          const Text(
            'Loading...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class _ErrorFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: const Icon(Icons.event, size: 60, color: Colors.blue),
    );
  }
}

class SimpleSplashScreen extends ConsumerWidget {
  const SimpleSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(systemUiModeProvider);

    final splashState = ref.watch(splashProvider);

    ref.listen<SplashState>(splashProvider, (previous, next) {
      if (next.shouldNavigate && context.mounted) {
        context.go(Routes.login);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.card,
      body: Center(
        child: splashState.isVideoReady && splashState.videoController != null
            ? _VideoSplash(controller: splashState.videoController!)
            : _ImageSplash(hasError: splashState.hasError),
      ),
    );
  }
}
