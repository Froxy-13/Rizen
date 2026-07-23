import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('utilisateur_id', userId)
        .order('date_notification', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> marquerLue(int id) async {
    await _client.from('notifications').update({'lu': true}).eq('id', id);
  }

  Future<void> marquerToutesLues(String userId) async {
    await _client
        .from('notifications')
        .update({'lu': true})
        .eq('utilisateur_id', userId)
        .eq('lu', false);
  }

  Future<int> getNombreNonLues(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('utilisateur_id', userId)
        .eq('lu', false);
    return (data as List).length;
  }
}