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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/certainty_logo_512.png',
                  height: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Certainty',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your personal truth compass',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
          // ListTile(
          //   leading: Icon(Icons.message, color: Theme.of(context).colorScheme.primary),
          //   title: const Text('Manage Share Templates'),
          //   onTap: () => _manageShareTemplates(context),
          // ),
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

  void _manageShareTemplates(BuildContext context) {
    // Implement a dialog or screen to manage multiple share templates
  }

  @override
  void dispose() {
    super.dispose();
  }
}

