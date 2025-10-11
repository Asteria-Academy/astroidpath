import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../components/double_stroke_text.dart';
import '../components/action_pill_button.dart';

class DrawPathScreenArgs {
  final bool openLoadPicker;

  const DrawPathScreenArgs({this.openLoadPicker = false});
}

enum DrawTool { pencil, erase, placeFinish }

class DrawPathScreen extends StatefulWidget {
  const DrawPathScreen({super.key, this.initialArgs});

  final DrawPathScreenArgs? initialArgs;

  @override
  State<DrawPathScreen> createState() => _DrawPathScreenState();
}

class _DrawPathScreenState extends State<DrawPathScreen> {
  final GlobalKey _boardKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _capturedImageBytes;
  String? _capturedImageName;

  double? _tableLengthCm;
  double? _tableWidthCm;
  int? _rows;
  int? _cols;

  double _robotSpeedPercent = 50;

  final Set<CellCoordinate> _paintedCells = <CellCoordinate>{};
  CellCoordinate? _startCell;
  CellCoordinate? _finishCell;
  CellCoordinate? _activeRobotCell;

  DrawTool _activeTool = DrawTool.pencil;

  Timer? _simulationTimer;
  List<CellCoordinate>? _simulationPath;
  int _simulationIndex = 0;
  final Set<CellCoordinate> _simulatedCells = <CellCoordinate>{};

  bool _orderedPathDirty = true;
  List<CellCoordinate>? _cachedOrderedPath;

  CellCoordinate? _lastInteractionCell;

  static const double _kToolRailCollapsedSize = 48;
  static const double _kToolRailMinWidth = 88;
  static const double _kToolRailMinHeight = 260;
  static const Color _kActionAccentColor = Color(0xFF4B3D8A);
  static const Duration _kActionPanelAnimDuration = Duration(milliseconds: 220);

  Offset? _toolRailOffset;
  bool _toolRailCollapsed = false;
  bool _actionButtonsExpanded = true;
  DateTime? _lastSnackTimestamp;
  String? _lastSnackMessage;

  bool get _hasImage => _capturedImageBytes != null;
  bool get _hasValidGrid =>
      _hasImage && _rows != null && _cols != null && _rows! > 0 && _cols! > 0;
  bool get _isSimulating => _simulationTimer != null;

  Offset _defaultToolRailOffset(Size boardSize) {
    return Offset(boardSize.width * 0.04, boardSize.height * 0.08);
  }

  Size _resolveToolRailSize({
    required bool collapsed,
    required Size boardSize,
    required double expandedWidth,
    required double expandedHeight,
  }) {
    final width = collapsed
        ? math.min(boardSize.width, _kToolRailCollapsedSize)
        : math.min(
            boardSize.width,
            math.max(_kToolRailMinWidth, expandedWidth),
          );
    final height = collapsed
        ? math.min(boardSize.height, _kToolRailCollapsedSize)
        : math.min(
            boardSize.height,
            math.max(_kToolRailMinHeight, expandedHeight),
          );
    return Size(width, height);
  }

  Offset _clampToolRailOffset(Offset candidate, Size boardSize, Size railSize) {
    final maxDx = math.max(0.0, boardSize.width - railSize.width);
    final maxDy = math.max(0.0, boardSize.height - railSize.height);
    return Offset(
      candidate.dx.clamp(0.0, maxDx),
      candidate.dy.clamp(0.0, maxDy),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialArgs?.openLoadPicker == true) {
        _openLoadPicker();
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0B1433),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/splash/bg.png', fit: BoxFit.cover),
          ),

          SafeArea(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.89,
                decoration: BoxDecoration(
                  color: const Color(0x4545EBD8).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF69C7C3), width: 2),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final h = c.maxHeight;

                    //spacing global
                    final sidePad = w * 0.03;
                    final topPad = 0.0;

                    // tinggi komponen tetap (sesuaikan dgn UI kamu)
                    final topBarH = h * 0.15; // tinggi judul MAP & DRAW PATH

                    // area board (frame ungu di screenshot)
                    final boardTop = topPad + topBarH + 8.0;
                    final boardLeft = sidePad;
                    final boardRight = sidePad;
                    final boardBottom = h * 0.05;

                    // ukuran tool rail mengambang
                    final boardWidth = w - (boardLeft + boardRight);
                    final boardHeight = h - (boardTop + boardBottom);
                    final toolRailW = boardWidth * 0.1;
                    final toolRailMaxH = h * 0.8; // jaga tidak overflow

