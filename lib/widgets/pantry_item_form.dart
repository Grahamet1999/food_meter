import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../services/barcode_lookup_service.dart';
import '../screens/barcode_scanner_screen.dart';

/// Shared form for creating or editing a [PantryItem].
///
/// Used by both the add-item and edit-item screens so the field layout,
/// validation, and unit/category pickers only need to be maintained once.
class PantryItemForm extends StatefulWidget {
  /// The item being edited, or null when adding a new item.
  final PantryItem? initial;
  final String submitLabel;
  final void Function(String name, double quantity, String unit, String category, DateTime expirationDate) onSubmit;
  /// Optional widget (e.g. a Delete button) rendered next to the submit button.
  final Widget? secondaryAction;
  /// Shows a "Scan Barcode" button that pre-fills Name/Quantity/Unit from a
  /// scanned product. Only meaningful when adding a new item.
  final bool showScanButton;

  const PantryItemForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.secondaryAction,
    this.showScanButton = false,
  });

  @override
  State<PantryItemForm> createState() => _PantryItemFormState();
}

class _PantryItemFormState extends State<PantryItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late String _name;
  late double _quantity;
  late String _unit;
  late DateTime _expirationDate;
  late String _category;
  bool _isLookingUpProduct = false;

  static const _commonUnits = ['', 'g', 'kg', 'ml', 'L', 'oz', 'lb'];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = initial?.name ?? '';
    _quantity = initial?.quantity ?? 1;
    _unit = initial?.unit ?? '';
    _expirationDate = initial?.expirationDate ?? DateTime.now().add(const Duration(days: 30));
    _category = initial?.category ?? '';
    _nameController = TextEditingController(text: _name);
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;

    setState(() => _isLookingUpProduct = true);
    final product = await BarcodeLookupService.lookup(barcode);
    if (!mounted) return;
    setState(() => _isLookingUpProduct = false);

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found — enter details manually.')),
      );
      return;
    }

    setState(() {
      _name = product.name;
      _nameController.text = product.name;
      if (product.quantity != null) {
        _quantity = product.quantity!;
        _quantityController.text = product.quantity!.toString();
      }
      if (product.unit != null) {
        _unit = product.unit!;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filled from scanned product: ${product.name}')),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        filled: true,
        fillColor: Colors.black,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          if (widget.showScanButton) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLookingUpProduct ? null : _scanBarcode,
                icon: _isLookingUpProduct
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.barcode_reader, color: Colors.white),
                label: Text(_isLookingUpProduct ? 'Looking up product…' : 'Scan Barcode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _nameController,
            cursorColor: Colors.white,
            decoration: _decoration('Name'),
            style: const TextStyle(fontSize: 18, color: Colors.white),
            validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
            onSaved: (value) => _name = value ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            cursorColor: Colors.white,
            decoration: _decoration('Quantity'),
            style: const TextStyle(fontSize: 18, color: Colors.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter a quantity';
              final num = double.tryParse(value);
              if (num == null || num <= 0) return 'Enter a valid quantity';
              return null;
            },
            onSaved: (value) => _quantity = double.tryParse(value ?? '1') ?? 1,
          ),
          const SizedBox(height: 16),
          Autocomplete<String>(
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: const TextStyle(color: Colors.white)),
                          onTap: () => onSelected(option),
                          tileColor: Colors.black,
                          hoverColor: Colors.grey[900],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return _commonUnits;
              return _commonUnits.where((unit) => unit.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text != _unit) {
                controller.text = _unit;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                cursorColor: Colors.white,
                decoration: _decoration('Unit'),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) => setState(() => _unit = value),
                onSaved: (value) => _unit = value ?? '',
              );
            },
            onSelected: (String selection) => setState(() => _unit = selection),
          ),
          const SizedBox(height: 16),
          Consumer<PantryProvider>(
            builder: (context, provider, child) {
              return StreamBuilder<List<PantryItem>>(
                stream: provider.itemsStream,
                builder: (context, snapshot) {
                  final categories = (snapshot.data ?? [])
                      .map((item) => item.category.trim())
                      .where((cat) => cat.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                  final showNewCategoryField = _category == '__new__';
                  final dropdownValue = showNewCategoryField
                      ? '__new__'
                      : (_category.isNotEmpty && categories.contains(_category.trim()) ? _category.trim() : null);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        child: DropdownButtonFormField<String>(
                          initialValue: dropdownValue,
                          items: [
                            ...categories.map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                    child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                                  ),
                                )),
                            const DropdownMenuItem(
                              value: '__new__',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                child: Text('Add new category', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ],
                          decoration: _decoration('Category'),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                          iconEnabledColor: Colors.white,
                          selectedItemBuilder: (context) {
                            return [
                              ...categories.map((cat) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, overflow: TextOverflow.visible)),
                                  )),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Add new category', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, overflow: TextOverflow.visible)),
                              ),
                            ];
                          },
                          onChanged: (value) => setState(() => _category = value ?? ''),
                          validator: (value) => (value == null || value.isEmpty) ? 'Select a category' : null,
                          onSaved: (value) {
                            if (value != '__new__') _category = value ?? '';
                          },
                        ),
                      ),
                      if (showNewCategoryField) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          cursorColor: Colors.white,
                          decoration: _decoration('New Category'),
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                          validator: (value) => value == null || value.isEmpty ? 'Enter a category' : null,
                          onSaved: (value) {
                            if (_category == '__new__') _category = value ?? '';
                          },
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expirationDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (!mounted) return;
              if (picked != null) setState(() => _expirationDate = picked);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expiration Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        Text(_expirationDate.toLocal().toString().split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.white),
                ],
              ),
            ),
          ),
          if (widget.initial == null) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Defaults to 30 days out — this isn't read from the product "
                '(barcodes and manual entry both need this checked), so update it '
                "to match what's actually printed on the package.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Tap to save this item',
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        widget.onSubmit(_name, _quantity, _unit, _category, _expirationDate);
                      }
                    },
                    child: Text(widget.submitLabel),
                  ),
                ),
              ),
              if (widget.secondaryAction != null) ...[
                const SizedBox(width: 16),
                Expanded(child: widget.secondaryAction!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
