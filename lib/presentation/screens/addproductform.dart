import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? prodottoDaModificare;
  const AddProductForm({
    Key? key,
    this.prodottoDaModificare,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantitaController = TextEditingController();
  final TextEditingController _sogliaController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _prezzoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prodottoDaModificare != null) {
      _nomeController.text = widget.prodottoDaModificare!['nome'];
      _quantitaController.text =
          widget.prodottoDaModificare!['quantita'].toString();
      _sogliaController.text =
          widget.prodottoDaModificare!['soglia'].toString();
      _categoriaController.text =
          widget.prodottoDaModificare!['categoria'] ?? '';
      _prezzoController.text =
          widget.prodottoDaModificare!['prezzoUnitario']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantitaController.dispose();
    _sogliaController.dispose();
    _categoriaController.dispose();
    _prezzoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _nomeController,
              label: 'Nome Prodotto',
              icon: Icons.inventory_2_outlined,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obbligatorio'
                          : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _quantitaController,
              label: 'Quantità',
              icon: Icons.numbers,
              keyboardType: TextInputType.number,
              validator:
                  (value) =>
                      int.tryParse(value ?? '') == null
                          ? 'Inserisci un numero valido'
                          : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _sogliaController,
              label: 'Soglia minima di avviso',
              icon: Icons.warning_amber_outlined,
              keyboardType: TextInputType.number,
              validator:
                  (value) =>
                      int.tryParse(value ?? '') == null
                          ? 'Inserisci un numero valido'
                          : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _categoriaController,
              label: 'Categoria',
              icon: Icons.category,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obbligatorio'
                          : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _prezzoController,
              label: 'Prezzo unitario',
              icon: Icons.euro,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obbligatorio';
                }
                // Sostituisce le virgole con i punti per il parsing
                final normalizedValue = value.replaceAll(',', '.');
                if (double.tryParse(normalizedValue) == null) {
                  return 'Inserisci un prezzo valido';
                }
                return null;
              },
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final newProduct = {
                      'nome': _nomeController.text.trim(),
                      'quantita': int.parse(_quantitaController.text),
                      'soglia': int.parse(_sogliaController.text),
                      'categoria': _categoriaController.text.trim(),
                      'prezzoUnitario': double.parse(
                        _prezzoController.text.replaceAll(',', '.'),
                      ),
                      'consumati': 0,
                      'ultimaModifica': DateTime.now(),
                    };
                    widget.onSave(newProduct);
                  }
                },
                child: Text(
                  'Salva',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
        filled: true,
        fillColor: Colors.teal.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// Pagina principale per gestire i prodotti e aprire il form

class ProdottiPage extends StatefulWidget {
  const ProdottiPage({Key? key}) : super(key: key);

  @override
  State<ProdottiPage> createState() => _ProdottiPageState();
}

class _ProdottiPageState extends State<ProdottiPage> {
  final CollectionReference prodottiRef = FirebaseFirestore.instance.collection(
    'prodotti',
  );

  Future<void> _aggiungiProdotto() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Aggiungi prodotto'),
            content: AddProductForm(onSave: (newProduct) {}),
          ),
    );

    if (result != null) {
      await prodottiRef.add(result);
      setState(() {}); // Ricarica la pagina per aggiornare la lista
    }
  }

  Future<void> _modificaProdotto(
    String id,
    Map<String, dynamic> prodotto,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Modifica prodotto'),
            content: AddProductForm(
              prodottoDaModificare: prodotto,
              onSave: (newProduct) {},
            ),
          ),
    );

    if (result != null) {
      await prodottiRef.doc(id).update(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestione Prodotti')),
      body: StreamBuilder<QuerySnapshot>(
        stream: prodottiRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final prodotti = snapshot.data!.docs;

          if (prodotti.isEmpty) {
            return Center(child: Text('Nessun prodotto disponibile'));
          }

          return ListView.builder(
            itemCount: prodotti.length,
            itemBuilder: (context, index) {
              final prodotto = prodotti[index];
              final data = prodotto.data()! as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nome'] ?? ''),
                subtitle: Text(
                  'Quantità: ${data['quantita']}, Soglia: ${data['soglia']}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _modificaProdotto(prodotto.id, data),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _aggiungiProdotto,
        child: Icon(Icons.add),
      ),
    );
  }
}
