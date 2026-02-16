import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';

class FirestoreRecipeRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  FirestoreRecipeRepository(this._firestore, this._uid);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('recipes');

  Future<List<Recipe>> loadRecipes() async {
    final snapshot =
        await _collection.orderBy('lastUsed', descending: true).get();

    return snapshot.docs.map((doc) {
      return Recipe.fromJson(doc.data());
    }).toList();
  }

  Future<void> saveRecipe(Recipe recipe) async {
    await _collection.doc(recipe.id).set(recipe.toJson());
  }

  Future<void> deleteRecipe(String id) async {
    await _collection.doc(id).delete();
  }

  Future<Recipe?> getRecipe(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Recipe.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> updateLastUsed(String id) async {
    await _collection.doc(id).update({
      'lastUsed': DateTime.now().toIso8601String(),
    });
  }
}

/// Define provider
final firestoreRecipeRepositoryProvider =
    Provider<FirestoreRecipeRepository>((ref) {
  // 認証状態の変化を監視してリビルドはさせるが、
  // 値の取得は同期的に行うことで初期化時のレースコンディションを防ぐ
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User is not signed in');
  }
  return FirestoreRecipeRepository(FirebaseFirestore.instance, user.uid);
});