                    return Stack(
                      children: [
                        Positioned(
                          left: sidePad,
                          right: sidePad,
                          top: topPad,
                          height: topBarH,
                          child: _buildTopBar(),
                        ),

                        Positioned(
                          left: boardLeft,
                          top: boardTop,
                          width: boardWidth,
                          height: boardHeight,
                          child: _buildBoardArea(),
                        ),

                        _buildFloatingToolRail(
                          boardOrigin: Offset(boardLeft, boardTop),
                          boardSize: Size(boardWidth, boardHeight),
                          expandedWidth: toolRailW,
                          expandedHeight: toolRailMaxH,
                        ),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _buildActionButtons(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildBackButton(),
          const SizedBox(width: 12),
          DoubleStrokeText(
            text: 'MAP & DRAW PATH',
            fontSize: math.min(MediaQuery.of(context).size.width * 0.03, 32.0),
            letterSpacing: 1.5,
            outerStrokeColor: const Color(0xFF0C2F66), // biru gelap
            innerStrokeColor: const Color(0xFF6EE7FF), // biru terang
            fillColor: const Color(0xFFF4FDFF), // putih lembut
            outerStrokeWidth: 4.0,
            innerStrokeWidth: 8.0,
          ),
          const SizedBox(
            width: 16,
          ), // Add spacing between the text and the container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7F54F9),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              'path length: ${_pathLengthMeters.toStringAsFixed(1)}m',
              style: GoogleFonts.titanOne(
                fontSize: MediaQuery.of(context).size.height * 0.025,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    final buttonSize = math.min(MediaQuery.of(context).size.width * 0.08, 35.0);
    debugPrint('Button size: $buttonSize');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleBackToMenu,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: const Color(0xFF7F54F9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingToolRail({
    required Offset boardOrigin,
    required Size boardSize,
    required double expandedWidth,
    required double expandedHeight,
  }) {
    final resolvedSize = _resolveToolRailSize(
      collapsed: _toolRailCollapsed,
      boardSize: boardSize,
      expandedWidth: expandedWidth,
      expandedHeight: expandedHeight,
    );
    final defaultOffset = _defaultToolRailOffset(boardSize);
    final clampedOffset = _clampToolRailOffset(
      _toolRailOffset ?? defaultOffset,
      boardSize,
      resolvedSize,
    );
    _toolRailOffset = clampedOffset;

    void adjustOffset(Offset delta) {
      if (delta == Offset.zero) return;
      setState(() {
        final size = _resolveToolRailSize(
          collapsed: _toolRailCollapsed,
          boardSize: boardSize,
          expandedWidth: expandedWidth,
          expandedHeight: expandedHeight,
        );
        final nextOffset = _clampToolRailOffset(
          (_toolRailOffset ?? defaultOffset) + delta,
          boardSize,
          size,
        );
        if (nextOffset != _toolRailOffset) {
          _toolRailOffset = nextOffset;
        }
      });
    }

    void toggleCollapsed() {
      setState(() {
        _toolRailCollapsed = !_toolRailCollapsed;
        final size = _resolveToolRailSize(
          collapsed: _toolRailCollapsed,
          boardSize: boardSize,
          expandedWidth: expandedWidth,
          expandedHeight: expandedHeight,
        );
        final nextOffset = _clampToolRailOffset(
          _toolRailOffset ?? defaultOffset,
          boardSize,
          size,
        );
        _toolRailOffset = nextOffset;
      });
    }

    return Positioned(
      left: boardOrigin.dx + clampedOffset.dx,
      top: boardOrigin.dy + clampedOffset.dy,
      child: SizedBox(
        width: resolvedSize.width,
        height: resolvedSize.height,
        child: _buildToolRail(
          collapsed: _toolRailCollapsed,
          onToggleCollapsed: toggleCollapsed,
          onDragUpdate: adjustOffset,
        ),
      ),
    );
  }

  Widget _buildToolRail({
    required bool collapsed,
    required VoidCallback onToggleCollapsed,
    required void Function(Offset delta) onDragUpdate,
  }) {
    if (collapsed) {
      return _buildCollapsedToolRail(
        onToggleCollapsed: onToggleCollapsed,
        onDragUpdate: onDragUpdate,
      );
    }
    return _buildExpandedToolRail(
      onToggleCollapsed: onToggleCollapsed,
      onDragUpdate: onDragUpdate,
    );
  }

  Widget _buildCollapsedToolRail({
    required VoidCallback onToggleCollapsed,
    required void Function(Offset delta) onDragUpdate,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleCollapsed,
      onPanUpdate: (details) {
        if (details.delta == Offset.zero) return;
        onDragUpdate(details.delta);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2F2F2).withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 9, 9, 9).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.visibility, color: Color(0xFF4B3D8A), size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedToolRail({
    required VoidCallback onToggleCollapsed,
    required void Function(Offset delta) onDragUpdate,
  }) {
    const handleColor = Color(0xFF4B3D8A);
    final shadowColor = const Color.fromARGB(255, 9, 9, 9).withOpacity(0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2F2F2).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              if (details.delta == Offset.zero) return;
              onDragUpdate(details.delta);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.drag_indicator_rounded,
                    color: handleColor,
                    size: 20,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggleCollapsed,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.visibility_off,
                        color: handleColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolRailButton(
                    icon: Icons.photo_camera_rounded,
                    onTap: _openCamera,
                  ),
                  _ToolRailButton(
                    icon: Icons.create_rounded,
                    highlight: _activeTool == DrawTool.pencil,
                    disabled: !_hasValidGrid,
                    onTap: () {
                      if (!_hasValidGrid) return;
                      setState(() => _activeTool = DrawTool.pencil);
                    },
                  ),
                  _ToolRailButton(
                    icon: Icons.flag_rounded,
                    highlight: _activeTool == DrawTool.placeFinish,
                    disabled: !_hasValidGrid || _paintedCells.isEmpty,
                    onTap: () {
                      if (!_hasValidGrid) return;
                      if (_paintedCells.isEmpty) {
                        _showSnack('Gambar jalur dulu sebelum menaruh finish.');
                        return;
                      }
                      setState(() {
                        _activeTool = _activeTool == DrawTool.placeFinish
                            ? DrawTool.pencil
                            : DrawTool.placeFinish;
                      });
                    },
                  ),
                  _ToolRailButton(
                    icon: Icons.crop_square_rounded,
                    highlight: _activeTool == DrawTool.erase,
                    disabled: !_hasValidGrid,
                    onTap: () {
                      if (!_hasValidGrid) return;
                      setState(() => _activeTool = DrawTool.erase);
                    },
                  ),
                  _ToolRailButton(
                    icon: Icons.settings,
                    onTap: _openSettingsDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    final idleStyle = GoogleFonts.titanOne(
      fontSize: 28,
      color: Colors.white,
      letterSpacing: 1.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final borderRadius = BorderRadius.circular(32);
        final minBoardHeight = math.min(320.0, constraints.maxHeight);
        final minBoardWidth = math.min(320.0, constraints.maxWidth);
        return Container(
          constraints: BoxConstraints(
            minHeight: minBoardHeight,
            minWidth: minBoardWidth,
          ),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A64), Color(0xFF102144)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color.fromARGB(255, 175, 116, 251),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF081021).withOpacity(0.45),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (context, boardConstraints) {
                final boardSize = Size(
                  boardConstraints.maxWidth,
                  boardConstraints.maxHeight,
                );
                return Container(
                  key: _boardKey,
                  color: Colors.black.withOpacity(0.12),
                  child: !_hasImage
                      ? Center(
                          child: Text(
                            'Klik Kamera Untuk Foto Area',
                            textAlign: TextAlign.center,
                            style: idleStyle,
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_capturedImageBytes != null)
                              Positioned.fill(
                                child: Image.memory(
                                  _capturedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.18),
                              ),
                            ),
                            if (_hasValidGrid)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onDoubleTapDown: (details) =>
                                      _handleFinishDoubleTap(
                                        details.localPosition,
                                        boardSize,
                                      ),
                                  onTapDown: (details) => _handleBoardInput(
                                    details.localPosition,
                                    boardSize,
                                    isDrag: false,
                                  ),
                                  onPanStart:
                                      _activeTool == DrawTool.placeFinish
                                      ? null
                                      : (details) => _handleBoardInput(
                                          details.localPosition,
                                          boardSize,
                                          isDrag: true,
                                        ),
                                  onPanUpdate:
                                      _activeTool == DrawTool.placeFinish
                                      ? null
                                      : (details) => _handleBoardInput(
                                          details.localPosition,
                                          boardSize,
                                          isDrag: true,
                                        ),
                                  onPanEnd: (_) => _lastInteractionCell = null,
                                  onTapUp: (_) => _lastInteractionCell = null,
                                  onTapCancel: () =>
                                      _lastInteractionCell = null,
                                  child: CustomPaint(
                                    painter: _BoardPainter(
                                      rows: _rows!,
                                      cols: _cols!,
                                      paintedCells: _paintedCells,
                                      simulatedCells: _simulatedCells,
                                      segments: _buildDirectionalSegments(),
                                    ),
                                  ),
                                ),
                              ),
                            if (_hasValidGrid && _displayStartCell != null)
                              _buildMarker(
                                cell: _displayStartCell!,
                                boardSize: boardSize,
                                assetPath: 'assets/path/maps.png',
                                onDrag: (global) => _handleMarkerDrag(
                                  global,
                                  boardSize,
                                  MarkerType.start,
                                ),
                              ),
                            if (_hasValidGrid && _finishCell != null)
                              _buildMarker(
                                cell: _finishCell!,
                                boardSize: boardSize,
                                assetPath: 'assets/path/finish.png',
                                onDrag: (global) => _handleMarkerDrag(
                                  global,
                                  boardSize,
                                  MarkerType.finish,
                                ),
                              ),
                          ],
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _toggleActionButtons() {
    setState(() {
      _actionButtonsExpanded = !_actionButtonsExpanded;
    });
  }

  void _handleBackToMenu() {
    Navigator.of(context).maybePop();
  }

  void _handleRunPathTap() {
    _showSnack('Hubungkan robot terlebih dahulu.');
  }

  Widget _buildActionButtons() {
    final simulateDisabled = !_canSimulate;
    final saveDisabled = !_canSave;
    final hasUnsavedChanges = _orderedPathDirty;
    final showButtons = _actionButtonsExpanded;
    final panelPadding = showButtons
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : const EdgeInsets.all(12);

    return AnimatedSize(
      duration: _kActionPanelAnimDuration,
      curve: Curves.easeInOut,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: panelPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionPanelToggle(),
            if (showButtons) ...[
              const SizedBox(width: 12),
              ActionPillButton(
                label: 'RUN PATH',
                icon: Icons.play_arrow_rounded,
                fontSize: 16,
                onTap: _handleRunPathTap,
                primaryColor: _kActionAccentColor,
                isActive: false,
              ),
              const SizedBox(width: 12),
              ActionPillButton(
                label: 'LOAD',
                icon: Icons.folder_open_rounded,
                fontSize: 16,
                onTap: _openLoadPicker,
                primaryColor: _kActionAccentColor,
                isActive: false,
              ),
              const SizedBox(width: 12),
              ActionPillButton(
                label: _isSimulating ? 'STOP' : 'SIMULATE',
                icon: _isSimulating
                    ? Icons.stop_rounded
                    : Icons.play_circle_fill,
                fontSize: 16,
                onTap: _isSimulating
                    ? _stopSimulation
                    : (simulateDisabled ? null : _startSimulation),
                primaryColor: _kActionAccentColor,
                isActive: _isSimulating,
              ),
              const SizedBox(width: 12),
              ActionPillButton(
                label: 'SAVE',
                icon: Icons.save_rounded,
                fontSize: 16,
                onTap: saveDisabled ? null : _saveCurrentPath,
                primaryColor: _kActionAccentColor,
                isActive: !saveDisabled && hasUnsavedChanges,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanelToggle() {
    return Material(
      color: _kActionAccentColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _toggleActionButtons,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedSwitcher(
            duration: _kActionPanelAnimDuration,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Icon(
              _actionButtonsExpanded ? Icons.chevron_right : Icons.chevron_left,
              key: ValueKey<bool>(_actionButtonsExpanded),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  CellCoordinate? get _displayStartCell => _activeRobotCell ?? _startCell;

  bool get _canSimulate => _getValidPath() != null && !_isSimulating;

  bool get _canSave => _getValidPath() != null && !_isSimulating;

  void _handleBoardInput(
    Offset localPosition,
    Size boardSize, {
    bool isDrag = false,
  }) {
    if (!_hasValidGrid) return;
    final cell = _positionToCell(localPosition, boardSize);
    if (cell == null) return;
    if (cell == _lastInteractionCell) return;
    _lastInteractionCell = cell;
    switch (_activeTool) {
      case DrawTool.pencil:
        _paintCell(cell);
        break;
      case DrawTool.erase:
        _eraseCell(cell);
        break;
      case DrawTool.placeFinish:
        if (isDrag) return;
        _attemptPlaceFinish(
          cell,
          deactivateToolAfterPlacement: true,
          showInvalidSnack: true,
        );
        break;
    }
  }

  void _handleFinishDoubleTap(Offset localPosition, Size boardSize) {
    if (!_hasValidGrid) return;
    final cell = _positionToCell(localPosition, boardSize);
    if (cell == null) return;
    final placed = _attemptPlaceFinish(
      cell,
      deactivateToolAfterPlacement: false,
      showInvalidSnack: true,
    );
    if (placed) {
      _lastInteractionCell = null;
    }
  }

  Widget _buildMarker({
    required CellCoordinate cell,
    required Size boardSize,
    required String assetPath,
    required void Function(Offset globalPosition) onDrag,
  }) {
    final cellSize = _cellSizeForBoard(boardSize);
    if (cellSize == null) return const SizedBox.shrink();

    final left = cell.col * cellSize.width;
    final top = cell.row * cellSize.height;

    return Positioned(
      left: left,
      top: top,
      width: cellSize.width,
      height: cellSize.height,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.globalPosition),
        child: Center(
          child: Image.asset(assetPath, width: cellSize.width * 0.9),
        ),
      ),
    );
  }

  Size? _cellSizeForBoard(Size boardSize) {
    if (!_hasValidGrid) return null;
    return Size(boardSize.width / _cols!, boardSize.height / _rows!);
  }

  void _handleMarkerDrag(
    Offset globalPosition,
    Size boardSize,
    MarkerType type,
  ) {
    final renderBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final local = renderBox.globalToLocal(globalPosition);
    final cell = _positionToCell(local, boardSize);
    if (cell == null) return;

    if (_paintedCells.isEmpty) {
      final added = _paintCell(cell, allowIsolated: true);
      if (!added) return;
    } else if (!_paintedCells.contains(cell)) {
      _showSnack('Letakkan ikon di jalur yang sudah digambar.');
      return;
    }

    setState(() {
      if (type == MarkerType.start) {
        _startCell = cell;
        _activeRobotCell = cell;
      } else {
        _finishCell = cell;
      }
      _markPathDirty();
    });
  }

  CellCoordinate? _positionToCell(Offset position, Size boardSize) {
    if (!_hasValidGrid) return null;
    final dx = position.dx;
    final dy = position.dy;
    if (dx < 0 || dy < 0 || dx >= boardSize.width || dy >= boardSize.height) {
      return null;
    }
    final col = (dx / (boardSize.width / _cols!)).floor();
    final row = (dy / (boardSize.height / _rows!)).floor();
    final cell = CellCoordinate(row, col);
    return _isInside(cell) ? cell : null;
  }

  bool _paintCell(CellCoordinate cell, {bool allowIsolated = false}) {
    if (!_isInside(cell)) return false;
    if (_paintedCells.contains(cell)) return false;
    if (_isSimulating) {
      _stopSimulation();
    }
    final neighbors = _validNeighbors(
      cell,
    ).where(_paintedCells.contains).toList();
    if (!allowIsolated && _paintedCells.isNotEmpty && neighbors.isEmpty) {
      _showSnack('Hubungkan jalur ke sel yang sudah dibuat.');
      return false;
    }
    for (final neighbor in neighbors) {
      if (_degree(neighbor) >= 2) {
        _showSnack('Jalur hanya boleh selebar satu kotak.');
        return false;
      }
    }
    if (neighbors.length > 2) {
      _showSnack('Jalur hanya boleh selebar satu kotak.');
      return false;
    }
    setState(() {
      _paintedCells.add(cell);
      if (_startCell == null) {
        _startCell = cell;
        _activeRobotCell = cell;
      }
      final shouldAutoAssignFinish =
          _finishCell == null || !_paintedCells.contains(_finishCell!);
      if (shouldAutoAssignFinish) {
        _finishCell = cell;
      }
      _markPathDirty();
    });
    return true;
  }

  void _eraseCell(CellCoordinate cell) {
    if (!_paintedCells.contains(cell)) return;
    if (_isSimulating) {
      _stopSimulation();
    }
    setState(() {
      _paintedCells.remove(cell);
      if (_startCell == cell) {
        _startCell = null;
        _activeRobotCell = null;
      }
      if (_finishCell == cell) {
        _finishCell = null;
      }
      _simulatedCells.clear();
      _markPathDirty();
    });
  }

  bool _attemptPlaceFinish(
    CellCoordinate cell, {
    required bool deactivateToolAfterPlacement,
    required bool showInvalidSnack,
  }) {
    if (!_paintedCells.contains(cell)) {
      if (showInvalidSnack) {
        _showSnack('Letakkan finish di jalur yang sudah digambar.');
      }
      return false;
    }
    final alreadyPlaced = _finishCell == cell;
    final shouldDeactivate =
        deactivateToolAfterPlacement && _activeTool == DrawTool.placeFinish;
    final wasSimulating = _isSimulating;
    if (wasSimulating) {
      _stopSimulation();
    }
    if (alreadyPlaced && !shouldDeactivate) {
      return true;
    }
    setState(() {
      if (!alreadyPlaced) {
        _finishCell = cell;
        if (!wasSimulating) {
          _simulatedCells.clear();
          _activeRobotCell = _startCell;
        }
        _markPathDirty();
      }
      if (shouldDeactivate) {
        _activeTool = DrawTool.pencil;
      }
    });
    return true;
  }

  Iterable<CellCoordinate> _validNeighbors(CellCoordinate cell) sync* {
    yield* cell.neighbors.where(_isInside);
  }

  bool _isInside(CellCoordinate cell) {
    if (!_hasValidGrid) return false;
    return cell.row >= 0 &&
        cell.row < _rows! &&
        cell.col >= 0 &&
        cell.col < _cols!;
  }

  int _degree(CellCoordinate cell) {
    return _validNeighbors(cell).where(_paintedCells.contains).length;
  }

  void _markPathDirty() {
    _orderedPathDirty = true;
  }

  List<CellCoordinate>? _computeOrderedPath() {
    if (!_hasValidGrid || _paintedCells.isEmpty) return null;
    if (_orderedPathDirty || _cachedOrderedPath == null) {
      _cachedOrderedPath = _calculateOrderedPath();
      _orderedPathDirty = false;
    }
    return _cachedOrderedPath;
  }

  List<CellCoordinate>? _calculateOrderedPath() {
    final start = _startCell;
    final finish = _finishCell;
    if (start == null || finish == null) {
      return null;
    }
    if (!_paintedCells.contains(start) || !_paintedCells.contains(finish)) {
      return null;
    }

    final Map<CellCoordinate, List<CellCoordinate>> adjacency = {};
    for (final cell in _paintedCells) {
      final neighbors = _validNeighbors(
        cell,
      ).where(_paintedCells.contains).toList();
      if (neighbors.length > 2) {
        return null;
      }
      adjacency[cell] = neighbors;
    }

    final visited = <CellCoordinate>{};
    final path = <CellCoordinate>[];
    var current = start;
    CellCoordinate? previous;

    while (true) {
      path.add(current);
      visited.add(current);
      if (current == finish) {
        break;
      }
      final neighbors = adjacency[current]!;
      final nextOptions = neighbors.where((c) => c != previous).toList();
      if (nextOptions.isEmpty) {
        return null;
      }
      final next = nextOptions.firstWhere(
        (candidate) => !visited.contains(candidate) || candidate == finish,
        orElse: () => nextOptions.first,
      );
      previous = current;
      current = next;
      if (path.length > _paintedCells.length + 2) {
        return null;
      }
    }

    if (visited.length != _paintedCells.length) {
      return null;
    }

    return path;
  }

  List<CellCoordinate>? _getValidPath() {
    final ordered = _computeOrderedPath();
    if (ordered == null) return null;
    if (ordered.length < 2) return null;
    return ordered;
  }

  List<DirectedSegment> _buildDirectionalSegments() {
    final ordered = _computeOrderedPath();
    if (ordered == null || ordered.length < 2) {
      return const <DirectedSegment>[];
    }
    final segments = <DirectedSegment>[];
    for (var i = 0; i < ordered.length - 1; i++) {
      final from = ordered[i];
      final to = ordered[i + 1];
      final direction = _directionBetween(from, to);
      final isHighlighted =
          _simulatedCells.contains(to) || _activeRobotCell == to;
      segments.add(
        DirectedSegment(
          from: from,
          to: to,
          direction: direction,
          isHighlighted: isHighlighted,
        ),
      );
    }
    return segments;
  }

  CellDirection _directionBetween(CellCoordinate from, CellCoordinate to) {
    if (to.row < from.row) return CellDirection.north;
    if (to.row > from.row) return CellDirection.south;
    if (to.col > from.col) return CellDirection.east;
    return CellDirection.west;
  }

  double get _pathLengthMeters {
    final ordered = _computeOrderedPath();
    if (ordered == null || ordered.length < 2) return 0;
    final steps = ordered.length - 1;
    return steps * 0.05;
  }

  double get _cellsPerSecond => math.max(0.2, 0.2 + 0.018 * _robotSpeedPercent);

  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CameraCapturePage(picker: _picker),
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _capturedImageBytes = result;
      _capturedImageName =
          'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _clearPath();
    });
  }

  void _clearPath() {
    _paintedCells.clear();
    _startCell = null;
    _finishCell = null;
    _activeRobotCell = null;
    _simulatedCells.clear();
    _simulationPath = null;
    _simulationIndex = 0;
    _markPathDirty();
  }

  Future<void> _openSettingsDialog() async {
    final result = await showDialog<_SettingsResult>(
      context: context,
      builder: (context) => _SettingsDialog(
        initialLength: _tableLengthCm,
        initialWidth: _tableWidthCm,
        initialSpeed: _robotSpeedPercent,
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    if (result.lengthCm < 5 || result.widthCm < 5) {
      _showSnack('Minimum ukuran meja 5cm x 5cm.');
      return;
    }

    final newRows = (result.lengthCm / 5).floor();
    final newCols = (result.widthCm / 5).floor();
    if (newRows <= 0 || newCols <= 0) {
      _showSnack('Ukuran grid tidak valid.');
      return;
    }

    final gridChanged =
        newRows != _rows ||
        newCols != _cols ||
        _tableLengthCm != result.lengthCm ||
        _tableWidthCm != result.widthCm;

    if (gridChanged && _paintedCells.isNotEmpty) {
      final confirm =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hapus Jalur?'),
              content: const Text(
                'Mengubah ukuran meja akan menghapus jalur yang sudah digambar. Lanjutkan?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('BATAL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('LANJUTKAN'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirm) return;
    }

    if (!mounted) return;
    setState(() {
      _tableLengthCm = result.lengthCm;
      _tableWidthCm = result.widthCm;
      _rows = newRows;
      _cols = newCols;
      _robotSpeedPercent = result.robotSpeed;
      if (gridChanged) {
        _clearPath();
      }
    });
  }

  void _startSimulation() {
    final path = _getValidPath();
    if (path == null) {
      _showSnack('Lengkapi jalur dari start ke finish terlebih dahulu.');
      return;
    }
    if (_startCell == null || _finishCell == null) {
      _showSnack('Posisi start dan finish belum diatur.');
      return;
    }

    setState(() {
      _simulationPath = path;
      _simulationIndex = 1;
      _simulatedCells
        ..clear()
        ..add(path.first);
      _activeRobotCell = path.first;
    });

    final stepDuration = Duration(
      milliseconds: (1000 / _cellsPerSecond).round().clamp(80, 2000),
    );

    _simulationTimer = Timer.periodic(stepDuration, (timer) {
      if (_simulationPath == null) {
        timer.cancel();
        return;
      }
      if (_simulationIndex >= _simulationPath!.length) {
        _stopSimulation();
        return;
      }
      final nextCell = _simulationPath![_simulationIndex];
      setState(() {
        _activeRobotCell = nextCell;
        _simulatedCells.add(nextCell);
        _simulationIndex += 1;
      });
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    setState(() {
      _simulationPath = null;
      _simulationIndex = 0;
      _simulatedCells.clear();
      _activeRobotCell = _startCell;
    });
  }

  Future<void> _saveCurrentPath() async {
    final path = _getValidPath();
    if (path == null) {
      _showSnack('Jalur belum valid untuk disimpan.');
      return;
    }
    if (!_hasValidGrid || !_hasImage) {
      _showSnack('Pastikan foto dan pengaturan sudah lengkap.');
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'path_${DateTime.now().millisecondsSinceEpoch}.astpath';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      final payload = {
        'version': 1,
        'image_base64': base64Encode(_capturedImageBytes!),
        'image_name': _capturedImageName,
        'settings': {
          'length_cm': _tableLengthCm,
          'width_cm': _tableWidthCm,
          'robot_speed_percent': _robotSpeedPercent,
          'rows': _rows,
          'cols': _cols,
        },
        'path': path
            .map((cell) => {'row': cell.row, 'col': cell.col})
            .toList(growable: false),
        'start': {'row': _startCell?.row, 'col': _startCell?.col},
        'finish': {'row': _finishCell?.row, 'col': _finishCell?.col},
      };
      await file.writeAsString(jsonEncode(payload));
      if (mounted) {
        _showSnack('File tersimpan: $fileName');
      }
    } on Exception catch (e) {
      _showSnack('Gagal menyimpan file: $e');
    }
  }

  Future<void> _openLoadPicker() async {
    if (_hasImage && _paintedCells.isNotEmpty) {
      final proceed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Muat Jalur?'),
              content: const Text(
                'Membuka file baru akan menimpa jalur yang sedang aktif. Lanjutkan?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('BATAL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('MUAT'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (!proceed) return;
    }
    await _showLoadSheet();
  }

  Future<void> _showLoadSheet() async {
    final directory = await getApplicationDocumentsDirectory();
    if (!mounted) return;
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.astpath'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    if (files.isEmpty) {
      if (!mounted) return;
      _showSnack('Belum ada file tersimpan.');
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF13274A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final name = file.uri.pathSegments.last;
            return ListTile(
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                'Terakhir: ${file.lastModifiedSync()}',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              onTap: () => Navigator.pop(context, file.path),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (selected == null) return;
    await _loadFromFile(File(selected));
  }

  Future<void> _loadFromFile(File file) async {
    try {
      final text = await file.readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      final imageBase64 = json['image_base64'] as String?;
      final settings = json['settings'] as Map<String, dynamic>?;
      final pathJson = json['path'] as List<dynamic>?;
      if (imageBase64 == null || settings == null || pathJson == null) {
        throw const FormatException('File tidak lengkap.');
      }

      final rows = (settings['rows'] as num?)?.toInt();
      final cols = (settings['cols'] as num?)?.toInt();
      final length = (settings['length_cm'] as num?)?.toDouble();
      final width = (settings['width_cm'] as num?)?.toDouble();
      final speed = (settings['robot_speed_percent'] as num?)?.toDouble();
      if (rows == null || cols == null || length == null || width == null) {
        throw const FormatException('Pengaturan tidak valid.');
      }

      final cells = pathJson
          .map(
            (e) => CellCoordinate(
              (e['row'] as num).toInt(),
              (e['col'] as num).toInt(),
            ),
          )
          .where(
            (cell) =>
                cell.row >= 0 &&
                cell.col >= 0 &&
                cell.row < rows &&
                cell.col < cols,
          )
          .toList();
      if (cells.isEmpty) {
        throw const FormatException('Data jalur kosong.');
      }

      final startJson = json['start'] as Map<String, dynamic>?;
      final finishJson = json['finish'] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        _capturedImageBytes = base64Decode(imageBase64);
        _capturedImageName = json['image_name'] as String?;
        _tableLengthCm = length;
        _tableWidthCm = width;
        _rows = rows;
        _cols = cols;
        _robotSpeedPercent = speed ?? _robotSpeedPercent;
        _paintedCells
          ..clear()
          ..addAll(cells);
        _startCell = startJson == null
            ? cells.first
            : CellCoordinate(
                (startJson['row'] as num).toInt(),
                (startJson['col'] as num).toInt(),
              );
        _finishCell = finishJson == null
            ? cells.last
            : CellCoordinate(
                (finishJson['row'] as num).toInt(),
                (finishJson['col'] as num).toInt(),
              );
        _activeRobotCell = _startCell;
        _simulatedCells.clear();
        _simulationPath = null;
        _simulationIndex = 0;
        _markPathDirty();
      });
      _showSnack('File berhasil dimuat: ${file.uri.pathSegments.last}');
    } on FormatException catch (e) {
      _showSnack('File rusak: ${e.message}');
    } on Exception catch (e) {
      _showSnack('Gagal membuka file: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastSnackMessage == message &&
        _lastSnackTimestamp != null &&
        now.difference(_lastSnackTimestamp!) <
            const Duration(milliseconds: 900)) {
      return;
    }
    _lastSnackMessage = message;
    _lastSnackTimestamp = now;

    final messenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final desiredWidth = math.min(
      screenWidth - 32.0,
      math.max(220.0, message.length * 6.5 + 96),
    );
    final horizontalInset = math.max(16.0, (screenWidth - desiredWidth) / 2);
    final snackMargin = EdgeInsets.fromLTRB(
      horizontalInset,
      0,
      horizontalInset,
      24,
    );

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
            GestureDetector(
              onTap: messenger.hideCurrentSnackBar,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        backgroundColor: const Color(0xFF1B2A4A).withOpacity(0.94),
        duration: const Duration(seconds: 2),
        margin: snackMargin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class CellCoordinate {
  final int row;
  final int col;

  const CellCoordinate(this.row, this.col);

  List<CellCoordinate> get neighbors => [
    CellCoordinate(row - 1, col),
    CellCoordinate(row + 1, col),
    CellCoordinate(row, col - 1),
    CellCoordinate(row, col + 1),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellCoordinate && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'CellCoordinate(row: $row, col: $col)';
}

enum MarkerType { start, finish }

enum CellDirection { north, east, south, west }

class DirectedSegment {
  DirectedSegment({
    required this.from,
    required this.to,
    required this.direction,
    required this.isHighlighted,
  });

  final CellCoordinate from;
  final CellCoordinate to;
  final CellDirection direction;
  final bool isHighlighted;
}

class _ToolRailButton extends StatelessWidget {
  const _ToolRailButton({
    required this.icon,
    this.highlight = false,
    this.disabled = false,
    this.onTap,
  });

  final IconData icon;
  final bool highlight;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final shortestSide = math.min(mediaSize.width, mediaSize.height);
    final iconSize = shortestSide * 0.035;
    final verticalPadding = shortestSide * 0.012;
    final horizontalPadding = shortestSide * 0.008;
    final borderRadiusValue = shortestSide * 0.03;

    final clampedIconSize = iconSize.clamp(20.0, 28.0);
    final clampedVerticalPadding = verticalPadding.clamp(6.0, 12.0);
    final clampedHorizontalPadding = horizontalPadding.clamp(6.0, 12.0);
    final clampedBorderRadius = borderRadiusValue.clamp(14.0, 20.0);

    final enabledColor = highlight
        ? const Color.fromARGB(255, 68, 130, 255)
        : Colors.white;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.005,
        ),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            vertical: clampedVerticalPadding,
            horizontal: clampedHorizontalPadding,
          ),
          decoration: BoxDecoration(
            gradient: highlight
                ? const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 166, 98, 255),
                      Color.fromARGB(255, 99, 211, 231),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: highlight ? null : const Color(0xFF800080),
            borderRadius: BorderRadius.circular(clampedBorderRadius),
            border: Border.all(
              color: highlight ? const Color(0xFFB5FEFF) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: disabled ? Colors.white54 : enabledColor,
            size: clampedIconSize,
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.rows,
    required this.cols,
    required this.paintedCells,
    required this.simulatedCells,
    required this.segments,
  });

  final int rows;
  final int cols;
  final Set<CellCoordinate> paintedCells;
  final Set<CellCoordinate> simulatedCells;
  final List<DirectedSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final gridPaint = Paint()
      ..color = const Color(0xFFB5F6FF).withOpacity(0.28)
      ..strokeWidth = 1;

    final pathPaint = Paint()
      ..color = const Color(0xFF83F8C5).withOpacity(0.75);

    final simulatedPaint = Paint()
      ..color = const Color(0xFF4CD4FF).withOpacity(0.5);

    for (final cell in paintedCells) {
      final rect = Rect.fromLTWH(
        cell.col * cellWidth,
        cell.row * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect, pathPaint);
    }

    for (final cell in simulatedCells) {
      final rect = Rect.fromLTWH(
        cell.col * cellWidth,
        cell.row * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect, simulatedPaint);
    }

    if (segments.isNotEmpty) {
      // Draw direction arrows between ordered cells (default + simulated styles).
      final minExtent = math.min(cellWidth, cellHeight);
      final baseStroke = math.max(1.8, minExtent * 0.14);
      final highlightStroke = math.min(minExtent * 0.26, baseStroke * 1.4);
      final arrowPadding = minExtent * 0.18;
      final maxHeadLength = minExtent * 0.32;
      final baseColor = const Color(0xFF4FA9FF);
      final highlightColor = const Color(0xFFFFC960);

      for (final segment in segments) {
        final color = segment.isHighlighted ? highlightColor : baseColor;
        final strokeWidth = segment.isHighlighted
            ? highlightStroke
            : baseStroke;
        final startCenter = Offset(
          (segment.from.col + 0.5) * cellWidth,
          (segment.from.row + 0.5) * cellHeight,
        );
        final endCenter = Offset(
          (segment.to.col + 0.5) * cellWidth,
          (segment.to.row + 0.5) * cellHeight,
        );
        final delta = endCenter - startCenter;
        final distance = delta.distance;
        if (distance == 0) {
          continue;
        }
        final unit = delta / distance;
        final start = startCenter + unit * arrowPadding;
        final end = endCenter - unit * arrowPadding;
        final drawableDelta = end - start;
        final drawableLength = drawableDelta.distance;
        if (drawableLength <= 0) {
          continue;
        }
        final tip = start + unit * drawableLength;
        final headLength = math.min(maxHeadLength, drawableLength * 0.6);
        final headBase = tip - unit * headLength;
        final perp = Offset(-unit.dy, unit.dx);
        final headWidth = headLength * 0.7;
        final halfWidthVector = perp * (headWidth / 2);

        final shaftPaint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final headPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawLine(start, headBase, shaftPaint);

        final headPath = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            headBase.dx + halfWidthVector.dx,
            headBase.dy + halfWidthVector.dy,
          )
          ..lineTo(
            headBase.dx - halfWidthVector.dx,
            headBase.dy - halfWidthVector.dy,
          )
          ..close();
        canvas.drawPath(headPath, headPaint);
      }
    }

    for (int r = 0; r <= rows; r++) {
      final dy = r * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      final dx = c * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.paintedCells != paintedCells ||
        oldDelegate.simulatedCells != simulatedCells ||
        oldDelegate.segments != segments ||
        oldDelegate.rows != rows ||
        oldDelegate.cols != cols;
  }
}

class _CameraCapturePage extends StatefulWidget {
  const _CameraCapturePage({required this.picker});

  final ImagePicker picker;

  @override
  State<_CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<_CameraCapturePage> {
  Uint8List? _previewBytes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091326),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ambil Foto Area',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF12264A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6FE2FF).withOpacity(0.8),
                ),
              ),
              child: Text(
                'Ambil foto dari tampak atas (top-down) agar skala akurat.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: _previewBytes == null
                      ? const Center(
                          child: Text(
                            'Belum ada foto',
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      : Image.memory(_previewBytes!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _captureImage,
                    icon: const Icon(Icons.photo_camera, size: 20),
                    label: const Text('Ambil Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A4CF3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(0, 48),
                      textStyle: GoogleFonts.titanOne(fontSize: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                if (_previewBytes != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop(_previewBytes);
                            },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Gunakan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(0, 48),
                        textStyle: GoogleFonts.titanOne(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final file = await widget.picker.pickImage(source: ImageSource.camera);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _previewBytes = bytes;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kamera: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _SettingsResult {
  final double lengthCm;
  final double widthCm;
  final double robotSpeed;

  const _SettingsResult({
    required this.lengthCm,
    required this.widthCm,
    required this.robotSpeed,
  });
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    this.initialLength,
    this.initialWidth,
    required this.initialSpeed,
  });

  final double? initialLength;
  final double? initialWidth;
  final double initialSpeed;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late double _speed;
  late double _areaLength;
  late double _areaWidth;

  double _normalizeDimension(double? value) {
    final raw = value ?? 40.0;
    final clamped = raw.clamp(5.0, 500.0).toDouble();
    final steps = (clamped / 5.0).round();
    return (steps * 5).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
    _areaLength = _normalizeDimension(widget.initialLength);
    _areaWidth = _normalizeDimension(widget.initialWidth);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final cardWidth = math.min(380.0, media.size.width * 0.78);
    final availableHeight = media.size.height - 120;
    const minCardHeight = 340.0;
    const maxCardHeight = 440.0;

    double cardHeight = math.min(
      maxCardHeight,
      math.max(minCardHeight, availableHeight),
    );
    final buttonSize = 70.0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardWidth + buttonSize + 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F35F5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFB5C4FF),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF090B27).withOpacity(0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: cardHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),

                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: c.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                // KUNCI: spaceBetween biar slider “nempel” bawah tanpa Expanded
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // ====== TOP GROUP: title + fields ======
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'PENGATURAN AREA',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.titanOne(
                                          color: Colors.white,
                                          fontSize: 24,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildStepperField(
                                        label: 'Area Length',
                                        value: _areaLength,
                                        onChanged: (val) => setState(
                                          () => _areaLength =
                                              _normalizeDimension(val),
                                        ),
                                        step: 5.0, // increment 5cm
                                        max: 500,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildStepperField(
                                        label: 'Area Width',
                                        value: _areaWidth,
                                        onChanged: (val) => setState(
                                          () => _areaWidth =
                                              _normalizeDimension(val),
                                        ),
                                        step: 5.0,
                                        max: 500,
                                      ),
                                    ],
                                  ),

                                  // ====== BOTTOM GROUP: slider speed ======
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 18),
                                      Text(
                                        'ROBOT SPEED (0% - 100%) : ${_speed.toStringAsFixed(0)}%',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 8,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 12,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 18,
                                              ),
                                          activeTrackColor: const Color(
                                            0xFFE4B9FF,
                                          ),
                                          inactiveTrackColor: Colors.white
                                              .withOpacity(0.24),
                                          thumbColor: const Color(0xFFF7EDFF),
                                          showValueIndicator:
                                              ShowValueIndicator.onDrag,
                                          valueIndicatorColor: const Color(
                                            0xFF7B4BF2,
                                          ),
                                          valueIndicatorTextStyle:
                                              GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                        ),
                                        child: Slider(
                                          value: _speed,
                                          min: 0,
                                          max: 100,
                                          divisions: 100,
                                          label:
                                              '${_speed.toStringAsFixed(0)}%',
                                          onChanged: (value) {
                                            setState(() => _speed = value);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  height: cardHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _floatingDialogButton(
                        icon: Icons.check_rounded,
                        accentColor: const Color(0xFF7038F9),
                        onTap: _onSave,
                        size: buttonSize,
                      ),
                      const SizedBox(height: 16),
                      _floatingDialogButton(
                        icon: Icons.close_rounded,
                        accentColor: const Color(0xFFFF7A1A),
                        onTap: () => Navigator.pop(context),
                        size: buttonSize,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required double value,
    required Function(double) onChanged,
    double step = 1.0,
    double min = 5,
    double max = 1000,
  }) {
    var currentValue = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Tombol Minus
              _stepperButton(
                icon: Icons.remove,
                onStep: () {
                  if (currentValue <= min) return false;
                  final next = math.max(min, currentValue - step);
                  if (next == currentValue) return false;
                  currentValue = next;
                  onChanged(next);
                  return true;
                },
              ),
              // Display Value
              Expanded(
                child: Text(
                  '${value.toStringAsFixed(0)} cm',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Tombol Plus
              _stepperButton(
                icon: Icons.add,
                onStep: () {
                  if (currentValue >= max) return false;
                  final next = math.min(max, currentValue + step);
                  if (next == currentValue) return false;
                  currentValue = next;
                  onChanged(next);
                  return true;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool Function() onStep,
  }) {
    return _HoldStepperButton(icon: icon, onStep: onStep);
  }

  Widget _floatingDialogButton({
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required double size,
  }) {
    final radius = BorderRadius.circular(size * 0.5);
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: accentColor.withOpacity(0.35),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: size * 0.36),
            ),
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (_areaLength <= 0 || _areaWidth <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ukuran meja tidak valid.')));
      return;
    }
    Navigator.pop(
      context,
      _SettingsResult(
        lengthCm: _areaLength,
        widthCm: _areaWidth,
        robotSpeed: _speed,
      ),
    );
  }
}

class _HoldStepperButton extends StatefulWidget {
  const _HoldStepperButton({required this.icon, required this.onStep});

  final IconData icon;
  final bool Function() onStep;

  @override
  State<_HoldStepperButton> createState() => _HoldStepperButtonState();
}

class _HoldStepperButtonState extends State<_HoldStepperButton> {
  static const Duration _holdActivationDelay = Duration(milliseconds: 300);
  static const Duration _initialRepeatDelay = Duration(milliseconds: 220);
  static const Duration _minRepeatDelay = Duration(milliseconds: 60);
  static const double _accelerationFactor = 0.82;

  Timer? _holdTimer;
  Timer? _repeatTimer;
  bool _didTriggerAutoStep = false;
  Duration _currentDelay = _initialRepeatDelay;

  void _handlePointerDown(PointerDownEvent event) {
    _startHoldCountdown();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _handlePointerEnd(canceled: false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _handlePointerEnd(canceled: true);
  }

  void _startHoldCountdown() {
    _cancelAllTimers();
    _didTriggerAutoStep = false;
    _holdTimer = Timer(_holdActivationDelay, () {
      if (!mounted) return;
      _didTriggerAutoStep = true;
      if (_performStep()) {
        _currentDelay = _initialRepeatDelay;
        _scheduleNextStep();
      }
    });
  }

  void _scheduleNextStep() {
    _repeatTimer = Timer(_currentDelay, () {
      if (!mounted) return;
      if (!_performStep()) return;
      final nextDelayMs = math.max(
        _minRepeatDelay.inMilliseconds,
        (_currentDelay.inMilliseconds * _accelerationFactor).round(),
      );
      _currentDelay = Duration(milliseconds: nextDelayMs);
      _scheduleNextStep();
    });
  }

  bool _performStep() {
    final applied = widget.onStep();
    if (!applied) {
      _cancelAllTimers();
    }
    return applied;
  }

  void _handlePointerEnd({required bool canceled}) {
    final triggeredHold = _didTriggerAutoStep;
    _cancelAllTimers();
    _didTriggerAutoStep = false;
    if (!canceled && !triggeredHold) {
      widget.onStep();
    }
  }

  void _cancelAllTimers() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    _holdTimer = null;
    _repeatTimer = null;
    _currentDelay = _initialRepeatDelay;
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: InkWell(
        onTap: () {},
        onTapCancel: () => _handlePointerEnd(canceled: true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF7038F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
