import 'package:flutter/material.dart';

class FornitoreDialog extends StatelessWidget {
  final void Function(String nome, String numero) onSave;

  const FornitoreDialog({Key? key, required this.onSave})
    : super(key: key); // Costruttore const: ottimo per performance

  @override
  Widget build(BuildContext context) {
    final nomeController = TextEditingController();
    final numeroController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Nota: se il dialog cresce, modularizza i campi in widget separati
    // Nota: se il dialog diventa stateful, sposta i controller fuori dal build per evitare memory leak
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.store, color: Colors.teal), // const
          const SizedBox(width: 8), // const
          const Text("Aggiungi Fornitore"), // const
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: "Nome fornitore",
                prefixIcon: const Icon(Icons.badge), // const
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Inserisci un nome valido";
                }
                return null;
              },
            ),
            const SizedBox(height: 12), // const
            TextFormField(
              controller: numeroController,
              decoration: InputDecoration(
                labelText: "Numero WhatsApp",
                prefixIcon: const Icon(Icons.phone), // const
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty || value.length < 9) {
                  return "Numero non valido";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Annulla", style: TextStyle(color: Colors.grey[700])),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final nome = nomeController.text.trim();
            final numero = numeroController.text.trim();
            onSave(nome, numero);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.save), // const
          label: const Text("Salva"), // const
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
