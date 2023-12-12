import 'dart:ui';

class Patch {
  const Patch({
    required this.gridPosition,
    required this.patchLeft,
    required this.patchRight,
    required this.patchTop,
    required this.patchBottom,
  });

  const Patch.all({
    required this.gridPosition,
  })  : patchLeft = true,
        patchRight = true,
        patchTop = true,
        patchBottom = true;

  const Patch.none({
    required this.gridPosition,
  })  : patchLeft = false,
        patchRight = false,
        patchTop = false,
        patchBottom = false;

  final Offset gridPosition;

  final bool patchLeft;
  final bool patchRight;
  final bool patchTop;
  final bool patchBottom;

  Patch copyWith({
    Offset? gridPosition,
    bool? patchLeft,
    bool? patchRight,
    bool? patchTop,
    bool? patchBottom,
  }) {
    return Patch(
      gridPosition: gridPosition ?? this.gridPosition,
      patchLeft: patchLeft ?? this.patchLeft,
      patchRight: patchRight ?? this.patchRight,
      patchTop: patchTop ?? this.patchTop,
      patchBottom: patchBottom ?? this.patchBottom,
    );
  }
}
