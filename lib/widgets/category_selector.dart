import 'package:flutter/material.dart';

class CategoryItem {
  final String key;
  final String displayName;
  final IconData icon;

  const CategoryItem({
    required this.key,
    required this.displayName,
    required this.icon,
  });
}

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<CategoryItem> _categories = [
    CategoryItem(key: 'general', displayName: 'General', icon: Icons.newspaper),
    CategoryItem(key: 'technology', displayName: 'Tecnología', icon: Icons.computer),
    CategoryItem(key: 'sports', displayName: 'Deportes', icon: Icons.sports_soccer),
    CategoryItem(key: 'business', displayName: 'Negocios', icon: Icons.business_center),
    CategoryItem(key: 'health', displayName: 'Salud', icon: Icons.medical_services),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category.key == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              avatar: Icon(
                category.icon,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              label: Text(
                category.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(category.key);
                }
              },
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected 
                      ? Colors.transparent 
                      : theme.colorScheme.outlineVariant.withAlpha(128),
                  width: 1,
                ),
              ),
              elevation: isSelected ? 2 : 0,
              pressElevation: 4,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
