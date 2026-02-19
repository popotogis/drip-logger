import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Auth のインスタンスを提供するプロバイダー
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 認証サービスのプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

/// ユーザーのログイン状態を監視する StreamProvider
/// ログイン/ログアウトの変更を検知してUIを再描画するのに使います
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService(this._firebaseAuth);

  /// 認証状態の変更通知ストリーム
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// 現在のユーザー
  User? get currentUser => _firebaseAuth.currentUser;

  // Googleアカウントとリンク (データ引継ぎ用)
  Future<User?> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.currentUser?.linkWithCredential(credential);
      return userCredential?.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // 既にほかのユーザーに関連付けられている場合の処理
        print('このGoogleアカウントは既に使用されています。');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Googleでサインイン
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Sign in failed: $e');
      rethrow;
    }
  }

  /// 匿名認証でサインイン
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // 必要に応じてエラー詳細をログ出力など
      print('Failed with error code: ${e.code}');
      print(e.message);
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
