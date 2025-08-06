import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/fornitore.dart';
import '../../presentation/providers/supplier_provider.dart';
import '../../presentation/providers/product_provider.dart';
import '../widgets/fornitore_dialog.dart';
import '../widgets/main_button.dart';
import '../widgets/product_card.dart';

class OrdineRapidoPage extends StatefulWidget {
  const OrdineRapidoPage({super.key});

  @override
  State<OrdineRapidoPage> createState() => _OrdineRapidoPageState();
}

class _OrdineRapidoPageState extends State<OrdineRapidoPage> {
  String? _selectedFornitoreId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fornitoreProvider = Provider.of<SupplierProvider>(
      context,
      listen: false,
    );
    if (_selectedFornitoreId == null &&
        fornitoreProvider.suppliers.isNotEmpty) {
      _selectedFornitoreId = fornitoreProvider.suppliers.first.id;
    }
  }

  void _inviaOrdineWhatsapp(
    List<Map<String, dynamic>> prodottiDaOrdinare,
    Fornitore? fornitore,
  ) async {
    if (prodottiDaOrdinare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessun prodotto da ordinare")),
      );
      return;
    }
    if (fornitore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleziona un fornitore valido")),
      );
      return;
    }

    String numero = fornitore.numero;
    final prefisso = '+39';
    if (!numero.startsWith(prefisso)) {
      numero = prefisso + numero;
    }

    String messaggio = Uri.encodeComponent(
      "📦 Ordine: \n${prodottiDaOrdinare.map((p) => "- ${p['nome']} x ${(p['soglia'] as int) * 2}").join("\n")}\n📅 Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\nOrdine fatto con l'app Invory ✅.",
    );

    final url = Uri.parse("https://wa.me/$numero?text=$messaggio");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nell'apertura di WhatsApp")),
      );
    }
  }

  void _showEditFornitoreDialog(Fornitore fornitore) {
    final nomeController = TextEditingController(text: fornitore.nome);
    final numeroController = TextEditingController(text: fornitore.numero);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Modifica Fornitore"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: "Nome fornitore",
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? "Inserisci un nome valido"
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numeroController,
                  decoration: const InputDecoration(
                    labelText: "Numero WhatsApp",
                  ),
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) =>
                          value == null ||
                                  value.trim().isEmpty ||
                                  value.length < 9
                              ? "Numero non valido"
                              : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final updatedFornitore = Fornitore(
                  id: fornitore.id,
                  nome: nomeController.text.trim(),
                  numero: numeroController.text.trim(),
                );
                await Provider.of<SupplierProvider>(
                  context,
                  listen: false,
                ).updateSupplier(updatedFornitore);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fornitore aggiornato!")),
                );
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  void _rimuoviFornitore(String fornitoreId) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Conferma eliminazione"),
            content: const Text("Vuoi davvero eliminare questo fornitore?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annulla"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Elimina"),
              ),
            ],
          ),
    );

    if (conferma == true) {
      await Provider.of<SupplierProvider>(
        context,
        listen: false,
      ).deleteSupplier(fornitoreId);
      if (_selectedFornitoreId == fornitoreId) {
        setState(() {
          _selectedFornitoreId = null;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fornitore eliminato!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    String dataOggi = DateFormat('d MMMM yyyy', 'it_IT').format(DateTime.now());
    final fornitoreProvider = Provider.of<SupplierProvider>(context);
    final fornitori = fornitoreProvider.suppliers;

    // Assicura che _selectedFornitoreId sia valido
    if (_selectedFornitoreId != null &&
        !fornitori.any((f) => f.id == _selectedFornitoreId)) {
      _selectedFornitoreId = fornitori.isNotEmpty ? fornitori.first.id : null;
    } else if (_selectedFornitoreId == null && fornitori.isNotEmpty) {
      _selectedFornitoreId = fornitori.first.id;
    }

    final fornitoreSelezionato =
        _selectedFornitoreId != null
            ? fornitori.firstWhere((f) => f.id == _selectedFornitoreId)
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.send_outlined, color: Color(0xFF009688), size: 28),
            const SizedBox(width: 10),
            const Text(
              'Ordine Rapido',
              style: TextStyle(
                color: Color(0xFF009688),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              dataOggi,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            fornitoreProvider.loading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFornitoreId,
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(24),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF009688),
                                      fontSize: 16,
                                    ),
                                    items:
                                        fornitori.map((fornitore) {
                                          return DropdownMenuItem<String>(
                                            value: fornitore.id,
                                            child: Row(
                                              children: [
                                                Text(fornitore.nome),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _showEditFornitoreDialog(
                                                            fornitore,
                                                          ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed:
                                                      () => _rimuoviFornitore(
                                                        fornitore.id,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (nuovoId) {
                                      if (nuovoId != null) {
                                        setState(() {
                                          _selectedFornitoreId = nuovoId;
                                        });
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF009688),
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => FornitoreDialog(
                                  onSave: (nome, numero) async {
                                    await fornitoreProvider.addSupplier(
                                      nome,
                                      numero,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Fornitore aggiunto con successo",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.teal),
                        label: const Text(
                          "Aggiungi fornitore",
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    fornitoreSelezionato != null
                        ? "Numero: ${fornitoreSelezionato.numero}"
                        : "Nessun fornitore selezionato",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    final prodottiDaOrdinare =
                        productProvider.prodotti
                            .where(
                              (p) => p.quantita == 0 || p.quantita < p.soglia,
                            )
                            .toList();

                    if (productProvider.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (prodottiDaOrdinare.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.teal.shade100,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nessun prodotto da ordinare',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: prodottiDaOrdinare.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      padding: const EdgeInsets.only(bottom: 160),
                      itemBuilder: (context, index) {
                        final prodotto = prodottiDaOrdinare[index];
                        return ProductCard(
                          nome: prodotto.nome,
                          quantita: prodotto.quantita,
                          soglia: prodotto.soglia,
                          suggerita: prodotto.soglia * 2,
                          onEdit: null,
                          onDelete: null,
                          onIncrement: null,
                          onDecrement: null,
                          showEditDelete: false,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 100,
            child: SafeArea(
              bottom: true,
              child: MainButton(
                label: "Genera ordine WhatsApp",
                icon: Icons.send,
                color: Colors.green,
                onPressed: () {
                  final productProvider = Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  );
                  final prodottiDaOrdinare =
                      productProvider.prodotti
                          .where(
                            (p) => p.quantita == 0 || p.quantita < p.soglia,
                          )
                          .toList();

                  _inviaOrdineWhatsapp(
                    prodottiDaOrdinare
                        .map(
                          (p) => {
                            'nome': p.nome,
                            'quantita': p.quantita,
                            'soglia': p.soglia,
                          },
                        )
                        .toList(),
                    fornitoreSelezionato,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
