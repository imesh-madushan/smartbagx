import 'package:flutter/material.dart';
import 'package:smartbagx/repository/bagRepository.dart';

Future<void> showBagRenameDialog(BuildContext context, String bagId) async {
  TextEditingController nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Rename Bag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'New Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              String bagName = nameController.text;

              if (bagName.isNotEmpty) {
                Bagrepository().renameBag(bagId, bagName);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bag renamed successfully')),
                );
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill out the field')),
                );
              }
            },
            child: Text('Rename'),
          ),
        ],
      );
    },
  );
}
