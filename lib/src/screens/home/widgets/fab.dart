import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/post_creation/post_creation_modal.dart';

Widget customFAB(BuildContext context) {
  return FloatingActionButton(
    onPressed: () {
      showModalBottomSheet(
        context: context,
        builder: (context) => const PostCreationModal(),
      );
    },
    child: const Icon(Icons.add),
  );
}