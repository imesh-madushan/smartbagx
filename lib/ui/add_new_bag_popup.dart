import 'package:flutter/material.dart';
import 'package:smartbagx/repository/bagRepository.dart';

Future<void> showAddBagDialog(BuildContext context) async {
  TextEditingController nameController = TextEditingController();
  TextEditingController idController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add a New Bag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Bag Name'),
            ),
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: 'Bag ID'),
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
              String bagID = idController.text;

              if (bagName.isNotEmpty && bagID.isNotEmpty) {
                // add the bag to Firestore
                final stat = await Bagrepository().addBag(bagName, bagID);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(stat)),
                );
                Navigator.of(context).pop(); // close the dialog
              } else {
                // show error if the fields are empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill out both fields')),
                );
              }
            },
            child: Text('Add Bag'),
          ),
        ],
      );
    },
  );
}
