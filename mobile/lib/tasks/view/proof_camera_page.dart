import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

/// Takes a task's proof photos, one slot at a time, from the live camera
/// only, recording where (GPS and its accuracy) and when each was taken.
///
/// Opened from a task, it returns there when the last photo is in; opened
/// from the tab bar, it then shows the task.
class ProofCameraPage extends StatefulWidget {
  const new({this.slotId, this.returnsToTask = true, super.key});

  /// The slot to start with; the first without a photo by default.
  final String? slotId;

  /// Whether a task screen is underneath to go back to.
  final bool returnsToTask;

  @override
  State<ProofCameraPage> createState() => _ProofCameraPageState();
}

enum _Problem { noCamera, cameraDenied, locationOff, locationDenied }

class _ProofCameraPageState extends State<ProofCameraPage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  StreamSubscription<Position>? _positions;
  Position? _position;
  _Problem? _problem;
  String? _slotId;
  bool _flash = false;
  bool _shooting = false;

  @override
  void initState() {
    super.initState();
    _slotId = widget.slotId;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_positions?.cancel());
    unawaited(_camera?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera is released while the app is in the background.
    if (state == AppLifecycleState.inactive) {
      final camera = _camera;
      _camera = null;
      if (mounted) setState(() {});
      unawaited(camera?.dispose());
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    await Future.wait([_startCamera(), _startLocation()]);
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return _fail(_Problem.noCamera);
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await camera.initialize();
      if (!mounted) return unawaited(camera.dispose());
      setState(() => _camera = camera);
    } on CameraException catch (e) {
      _fail(
        e.code.contains('Denied') ? _Problem.cameraDenied : _Problem.noCamera,
      );
    }
  }

  Future<void> _startLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return _fail(_Problem.locationOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _fail(_Problem.locationDenied);
    }
    await _positions?.cancel();
    _positions =
        Geolocator.getPositionStream(locationSettings: const LocationSettings())
            .listen((p) {
              if (mounted) setState(() => _position = p);
            }, onError: (Object _) => _fail(_Problem.locationOff));
  }

  void _fail(_Problem problem) {
    if (mounted) setState(() => _problem = problem);
  }

  ProofSlot? _slot(Task task) {
    for (final slot in task.photos) {
      if (slot.id == _slotId && !slot.done) return slot;
    }
    return task.nextSlot;
  }

  Future<void> _shoot(Task task, ProofSlot slot) async {
    final camera = _camera;
    final position = _position;
    if (camera == null || position == null || _shooting) return;
    setState(() => _shooting = true);
    final cubit = context.read<TaskCubit>();
    try {
      final shot = await camera.takePicture();
      final ok = await cubit.addPhoto(
        slotId: slot.id,
        file: UploadFile(name: shot.name, bytes: await shot.readAsBytes()),
        localUrl: 'file:${shot.path}',
        fix: CaptureFix(
          lat: position.latitude,
          lng: position.longitude,
          accuracyM: position.accuracy,
          takenAt: DateTime.now(),
          mocked: position.isMocked,
        ),
      );
      if (!mounted || !ok) return;
      await HapticFeedback.mediumImpact();
      final next = cubit.state.task?.nextSlot;
      if (next == null) {
        _finish();
      } else {
        setState(() => _slotId = next.id);
      }
    } on CameraException {
      // Shown as the cubit's failure would be: try again.
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  void _finish() {
    if (widget.returnsToTask) {
      context.pop();
    } else {
      final cubit = context.read<TaskCubit>();
      context.pushReplacement(AppRoutes.task(cubit.taskId), extra: cubit);
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null) return;
    final on = !_flash;
    await camera.setFlashMode(on ? FlashMode.always : FlashMode.off);
    if (mounted) setState(() => _flash = on);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<TaskCubit>().state;
    final task = state.task;
    final slot = task == null ? null : _slot(task);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SolaColors.cameraBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_camera case final camera? when camera.value.isInitialized)
              ExcludeSemantics(child: _Preview(camera: camera)),
            const _TopShade(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    slot: slot,
                    index: task == null || slot == null
                        ? 0
                        : task.photos.indexOf(slot) + 1,
                    count: task?.photos.length ?? 0,
                    flash: _flash,
                    onClose: () => context.pop(),
                    onFlash: _camera == null
                        ? null
                        : () => unawaited(_toggleFlash()),
                  ),
                  Expanded(
                    child: Center(
                      child: _problem != null
                          ? _ProblemNotice(problem: _problem!)
                          : _Guide(hint: slot?.hint),
                    ),
                  ),
                  _Panel(
                    task: task,
                    slot: slot,
                    position: _position,
                    failure: state.failure?.message(l10n),
                    busy: _shooting || state.busy,
                    onSlot: (id) => setState(() => _slotId = id),
                    onShoot:
                        task == null ||
                            slot == null ||
                            _camera == null ||
                            _position == null
                        ? null
                        : () => unawaited(_shoot(task, slot)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The live camera, filling the screen like the designs.
class _Preview extends StatelessWidget {
  const new({required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    // Scale the preview up until it covers the screen, cropping the rest.
    final screen = MediaQuery.sizeOf(context);
    var scale = screen.aspectRatio * camera.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(camera)),
      ),
    );
  }
}

/// Shades the top of the camera so the slot's name reads on any scene.
class _TopShade extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SolaColors.cameraShade, SolaColors.cameraShadeClear],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const new({
    required this.slot,
    required this.index,
    required this.count,
    required this.flash,
    required this.onClose,
    required this.onFlash,
  });

  final ProofSlot? slot;
  final int index;
  final int count;
  final bool flash;
  final VoidCallback onClose;
  final VoidCallback? onFlash;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slot = this.slot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SolaSpace.space16,
        SolaSpace.space8,
        SolaSpace.space16,
        0,
      ),
      child: Row(
        children: [
          _GlassButton(
            key: const Key('camera_close'),
            icon: SolaIcons.close,
            label: l10n.closeCamera,
            onTap: onClose,
          ),
          Expanded(
            child: Column(
              spacing: SolaSpace.space2,
              children: [
                if (slot != null) ...[
                  SolaText(
                    l10n.shotOf(index, count),
                    style: SolaTextStyle.eyebrow,
                    color: SolaColors.cameraText,
                  ),
                  SolaText(
                    slot.label,
                    style: SolaTextStyle.navTitle,
                    color: SolaColors.surface,
                  ),
                ],
              ],
            ),
          ),
          _GlassButton(
            key: const Key('camera_flash'),
            icon: SolaIcons.flash,
            label: flash ? l10n.flashOn : l10n.flashOff,
            selected: flash,
            onTap: onFlash,
          ),
        ],
      ),
    );
  }
}

