import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../utils/recipe_sharer.dart';
import '../utils/dev_data.dart'; // for generateDummyData
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
          await ref.read(recipeRepositoryProvider).saveRecipe(savedRecipe);
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
              if (kDebugMode)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'reset') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Dev: Reset Data'),
                          content: const Text(
                              'ALL DATA WILL BE DELETED and replaced with dummy data.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('EXECUTE')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Processing...')));
                        }
                        await generateDummyData(ref);
                        await _loadRecipes();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Done!')));
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Dev: Reset & Seed'),
                    ),
                  ],
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
                            onPressed: (context) async {
                              final deletedName = recipe.name;
                              // Optimistic update
                              setState(() {
                                _recipes.removeAt(index);
                              });
                              await ref
                                  .read(recipeRepositoryProvider)
                                  .deleteRecipe(recipe.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('$deletedName deleted')),
                                );
                              }
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
      await ref.read(recipeRepositoryProvider).saveRecipe(newRecipe);
      await _loadRecipes();
    }
  }

  Future<void> _navigateToDetail(Recipe recipe, int index) async {
    final updatedRecipe = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );

    // 抽出フローから戻った場合や編集された場合など、常にリロードして最新のLastUsed順序を反映する
    if (updatedRecipe != null && updatedRecipe is Recipe) {
      await ref.read(recipeRepositoryProvider).saveRecipe(updatedRecipe);
    }
    await _loadRecipes();
  }
}
