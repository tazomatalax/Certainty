import 'package:flutter/material.dart';

class SettingsSidebar extends StatefulWidget {
  final String currentShareMessage;
  final Function(String) onUpdateShareMessage;

  const SettingsSidebar({
    Key? key,
    required this.currentShareMessage,
    required this.onUpdateShareMessage,
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
