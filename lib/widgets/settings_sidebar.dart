import 'package:flutter/material.dart';

class SettingsSidebar extends StatefulWidget {
  final String currentShareMessage;
  final Function(String) onUpdateShareMessage;
  final VoidCallback onToggleFavorites;
  final Function(BuildContext) onAddNewTruth;
  final VoidCallback onToggleCustomTruths;
  final bool showingFavorites;
  final bool showingCustomTruths;

  const SettingsSidebar({
    Key? key,
    required this.currentShareMessage,
    required this.onUpdateShareMessage,
    required this.onToggleFavorites,
    required this.onAddNewTruth,
    required this.onToggleCustomTruths,
    required this.showingFavorites,
    required this.showingCustomTruths,
  }) : super(key: key);

  @override
  _SettingsSidebarState createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  late TextEditingController _shareMessageController;

  @override
  void initState() {
    super.initState();
    _shareMessageController = TextEditingController(text: widget.currentShareMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    widget.showingFavorites ? Icons.favorite : Icons.favorite_border,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('Toggle Favorites'),
                  onTap: () {
                    widget.onToggleFavorites();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    widget.showingCustomTruths ? Icons.person : Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('Toggle Custom Truths'),
                  onTap: () {
                    widget.onToggleCustomTruths();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('Add New Truth'),
                  onTap: () {
                    widget.onAddNewTruth(context);
                    // Don't close the drawer here, as we want to show the dialog
                  },
                ),
                // Add more settings options here if needed
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _shareMessageController,
                  decoration: InputDecoration(
                    hintText: 'Enter share message',
                    helperText: 'Use {truth} to insert the truth text',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onUpdateShareMessage(_shareMessageController.text);
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shareMessageController.dispose();
    super.dispose();
  }
}
