import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../utils/category_helper.dart';
import '../widgets/responsive_wrapper.dart';

const _emojiCandidates = [
  '🏥', '🎓', '🚗', '💪', '🎮', '🍽️',
  '✈️', '🐾', '👶', '💊', '📱', '🎨',
  '🎵', '📚', '🏦', '🔧', '⚡', '🌱',
];

class CategoryManageScreen extends ConsumerWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoryManageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.categoryAdd),
      ),
      body: ResponsiveWrapper(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (categories) {
            if (categories.isEmpty) {
              return Center(child: Text(l10n.categoryEmpty));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final displayName = getCategoryDisplayName(cat.name, l10n);
                return _CategoryTile(
                  category: cat,
                  displayName: displayName,
                  theme: theme,
                  l10n: l10n,
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    model.Category? existing,
  }) async {
    final result = await showDialog<({String name, String icon})>(
      context: context,
      builder: (ctx) => _CategoryEditDialog(
        l10n: l10n,
        initialName: existing?.name,
        initialIcon: existing?.icon,
      ),
    );

    if (result == null) return;

    final actions = ref.read(categoryActionsProvider);
    if (existing != null) {
      await actions.update(existing.copyWith(
        name: result.name,
        icon: result.icon,
      ));
    } else {
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      await actions.add(model.Category(
        name: result.name,
        icon: result.icon,
        sortOrder: categories.length,
        createdAt: DateTime.now(),
      ));
    }
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    required this.category,
    required this.displayName,
    required this.theme,
    required this.l10n,
  });

  final model.Category category;
  final String displayName;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (category.isDefault) {
      return ListTile(
        leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
        title: Text(displayName),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            l10n.categoryDefault,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context, ref),
      child: ListTile(
        leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
        title: Text(displayName),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => CategoryManageScreen._showCategoryDialog(
          context,
          ref,
          l10n,
          existing: category,
        ),
        onLongPress: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categoryDeleteTitle),
        content: Text(l10n.categoryDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && category.id != null) {
      await ref.read(categoryActionsProvider).delete(category.id!);
    }
    return confirmed;
  }
}

class _CategoryEditDialog extends StatefulWidget {
  const _CategoryEditDialog({
    required this.l10n,
    this.initialName,
    this.initialIcon,
  });

  final AppLocalizations l10n;
  final String? initialName;
  final String? initialIcon;

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? _emojiCandidates.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? l10n.categoryEdit : l10n.categoryAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: l10n.categoryNameLabel,
                hintText: l10n.categoryNameHint,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.categoryIconLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: _emojiCandidates.map((emoji) {
                final isSelected = _selectedIcon == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name: name, icon: _selectedIcon));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
