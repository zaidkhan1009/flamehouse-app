import 'package:flutter/material.dart';
import 'ai_service.dart';

class AIAssistantSheet extends StatefulWidget {
  const AIAssistantSheet({super.key});

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final AIService _aiService = AIService();
  
  String _selectedFeature = 'general'; // general, menu_pricing, inventory_actions
  bool _isLoading = false;
  AISuggestion? _suggestion;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
      _suggestion = null;
      _errorMessage = null;
    });

    final contextData = {
      'client_timestamp': DateTime.now().toIso8601String(),
      'requested_by': 'operator',
    };

    final result = await _aiService.fetchSuggestion(_selectedFeature, contextData);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _suggestion = result;
      } else {
        _errorMessage = 'Could not fetch recommendation. Check connection or settings.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        top: 24.0,
        left: 24.0,
        right: 24.0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header ---
          Row(
            children: [
              Icon(Icons.psychology, color: theme.colorScheme.primary, size: 32.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Business Copilot',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Realtime suggestions & actions',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // --- Feature Chips ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FilterChip(
                label: const Text('General'),
                selected: _selectedFeature == 'general',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFeature = 'general');
                    _fetchRecommendation();
                  }
                },
              ),
              FilterChip(
                label: const Text('Pricing'),
                selected: _selectedFeature == 'menu_pricing',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFeature = 'menu_pricing');
                    _fetchRecommendation();
                  }
                },
              ),
              FilterChip(
                label: const Text('Inventory'),
                selected: _selectedFeature == 'inventory_actions',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFeature = 'inventory_actions');
                    _fetchRecommendation();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // --- Main Content Area ---
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120.0),
            child: _buildContent(theme),
          ),
          const SizedBox(height: 20.0),

          // --- Close Button ---
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            child: const Text('Dismiss Copilot'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12.0),
            Text(
              'Analyzing restaurant operations metrics...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13.0, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestion != null) {
      final s = _suggestion!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Suggestion Box
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8.0),
                    Text(
                      'AI Recommendation',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  s.recommendation,
                  style: const TextStyle(fontSize: 15.0, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Metadata Badge Rows
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildMetadataBadge('Engine: ${s.metadata['provider'] ?? 'local'}'),
              _buildMetadataBadge('Model: ${s.metadata['model'] ?? 'rules-engine'}'),
              _buildMetadataBadge('Latency: ${s.metadata['latency_ms'] ?? 0}ms'),
              _buildMetadataBadge('Menu Count: ${s.metadata['menu_count'] ?? 0}'),
              _buildMetadataBadge('Stock Items: ${s.metadata['inventory_count'] ?? 0}'),
              if (s.metadata['low_stock_count'] != null && s.metadata['low_stock_count'] > 0)
                _buildWarningBadge('${s.metadata['low_stock_count']} Low Stock Items'),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMetadataBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.0, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildWarningBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.0, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
      ),
    );
  }
}
