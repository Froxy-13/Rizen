import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

enum _Filtre { tous, activite, offres, systeme }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  _Filtre _filtre = _Filtre.tous;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final data = await _service.getNotifications(userId);
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _marquerToutesLues() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() {
      for (final n in _notifications) {
        n['lu'] = true;
      }
    });
    try {
      await _service.marquerToutesLues(userId);
    } catch (_) {
      _charger();
    }
  }

  Future<void> _tapNotification(Map<String, dynamic> notif) async {
    if (notif['lu'] == true) return;
    setState(() => notif['lu'] = true);
    try {
      await _service.marquerLue(notif['id'] as int);
    } catch (_) {
      setState(() => notif['lu'] = false);
    }
  }

  // Regroupe les types réels de la table sous les 3 filtres du mockup
  bool _correspondAuFiltre(String type, _Filtre filtre) {
    switch (filtre) {
      case _Filtre.tous:
        return true;
      case _Filtre.activite:
        return ['message', 'transaction', 'annonce'].contains(type);
      case _Filtre.offres:
        return type == 'negociation';
      case _Filtre.systeme:
        return ['systeme', 'signalement'].contains(type);
    }
  }

  List<Map<String, dynamic>> get _notificationsFiltrees {
    if (_filtre == _Filtre.tous) return _notifications;
    return _notifications
        .where((n) => _correspondAuFiltre(n['type'] as String, _filtre))
        .toList();
  }

  String _tempsEcoule(String? dateIso) {
    if (dateIso == null) return '';
    final date = DateTime.parse(dateIso);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  ({IconData icon, Color couleur}) _styleType(String type) {
    switch (type) {
      case 'message':
        return (icon: Icons.chat_bubble_outline, couleur: AppColors.primary);
      case 'negociation':
        return (icon: Icons.handshake_outlined, couleur: AppColors.primary);
      case 'transaction':
        return (icon: Icons.local_shipping_outlined, couleur: AppColors.emerald);
      case 'annonce':
        return (icon: Icons.campaign_outlined, couleur: AppColors.navy);
      case 'signalement':
        return (icon: Icons.flag_outlined, couleur: Colors.red);
      case 'systeme':
      default:
        return (icon: Icons.info_outline, couleur: AppColors.rosyTaupe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = _notificationsFiltrees;
    final aDesNonLues = _notifications.any((n) => n['lu'] != true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _charger,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                    AppSpacing.containerMargin,
                    AppSpacing.stackSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back,
                                color: AppColors.navy),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Text('Notifications',
                              style: AppTextStyles.headlineSm),
                        ],
                      ),
                      if (aDesNonLues)
                        GestureDetector(
                          onTap: _marquerToutesLues,
                          child: Text(
                            'Tout marquer comme lu',
                            style: AppTextStyles.bodySm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Filtres ─────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerMargin,
                      vertical: AppSpacing.stackSm,
                    ),
                    itemCount: _Filtre.values.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.stackSm),
                    itemBuilder: (context, index) {
                      final f = _Filtre.values[index];
                      final label = switch (f) {
                        _Filtre.tous => 'Tous',
                        _Filtre.activite => 'Activité',
                        _Filtre.offres => 'Offres',
                        _Filtre.systeme => 'Système',
                      };
                      final selected = _filtre == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filtre = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.navy
                                : AppColors.softBlush,
                            borderRadius:
                            BorderRadius.circular(AppRadius.full),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: selected
                                    ? Colors.white
                                    : AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Liste ───────────────────────────────────
              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                ),
              )
                  : liste.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none,
                          size: 56, color: AppColors.paleOak),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        'Aucune notification',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.rosyTaupe,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.stackSm,
                  AppSpacing.containerMargin,
                  40,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildCard(liste[index]),
                    childCount: liste.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notif) {
    final type = notif['type'] as String;
    final style = _styleType(type);
    final nonLue = notif['lu'] != true;

    return GestureDetector(
      onTap: () => _tapNotification(notif),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: nonLue
              ? Border(left: BorderSide(color: style.couleur, width: 4))
              : null,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.couleur.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.couleur, size: 20),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif['titre'] as String,
                          style: AppTextStyles.titleMd.copyWith(
                            fontSize: 15,
                            fontWeight: nonLue
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tempsEcoule(notif['date_notification'] as String?),
                        style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['message'] as String,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (nonLue) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: style.couleur,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}