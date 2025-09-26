/// Tableau de bord principal du système avec état de tous les modules
import 'package:flutter/material.dart';
import '../../services/synchronization_service.dart';

class SystemStatusDashboard extends StatefulWidget {
  const SystemStatusDashboard({super.key});

  @override
  State<SystemStatusDashboard> createState() => _SystemStatusDashboardState();
}

class _SystemStatusDashboardState extends State<SystemStatusDashboard> {
  final SynchronizationService _syncService = SynchronizationService();

  bool _isLoading = true;
  Map<String, dynamic>? _systemStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
  }

  Future<void> _loadSystemStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _syncService.initialize();
      final status = await _syncService.getSystemStatus();

      setState(() {
        _systemStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _forceResync() async {
    try {
      await _syncService.forceResync();
      await _loadSystemStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Resynchronisation terminée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur de synchronisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Système'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSystemStatus,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: _isLoading ? null : _forceResync,
            icon: const Icon(Icons.sync),
            tooltip: 'Resynchroniser',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(theme, isDesktop),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de l\'état du système...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSystemStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_systemStatus == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemHealthCard(theme),
          const SizedBox(height: 24),
          _buildModulesGrid(theme, isDesktop),
          const SizedBox(height: 24),
          _buildDetailedStats(theme, isDesktop),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard(ThemeData theme) {
    final healthStatus = _systemStatus!['health_status'] as String;
    final totalProducts = _systemStatus!['total_products'] as int? ?? 0;
    final lastSync = _systemStatus!['last_sync'] as String? ?? '';
    final isSyncing = _systemStatus!['is_syncing'] as bool? ?? false;

    Color healthColor;
    IconData healthIcon;
    String healthText;

    switch (healthStatus) {
      case 'healthy':
        healthColor = Colors.green;
        healthIcon = Icons.check_circle;
        healthText = 'Système Opérationnel';
        break;
      case 'warning':
        healthColor = Colors.orange;
        healthIcon = Icons.warning;
        healthText = 'Avertissements Détectés';
        break;
      case 'error':
        healthColor = Colors.red;
        healthIcon = Icons.error;
        healthText = 'Erreurs Détectées';
        break;
      default:
        healthColor = Colors.grey;
        healthIcon = Icons.help;
        healthText = 'État Inconnu';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: healthColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                healthIcon,
                color: healthColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    healthText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalProducts produits dans le système',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isSyncing ? Icons.sync : Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSyncing
                            ? 'Synchronisation en cours...'
                            : 'Dernière synchro: ${_formatDateTime(lastSync)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid(ThemeData theme, bool isDesktop) {
    final modules = _systemStatus!['modules'] as Map<String, dynamic>;

    final moduleConfigs = [
      {
        'key': 'attribution',
        'title': 'Contrôle & Attribution',
        'icon': Icons.assignment_turned_in,
        'color': Colors.blue,
      },
      {
        'key': 'extraction',
        'title': 'Extraction',
        'icon': Icons.science,
        'color': Colors.green,
      },
      {
        'key': 'filtrage',
        'title': 'Filtrage',
        'icon': Icons.filter_alt,
        'color': Colors.purple,
      },
      {
        'key': 'cire',
        'title': 'Traitement Cire',
        'icon': Icons.texture,
        'color': Colors.brown,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.5 : 1.3,
      ),
      itemCount: moduleConfigs.length,
      itemBuilder: (context, index) {
        final config = moduleConfigs[index];
        final moduleData = modules[config['key']] as Map<String, dynamic>;

        return _buildModuleCard(
          theme,
          config['title'] as String,
          config['icon'] as IconData,
          config['color'] as Color,
          moduleData,
        );
      },
    );
  }

  Widget _buildModuleCard(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    Map<String, dynamic> data,
  ) {
    final total = data['total'] as int? ?? 0;
    final status = data['status'] as String? ?? 'unknown';
    final hasError = data['error'] != null;

    Color statusColor;
    IconData statusIcon;

    if (hasError) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (status == 'active') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$total produits',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Text(
                'Erreur détectée',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              _buildModuleStats(theme, data),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModuleStats(ThemeData theme, Map<String, dynamic> data) {
    final enAttente = data['en_attente'] as int? ?? 0;
    final enCours = data['en_cours'] as int? ?? 0;
    final termines = data['termines'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enAttente > 0)
          Text(
            '⏳ $enAttente en attente',
            style: theme.textTheme.bodySmall,
          ),
        if (enCours > 0)
          Text(
            '🔄 $enCours en cours',
            style: theme.textTheme.bodySmall,
          ),
        if (termines > 0)
          Text(
            '✅ $termines terminés',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildDetailedStats(ThemeData theme, bool isDesktop) {
    final modules = _systemStatus!['modules'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques Détaillées',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildAttributionDetails(
                          theme, modules['attribution'])),
                  const SizedBox(width: 16),
                  Expanded(child: _buildProcessingDetails(theme, modules)),
                ],
              )
            : Column(
                children: [
                  _buildAttributionDetails(theme, modules['attribution']),
                  const SizedBox(height: 16),
                  _buildProcessingDetails(theme, modules),
                ],
              ),
      ],
    );
  }

  Widget _buildAttributionDetails(ThemeData theme, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();

    final total = data['total'] as int? ?? 0;
    final controles = data['controles'] as int? ?? 0;
    final conformes = data['conformes'] as int? ?? 0;
    final attribues = data['attribues'] as int? ?? 0;
    final disponibles = data['disponibles'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Contrôle & Attribution',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total produits', total.toString(), Colors.blue),
            _buildStatRow('Contrôlés', controles.toString(), Colors.green),
            _buildStatRow('Conformes', conformes.toString(), Colors.teal),
            _buildStatRow('Attribués', attribues.toString(), Colors.orange),
            _buildStatRow('Disponibles', disponibles.toString(), Colors.purple),

            // Indicateurs de santé
            const SizedBox(height: 12),
            if (total > 0) ...[
              _buildProgressBar(
                'Contrôle',
                controles / total,
                Colors.green,
              ),
              _buildProgressBar(
                'Conformité',
                conformes / total,
                Colors.teal,
              ),
              _buildProgressBar(
                'Attribution',
                attribues / total,
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingDetails(
      ThemeData theme, Map<String, dynamic> modules) {
    final extraction = modules['extraction'] as Map<String, dynamic>?;
    final filtrage = modules['filtrage'] as Map<String, dynamic>?;
    final cire = modules['cire'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Processus de Traitement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (extraction != null) ...[
              _buildProcessSection(
                  'Extraction', Icons.science, Colors.green, extraction),
              const SizedBox(height: 8),
            ],
            if (filtrage != null) ...[
              _buildProcessSection(
                  'Filtrage', Icons.filter_alt, Colors.purple, filtrage),
              const SizedBox(height: 8),
            ],
            if (cire != null) ...[
              _buildProcessSection(
                  'Traitement Cire', Icons.texture, Colors.brown, cire),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessSection(
      String title, IconData icon, Color color, Map<String, dynamic> data) {
    final total = data['total'] as int? ?? 0;
    final enAttente = data['en_attente'] as int? ?? 0;
    final enCours = data['en_cours'] as int? ?? 0;
    final termines = data['termines'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '$total total',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('⏳ $enAttente', style: const TextStyle(fontSize: 12)),
            Text('🔄 $enCours', style: const TextStyle(fontSize: 12)),
            Text('✅ $termines', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '${(value * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'maintenant';
      } else if (difference.inHours < 1) {
        return 'il y a ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'il y a ${difference.inHours}h';
      } else {
        return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Inconnu';
    }
  }
}
