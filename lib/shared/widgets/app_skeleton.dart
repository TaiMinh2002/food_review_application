import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });
  final double? width;
  final double height, radius;
  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(
      opacity: _controller.drive(Tween(begin: .45, end: 1.0)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

class AppRestaurantSkeleton extends StatelessWidget {
  const AppRestaurantSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang tải quán ăn',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const AppSkeleton(width: 80, height: 80, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton(height: 16),
                  const SizedBox(height: 8),
                  const FractionallySizedBox(
                    widthFactor: .65,
                    child: AppSkeleton(height: 12),
                  ),
                  const SizedBox(height: 8),
                  const FractionallySizedBox(
                    widthFactor: .4,
                    child: AppSkeleton(height: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