/// A round button over the camera.
class _GlassButton extends StatelessWidget {
  const new({
    required Key super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final SolaIcons icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: label,
      selected: selected,
      onTap: onTap,
      builder: (context, state) => SizedBox.square(
        dimension: SolaSize.tapMin,
        child: Center(
          child: Container(
            width: SolaSize.navButton,
            height: SolaSize.navButton,
            decoration: BoxDecoration(
              color: selected ? SolaColors.sun : SolaColors.cameraGlass,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SolaIcon(
                icon,
                size: 20,
                color: selected ? SolaColors.ink : SolaColors.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The frame to fit the subject in, and the slot's hint.
class _Guide extends StatelessWidget {
  const new({required this.hint});

  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: SolaSpace.space14,
      children: [
        Container(
          width: 196,
          height: 172,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SolaRadius.radius22),
            border: Border.all(color: SolaColors.surface, width: 2),
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space34),
            child: SolaText(
              hint,
              style: SolaTextStyle.bodyStrong,
              color: SolaColors.surface,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _ProblemNotice extends StatelessWidget {
  const new({required this.problem});

  final _Problem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, body) = switch (problem) {
      _Problem.noCamera => (l10n.cameraUnavailable, l10n.cameraUnavailableBody),
      _Problem.cameraDenied => (l10n.cameraDenied, l10n.cameraDeniedBody),
      _Problem.locationOff => (l10n.locationOff, l10n.locationOffBody),
      _Problem.locationDenied => (l10n.locationDenied, l10n.locationDeniedBody),
    };
    return Padding(
      padding: const EdgeInsets.all(SolaSpace.space20),
      child: SolaNotice(
        title: title,
        body: body,
        tone: SolaTone.warning,
        announce: true,
        action: SolaButton(
          key: const Key('camera_settings'),
          label: l10n.openSettings,
          variant: SolaButtonVariant.white,
          compact: true,
          expand: false,
          onPressed: () => unawaited(
            problem == _Problem.locationOff
                ? Geolocator.openLocationSettings()
                : Geolocator.openAppSettings(),
          ),
        ),
      ),
    );
  }
}

/// Where the phone is and when, the slots, and the shutter.
class _Panel extends StatelessWidget {
  const new({
    required this.task,
    required this.slot,
    required this.position,
    required this.failure,
    required this.busy,
    required this.onSlot,
    required this.onShoot,
  });

  final Task? task;
  final ProofSlot? slot;
  final Position? position;
  final String? failure;
  final bool busy;
  final ValueChanged<String> onSlot;
  final VoidCallback? onShoot;

  String _where(AppLocalizations l10n) {
    final p = position;
    final site = task?.customer;
    if (p == null) return l10n.findingLocation;
    final accuracy = l10n.accuracyM(p.accuracy.round());
    if (site?.lat == null || site?.lng == null) return accuracy;
    final metres = Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      site!.lat!,
      site.lng!,
    );
    final distance = metres < 200
        ? l10n.atSite
        : l10n.fromSiteKm((metres / 1000).toStringAsFixed(1));
    return '$distance · $accuracy';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = this.task;
    final failure = this.failure;
    return Container(
      padding: EdgeInsets.fromLTRB(
        SolaSpace.space20,
        SolaSpace.space16,
        SolaSpace.space20,
        SolaSpace.space20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: SolaColors.cameraPanel,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SolaRadius.radius34),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: SolaSpace.space14,
        children: [
          Semantics(
            liveRegion: true,
            child: Container(
              height: SolaSize.pill + 6,
              padding: const EdgeInsets.symmetric(
                horizontal: SolaSpace.space14,
              ),
              decoration: BoxDecoration(
                color: SolaColors.cameraGlass,
                borderRadius: BorderRadius.circular(SolaRadius.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: SolaSpace.space6,
                children: [
                  const SolaIcon(
                    SolaIcons.pin,
                    size: 14,
                    color: SolaColors.surface,
                  ),
                  Flexible(
                    child: SolaText(
                      '${_where(l10n)} · ${formatDayMonth(DateTime.now())}, '
                      '${formatTime(DateTime.now())}',
                      style: SolaTextStyle.chip,
                      color: SolaColors.surface,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (failure != null)
            SolaText(
              failure,
              style: SolaTextStyle.meta,
              color: SolaColors.sun,
              textAlign: TextAlign.center,
            ),
          if (task != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: SolaSpace.space10,
              children: [
                for (final (i, s) in task.photos.indexed)
                  _SlotThumb(
                    key: ValueKey('camera_slot_${s.id}'),
                    slot: s,
                    number: i + 1,
                    current: s.id == slot?.id,
                    onTap: s.done ? null : () => onSlot(s.id),
                  ),
              ],
            ),
          SizedBox(
            height: 84,
            child: Center(
              child: _Shutter(busy: busy, onTap: busy ? null : onShoot),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotThumb extends StatelessWidget {
  const new({
    required Key super.key,
    required this.slot,
    required this.number,
    required this.current,
    required this.onTap,
  });

  final ProofSlot slot;
  final int number;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final image = slot.done ? imageFor(slot.photo?.url) : null;
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: slot.done
          ? l10n.photoAdded(slot.label)
          : l10n.photoMissing(slot.label),
      selected: current,
      onTap: onTap,
      builder: (context, state) => SizedBox.square(
        dimension: SolaSize.tapMin,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SolaRadius.radius12),
            border: Border.all(
              color: current ? SolaColors.sun : SolaColors.cameraGlass,
              width: current ? 2 : 1.5,
            ),
          ),
          child: image != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: image, fit: BoxFit.cover),
                    const Positioned(
                      top: 3,
                      right: 3,
                      child: SolaIcon(
                        SolaIcons.check,
                        size: 12,
                        color: SolaColors.surface,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: SolaText(
                    '$number',
                    style: SolaTextStyle.bodyStrong,
                    color: current ? SolaColors.sun : SolaColors.cameraText,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const new({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      key: const Key('camera_shutter'),
      identifier: 'camera_shutter',
      semanticsLabel: context.l10n.takePhoto,
      onTap: onTap,
      builder: (context, state) => Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: SolaColors.sun, width: 4),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap == null && !busy
                ? SolaColors.cameraGlass
                : state.pressed
                ? SolaColors.track
                : SolaColors.surface,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(SolaSpace.space20),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: SolaColors.ink,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
