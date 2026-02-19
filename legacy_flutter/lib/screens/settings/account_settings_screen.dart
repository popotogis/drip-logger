import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定'),
      ),
      body: ListView(
        children: [
          if (user != null) ...[
            ListTile(
              title: const Text('ユーザーID'),
              subtitle: Text(user.uid),
            ),
            ListTile(
              title: const Text('アカウント種別'),
              subtitle: Text(user.isAnonymous ? '匿名 (ゲスト)' : 'Google アカウント'),
              trailing: user.isAnonymous
                  ? const Chip(label: Text('未連携'))
                  : const Chip(
                      label: Text('連携済み'),
                      backgroundColor: Colors.green,
                    ),
            ),
            const Divider(),
            if (user.isAnonymous)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(authServiceProvider).linkWithGoogle();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Googleアカウントと連携しました')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('連携に失敗しました: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Googleアカウントと連携してデータを保存'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (!user.isAnonymous)
              ListTile(
                title: const Text('ログアウト'),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ] else
            const Center(child: Text('ログインしていません')),
        ],
      ),
    );
  }
}
