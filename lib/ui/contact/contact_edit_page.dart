import 'package:contacts_app/data/contact.dart';
import 'package:contacts_app/ui/contact/widget/contact_form.dart';
import 'package:flutter/material.dart';

class ContactEditPage extends StatelessWidget {
  final Contact editedContact;

  const ContactEditPage({super.key, required this.editedContact});

  @override
  Widget build(BuildContext context) {
    return ContactForm(editedContact: editedContact);
  }
}
