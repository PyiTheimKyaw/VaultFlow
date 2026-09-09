import 'package:flutter/material.dart';
import 'package:vf_ui/src/layout/breakpoints.dart';
import 'package:vf_ui/src/tokens/vf_spacing.dart';

/// A top-level navigation target.
@immutable
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
    this.tooltip,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? tooltip;
}

/// Lays out primary navigation, an optional [sidebar], the [body] and an
/// optional [detail] pane according to the window size class.
///
/// | Class    | Navigation             | Sidebar    | Detail       |
/// |----------|------------------------|------------|--------------|
/// | compact  | bottom `NavigationBar` | drawer     | hidden       |
/// | medium   | `NavigationRail`       | drawer     | hidden       |
/// | expanded | list inside sidebar    | persistent | side pane    |
///
/// The widget is stateless; the caller owns [selectedIndex]. Callers that
/// render `detail` on smaller classes should push it as a route instead.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    super.key,
    this.sidebar,
    this.detail,
    this.appBar,
    this.floatingActionButton,
    this.sidebarWidth = VfSizes.sidebarWidth,
    this.detailWidth = VfSizes.detailWidth,
    this.sizeClassOverride,
    this.onSidebarResize,
    this.onSidebarResizeEnd,
  }) : assert(destinations.length >= 2, 'need at least two destinations');

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Secondary navigation (e.g. the folder tree). Persistent when expanded,
  /// a drawer otherwise.
  final Widget? sidebar;

  /// Contextual pane shown to the right of [body] when expanded.
  final Widget? detail;

  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final double sidebarWidth;
  final double detailWidth;

  /// Forces a size class regardless of width; for tests and previews.
  final WindowSizeClass? sizeClassOverride;

  /// When set, the expanded layout shows a drag handle between the sidebar
  /// and the body and reports the requested width while dragging.
  final ValueChanged<double>? onSidebarResize;

  /// Called once when a resize drag ends (persist here).
  final VoidCallback? onSidebarResizeEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass =
            sizeClassOverride ?? Breakpoints.classify(constraints.maxWidth);
        return switch (sizeClass) {
          WindowSizeClass.compact => _buildCompact(context),
          WindowSizeClass.medium => _buildMedium(context),
          WindowSizeClass.expanded => _buildExpanded(context),
        };
      },
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: sidebar == null ? null : Drawer(child: SafeArea(child: sidebar!)),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
              tooltip: d.tooltip,
            ),
        ],
      ),
    );
  }

  Widget _buildMedium(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: sidebar == null ? null : Drawer(child: SafeArea(child: sidebar!)),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: Material(
              color: scheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SidebarNav(
                    destinations: destinations,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                  ),
                  if (sidebar != null) ...[
                    const Divider(),
                    Expanded(child: sidebar!),
                  ],
                ],
              ),
            ),
          ),
          if (onSidebarResize == null)
            const VerticalDivider()
          else
            _ResizeHandle(
              width: sidebarWidth,
              onResize: onSidebarResize!,
              onEnd: onSidebarResizeEnd,
            ),
          Expanded(child: body),
          if (detail != null) ...[
            const VerticalDivider(),
            SizedBox(width: detailWidth, child: detail),
          ],
        ],
      ),
    );
  }
}

class _SidebarNav extends StatelessWidget {
  const _SidebarNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VfSpacing.sm,
        vertical: VfSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < destinations.length; i++)
            ListTile(
              key: ValueKey('sidebar-nav-$i'),
              selected: i == selectedIndex,
              selectedTileColor: scheme.primaryContainer,
              selectedColor: scheme.onPrimaryContainer,
              leading: Icon(
                i == selectedIndex
                    ? destinations[i].selectedIcon
                    : destinations[i].icon,
              ),
              title: Text(destinations[i].label),
              onTap: () => onDestinationSelected(i),
            ),
        ],
      ),
    );
  }
}

/// A divider that can be dragged horizontally to resize the sidebar.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.width,
    required this.onResize,
    this.onEnd,
  });

  final double width;
  final ValueChanged<double> onResize;
  final VoidCallback? onEnd;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hover = false;
  bool _dragging = false;
  double _startWidth = 0;
  double _startX = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _hover || _dragging;
    return Semantics(
      label: 'Resize sidebar',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          key: const Key('sidebar-resize-handle'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            _startWidth = widget.width;
            _startX = d.globalPosition.dx;
            setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (d) =>
              widget.onResize(_startWidth + d.globalPosition.dx - _startX),
          onHorizontalDragEnd: (_) {
            setState(() => _dragging = false);
            widget.onEnd?.call();
          },
          onHorizontalDragCancel: () => setState(() => _dragging = false),
          child: SizedBox(
            width: 8,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: active ? 3 : 1,
                color: active ? scheme.primary : scheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
