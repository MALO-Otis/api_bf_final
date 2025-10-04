import 'package:flutter/material.dart';

/// Version simplifiée de la page historique pour déboguer
class HistoriqueAttributionPageSimple extends StatelessWidget {
  const HistoriqueAttributionPageSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historique & Statistiques',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            Container(
              color: Colors.deepPurple.shade700,
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
                  Tab(icon: Icon(Icons.assignment), text: 'Attributions'),
                  Tab(icon: Icon(Icons.science), text: 'Contrôles Qualité'),
                  Tab(icon: Icon(Icons.inventory), text: 'Données Reçues'),
                  Tab(icon: Icon(Icons.timeline), text: 'Chronologie'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _SimpleTab(title: 'Vue d\'ensemble', icon: Icons.dashboard),
                  _SimpleTab(title: 'Attributions', icon: Icons.assignment),
                  _SimpleTab(title: 'Contrôles Qualité', icon: Icons.science),
                  _SimpleTab(title: 'Données Reçues', icon: Icons.inventory),
                  _SimpleTab(title: 'Chronologie', icon: Icons.timeline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SimpleTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.deepPurple.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Onglet fonctionnel !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Les onglets fonctionnent correctement',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
