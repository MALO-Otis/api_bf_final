import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/scoop_models.dart';

import '../../../../authentication/user_session.dart';
import 'modal_nouveau_scoop.dart';
import 'modal_selection_scoop.dart';

class SectionScoop extends StatefulWidget {
  final ScoopModel? selectedScoop;
  final Function(ScoopModel?) onScoopSelected;
  final VoidCallback? onNext;

  const SectionScoop({
    super.key,
    required this.selectedScoop,
    required this.onScoopSelected,
    this.onNext,
  });

  @override
  State<SectionScoop> createState() => _SectionScoopState();
}

class _SectionScoopState extends State<SectionScoop> {
  String _selectionMode = 'existant'; // 'existant' ou 'nouveau'
  final UserSession _userSession = Get.find<UserSession>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sélection du SCOOP',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Choisissez un SCOOP existant ou créez-en un nouveau',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Mode de sélection
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'existant',
                    groupValue: _selectionMode,
                    onChanged: (value) => setState(() {
                      _selectionMode = value!;
                      widget.onScoopSelected(null);
                    }),
                    title: const Text('SCOOP existant'),
                    subtitle: const Text(
                        'Sélectionner dans la liste des SCOOPs enregistrés'),
                    activeColor: Colors.amber.shade700,
                  ),
                  Divider(color: Colors.grey.shade300, height: 1),
                  RadioListTile<String>(
                    value: 'nouveau',
                    groupValue: _selectionMode,
                    onChanged: (value) => setState(() {
                      _selectionMode = value!;
                      widget.onScoopSelected(null);
                    }),
                    title: const Text('Nouveau SCOOP'),
                    subtitle: const Text(
                        'Créer un nouveau SCOOP pour cette collecte'),
                    activeColor: Colors.amber.shade700,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Interface selon le mode
          if (_selectionMode == 'existant') ...[
            _buildScoopExistantSection(),
          ] else ...[
            _buildNouveauScoopSection(),
          ],

          const SizedBox(height: 16),

          // Aperçu du SCOOP sélectionné
          if (widget.selectedScoop != null) _buildScoopPreview(),

          const SizedBox(height: 24),

          // Bouton continuer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continuer',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildScoopExistantSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionner un SCOOP',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openScoopSelectionModal,
                icon: const Icon(Icons.search),
                label: Text(
                  widget.selectedScoop?.nom ?? 'Choisir dans la liste',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade100,
                  foregroundColor: Colors.amber.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNouveauScoopSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créer un nouveau SCOOP',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openNewScoopModal,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Créer un nouveau SCOOP',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoopPreview() {
    final scoop = widget.selectedScoop!;
    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'SCOOP sélectionné',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              scoop.nom,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Président: ${scoop.president} • Tél: ${scoop.telephone}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Zone: ${scoop.localisation}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildInfoChip('${scoop.nbMembres} membres', Icons.group),
                _buildInfoChip(
                    '${scoop.nbRuchesTrad + scoop.nbRuchesModernes} ruches',
                    Icons.hive),
                _buildInfoChip(
                    '${scoop.predominanceFlorale.length} types floraux',
                    Icons.local_florist),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.amber.shade700),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.amber.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _openScoopSelectionModal() async {
    final scoop = await showModalBottomSheet<ScoopModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ModalSelectionScoop(
        site: _userSession.site ?? '',
      ),
    );

    if (scoop != null) {
      widget.onScoopSelected(scoop);
    }
  }

  void _openNewScoopModal() async {
    final scoop = await showDialog<ScoopModel>(
      context: context,
      builder: (context) => ModalNouveauScoop(
        site: _userSession.site ?? '',
      ),
    );

    if (scoop != null) {
      widget.onScoopSelected(scoop);
    }
  }
}
