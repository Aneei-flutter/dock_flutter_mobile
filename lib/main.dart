import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A macOS-inspired dock widget positioned at the bottom of the screen.
///
/// Provides a full-width dock with smooth icon magnification, reordering,
/// and sophisticated dragging interactions.
///
///
/// The main entry point of the application.
///
/// This function is called when the app is launched.
void main() {
  // Runs the BottomDockApp
  runApp(const BottomDockApp());
}



class BottomDock<T> extends StatefulWidget {
  /// Creates a bottom dock with customizable appearance and behavior.
  const BottomDock({
    super.key,
    required this.items,
    required this.builder,
    this.magnificationFactor = 2.0,
    this.magnificationRadius = 150.0,
    this.itemSize = 64.0,
    this.spacing = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.backgroundColor = Colors.black12,
    this.shadowColor = Colors.black26,
    this.borderRadius = 24.0,
  });

  /// The list of items to be displayed in the dock.
  final List<T> items;

  /// A builder function that creates a widget for each dock item.
  final Widget Function(T) builder;

  /// The maximum scale factor for icon magnification during hover.
  final double magnificationFactor;

  /// The radius within which icons get magnified.
  final double magnificationRadius;

  /// The base size of each dock item.
  final double itemSize;

  /// The spacing between dock items.
  final double spacing;

  /// Padding around the dock container.
  final EdgeInsets padding;

  /// Background color of the dock.
  final Color backgroundColor;

  /// Shadow color for the dock container.
  final Color shadowColor;

  /// Border radius for the dock container.
  final double borderRadius;

  @override
  State<BottomDock<T>> createState() => _BottomDockState<T>();
}

class _BottomDockState<T> extends State<BottomDock<T>> with TickerProviderStateMixin {
  late List<T> _items;
  T? _draggedItem;
  Offset _dragPosition = Offset.zero;
  final GlobalKey _dockKey = GlobalKey();
  late AnimationController _reorderController;
  late Animation<double> _reorderAnimation;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);

    // Initialize animation controller for smooth reordering
    _reorderController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _reorderAnimation = CurvedAnimation(
      parent: _reorderController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _reorderController.dispose();
    super.dispose();
  }

  /// Calculates the scale of an item based on its proximity to the drag position.
  double _calculateScale(T item, Offset position) {
    if (_draggedItem == null) return 1.0;

    final RenderBox? dockRenderBox =
    _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (dockRenderBox == null) return 1.0;

    final localPosition = dockRenderBox.globalToLocal(position);
    final index = _items.indexOf(item);

    final itemPosition = Offset(
      index * (widget.itemSize + widget.spacing),
      dockRenderBox.size.height / 2,
    );

    final distance = (localPosition - itemPosition).distance;

    return distance < widget.magnificationRadius
        ? math.max(
      1.0,
      widget.magnificationFactor - (distance / widget.magnificationRadius),
    )
        : 1.0;
  }

  /// Updates the order of items during dragging.
  void _updateItemOrder(Offset globalPosition) {
    if (_draggedItem == null) return;

    final RenderBox? dockRenderBox =
    _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (dockRenderBox == null) return;

    final localPosition = dockRenderBox.globalToLocal(globalPosition);
    final newIndex = (localPosition.dx / (widget.itemSize + widget.spacing))
        .round()
        .clamp(0, _items.length - 1);

    final currentIndex = _items.indexOf(_draggedItem!);

    if (newIndex != currentIndex) {
      setState(() {
        _items.removeAt(currentIndex);
        _items.insert(newIndex, _draggedItem!);
      });

      // Trigger smooth reordering animation
      _reorderController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _dragPosition = details.globalPosition;
                _updateItemOrder(details.globalPosition);
              });
            },
            onPanEnd: (_) {
              setState(() {
                _draggedItem = null;
              });

              // Ensure final smooth settling
              _reorderController.forward(from: 0);
            },
            child: Container(
              key: _dockKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: widget.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor,
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: widget.padding,
              child: AnimatedBuilder(
                animation: _reorderAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return GestureDetector(
                        onTapDown: (_) {
                          setState(() {
                            _draggedItem = item;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutQuad,
                          width: widget.itemSize,
                          height: widget.itemSize,
                          margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                          transform: Matrix4.translationValues(
                              0,
                              // Add a subtle bounce effect when reordering
                              -10 * math.sin(_reorderAnimation.value * math.pi),
                              0
                          ),
                          child: AnimatedScale(
                            scale: _calculateScale(item, _dragPosition),
                            duration: const Duration(milliseconds: 100),
                            child: widget.builder(item),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Example application demonstrating the BottomDock widget.
class BottomDockApp extends StatelessWidget {
  /// Constructs the main application widget.
  const BottomDockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Colors.white),
            ),
            BottomDock<IconData>(
              items: const [
                Icons.person,
                Icons.message,
                Icons.call,
                Icons.camera,
                Icons.photo,
              ],
              magnificationFactor: 2.0,
              magnificationRadius: 150.0,
              itemSize: 56.0,
              builder: (icon) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.primaries[icon.hashCode % Colors.primaries.length],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

