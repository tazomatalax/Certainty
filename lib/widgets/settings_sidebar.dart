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
    super.key,
    required this.currentShareMessage,
    required this.onUpdateShareMessage,
    required this.onToggleFavorites,
    required this.onAddNewTruth,
    required this.onToggleCustomTruths,
    required this.showingFavorites,
    required this.showingCustomTruths,
  });

  @override
  _SettingsSidebarState createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            title: const Text('Toggle Favorites'),
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
            title: const Text('Toggle Custom Truths'),
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
            title: const Text('Add New Truth'),
            onTap: () {
              widget.onAddNewTruth(context);
              // Don't close the drawer here, as we want to show the dialog
            },
          ),
          ListTile(
            leading: Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Edit Share Message'),
            onTap: () {
              _showShareMessageDialog(context);
            },
          ),
          // Add more settings options here if needed
        ],
      ),
    );
  }

  void _showShareMessageDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: widget.currentShareMessage);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Share Message'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter share message',
              helperText: 'Use {truth} to insert the truth text',
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                widget.onUpdateShareMessage(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  @override
  void dispose() {
    super.dispose();
  }
}
