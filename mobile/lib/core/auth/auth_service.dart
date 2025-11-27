import 'package:firebase_auth/firebase_auth.dart';

/// AuthServiceのインターフェース
abstract class AuthServiceInterface {
  /// 現在のユーザーを取得（未ログイン時はnull）
  User? get currentUser;

  /// ログイン状態を取得
  bool get isAuthenticated;

  /// 認証状態の変更を監視
  Stream<User?> get authStateChanges;

  /// Firebase ID Tokenを取得
  /// [forceRefresh]がtrueの場合、強制リフレッシュ
  Future<String?> getIdToken({bool forceRefresh = false});

  /// ログアウト
  Future<void> signOut();
}

/// Firebase認証の状態管理とトークン取得を行うサービス
class AuthService implements AuthServiceInterface {
  final FirebaseAuth _firebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken(forceRefresh);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
