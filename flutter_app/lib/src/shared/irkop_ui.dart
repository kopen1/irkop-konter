import 'package:flutter/material.dart';

class IrkopPageFrame extends StatelessWidget {
  const IrkopPageFrame({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 28)});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: maxWidth, child: ListView(padding: padding, children: children)),
      );
    },
  );
}

class IrkopSectionHeader extends StatelessWidget {
  const IrkopSectionHeader({super.key, required this.eyebrow, required this.title, required this.subtitle, required this.icon, required this.action, this.onAction});
  final String eyebrow, title, subtitle, action;
  final IconData icon;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.primaryContainer.withValues(alpha: .78)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 23, backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, child: Icon(icon)),
          const SizedBox(width: 12),
          Expanded(child: Text(eyebrow.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.15))),
          if (onAction != null) IconButton.filledTonal(onPressed: onAction, icon: const Icon(Icons.add), tooltip: action),
        ]),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)),
        if (onAction != null) ...[
          const SizedBox(height: 16),
          FilledButton.tonalIcon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(action)),
        ],
      ]),
    );
  }
}

class IrkopMetricCard extends StatelessWidget {
  const IrkopMetricCard({super.key, required this.icon, required this.label, required this.value, this.caption});
  final IconData icon;
  final String label, value;
  final String? caption;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 14),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        if (caption != null) ...[const SizedBox(height: 4), Text(caption!, style: Theme.of(context).textTheme.bodySmall)],
      ]),
    ),
  );
}

class IrkopFilterBar extends StatelessWidget {
  const IrkopFilterBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: child));
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.icon, required this.title, required this.subtitle, this.action, this.onAction});
  final IconData icon;
  final String title, subtitle;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 34, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
        if (onAction != null && action != null) ...[const SizedBox(height: 18), FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(action!))],
      ])),
    ),
  );
}
