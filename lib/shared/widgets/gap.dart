import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gap for row or column
///
class Gap extends LeafRenderObjectWidget {
  final double size;

  const Gap(this.size, {super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GapRenderBox(size: size);
  }

  @override
  void updateRenderObject(BuildContext context, GapRenderBox renderObject) {
    renderObject._width = size;
    renderObject._height = size;
  }
}

/// Custom RenderBox that creates a gap
///
class GapRenderBox extends RenderBox {
  double? _width;
  double? _height;

  GapRenderBox({required double size}) {
    _width = size;
    _height = size;
  }

  @override
  void performLayout() {
    if (parentData is FlexParentData) {
      final flexParent = parent;
      if (flexParent is RenderFlex) {
        if (flexParent.direction == Axis.vertical) {
          size = constraints.constrain(Size(0, _height ?? 0));
        } else if (flexParent.direction == Axis.horizontal) {
          size = constraints.constrain(Size(_width ?? 0, 0));
        }
      }
    } else {
      size = constraints.constrain(Size(_width ?? 0, _height ?? 0));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  bool hitTestSelf(Offset position) => true;
}
