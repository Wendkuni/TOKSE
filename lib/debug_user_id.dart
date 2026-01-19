import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script de diagnostic pour vérifier les user_id
/// 
/// Comparer :
/// 1. auth.uid() de Supabase
/// 2. user_id stocké dans SharedPreferences
/// 3. user_id dans la table users
class UserIdDebugScreen extends StatefulWidget {
  const UserIdDebugScreen({super.key});

  @override
  State<UserIdDebugScreen> createState() => _UserIdDebugScreenState();
}

class _UserIdDebugScreenState extends State<UserIdDebugScreen> {
  String? _authUid;
  String? _sharedPrefsUserId;
  String? _databaseUserId;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _diagnoseUserIds();
  }

  Future<void> _diagnoseUserIds() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Récupérer auth.uid() de Supabase
      _authUid = supabase.auth.currentUser?.id;
      _userEmail = supabase.auth.currentUser?.email;

      // 2. Récupérer user_id de SharedPreferences (BONNE CLÉ)
      final prefs = await SharedPreferences.getInstance();
      _sharedPrefsUserId = prefs.getString('tokse_user_id'); // ✅ CORRECTION!
      final phoneStored = prefs.getString('tokse_user_phone');
      
      print('🔍 DEBUG SharedPreferences keys:');
      print('   tokse_user_id = $_sharedPrefsUserId');
      print('   tokse_user_phone = $phoneStored');

      // 3. Si pas d'auth.uid(), chercher par téléphone dans la DB
      if (_authUid == null && phoneStored != null) {
        print('📱 Recherche user_id par téléphone: $phoneStored');
        final response = await supabase
            .from('users')
            .select('id, email')
            .eq('telephone', phoneStored)
            .maybeSingle();
        
        if (response != null) {
          _databaseUserId = response['id'] as String?;
          print('✅ user_id trouvé en DB: $_databaseUserId');
        }
      } else if (_authUid != null) {
        // Sinon chercher par auth.uid()
        final response = await supabase
            .from('users')
            .select('id, email')
            .eq('id', _authUid!)
            .maybeSingle();
        
        if (response != null) {
          _databaseUserId = response['id'] as String?;
        }
      }

      print('🔍 DIAGNOSTIC USER_ID FINAL:');
      print('   auth.uid() = $_authUid');
      print('   SharedPrefs user_id = $_sharedPrefsUserId');
      print('   Database user_id = $_databaseUserId');
      print('   Email = $_userEmail');

    } catch (e) {
      print('❌ Erreur diagnostic: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fixUserIdInSharedPrefs() async {
    if (_authUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('auth.uid() est null')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _authUid!);
      
      print('✅ user_id corrigé dans SharedPreferences: $_authUid');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('user_id corrigé: $_authUid')),
      );

      // Re-diagnostiquer
      await _diagnoseUserIds();
    } catch (e) {
      print('❌ Erreur correction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic User ID'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    'Email',
                    _userEmail ?? 'N/A',
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'auth.uid() (Supabase Auth)',
                    _authUid ?? 'NULL',
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'SharedPreferences user_id',
                    _sharedPrefsUserId ?? 'NULL',
                    _sharedPrefsUserId == _authUid
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Database user_id',
                    _databaseUserId ?? 'NULL',
                    _databaseUserId == _authUid
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(height: 32),
                  if (_sharedPrefsUserId != _authUid) ...[
                    const Text(
                      '⚠️ PROBLÈME DÉTECTÉ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Le user_id dans SharedPreferences ne correspond pas à auth.uid().\n'
                      'Cela empêche l\'application de récupérer correctement vos données.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fixUserIdInSharedPrefs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'CORRIGER LE USER_ID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '✅ TOUT EST CORRECT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les user_id correspondent correctement.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _diagnoseUserIds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'RE-DIAGNOSTIQUER',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
