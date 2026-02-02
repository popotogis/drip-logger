import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../utils/recipe_sharer.dart';
import 'bean_list_screen.dart';
import 'recipe_edit_screen.dart';
import 'recipe_detail_screen.dart';

/// レシピ一覧画面 (ホーム画面)
///
/// 保存されているレシピをリスト表示し、新規作成や豆管理画面への遷移を提供します。
class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final repository = ref.read(recipeRepositoryProvider);
    final recipes = await repository.loadRecipes();
    if (mounted) {
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRecipes() async {
    final repository = ref.read(recipeRepositoryProvider);
    await repository.saveRecipes(_recipes);
  }

  // レシピimport用
  Future<void> _importRecipe() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.isEmpty) return;

    final recipe = RecipeSharer.decode(text);
    if (recipe != null) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Recipe'),
          content: Text('Do you want to import "${recipe.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (!mounted) return;
        final savedRecipe = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeEditScreen(recipe: recipe),
          ),
        );

        if (savedRecipe != null) {
          // Add or Update locally
          final index = _recipes.indexWhere((r) => r.id == savedRecipe.id);
          if (index != -1) {
            _recipes[index] = savedRecipe;
          } else {
            _recipes.add(savedRecipe);
          }
          await _saveRecipes();
          await _loadRecipes();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid recipe code')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRecipe,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Recipes'),
            centerTitle: true,
            pinned: true,
            actions: [
              IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _importRecipe,
                  tooltip: 'Import Recipe'),
              IconButton(
                icon: const Icon(Icons.coffee),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BeanListScreen()),
                  );
                },
                tooltip: 'Manage Beans',
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = _recipes[index];
                return Column(
                  children: [
                    Slidable(
                      key: Key(recipe.id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.2,
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              setState(() {
                                _recipes.removeAt(index);
                              });
                              _saveRecipes(); // Delete persistence
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('${recipe.name} deleted')),
                              );
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        title: Text(
                          recipe.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${recipe.beanWeightGrams}g · ${recipe.totalWaterAmount}ml',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[600]),
                            ),
                            if (recipe.note != null && recipe.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  recipe.note!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      overflow: TextOverflow.ellipsis),
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _navigateToDetail(recipe, index),
                      ),
                    ),
                    if (index < _recipes.length - 1)
                      const Divider(height: 1, indent: 20),
                  ],
                );
              },
              childCount: _recipes.length,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewRecipe() async {
    final newRecipe = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecipeEditScreen()),
    );

    if (newRecipe != null && newRecipe is Recipe) {
      // Add and Save locally first
      _recipes.add(newRecipe);
      await _saveRecipes();
    }
    // Always reload to ensure sorting (newly added should be top)
    await _loadRecipes();
  }

  Future<void> _navigateToDetail(Recipe recipe, int index) async {
    final updatedRecipe = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );

    if (updatedRecipe != null && updatedRecipe is Recipe) {
      if (updatedRecipe.id == recipe.id) {
        // ID unchanged: Overwrite (Edit)
        _recipes[index] = updatedRecipe;
      } else {
        // ID changed: Add New (Save as New)
        _recipes.add(updatedRecipe);
      }
      await _saveRecipes();
    }
    // Always reload to catch "Last Used" updates from Brewing or just sorting changes
    await _loadRecipes();
  }
}
