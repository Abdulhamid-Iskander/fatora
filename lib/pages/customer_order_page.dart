import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/appliance_item.dart';
import '../models/invoice.dart';
// import '../models/product.dart';
import '../models/customer_installment.dart';
import '../database_helper.dart';
import 'invoice_page.dart';
import 'product_registration_page.dart';
import 'products_display_page.dart';
import 'customer_installments_page.dart';

class CustomerOrderPage extends StatefulWidget {
  const CustomerOrderPage({Key? key}) : super(key: key);

  @override
  State<CustomerOrderPage> createState() => _CustomerOrderPageState();
}

class _CustomerOrderPageState extends State<CustomerOrderPage> {
  final List<ApplianceItem> _items = [];
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerIdNumberController = TextEditingController();
  final _customerPhoneNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _installmentsCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();

  bool _useInstallments = false;
  DateTime? _firstInstallmentDate;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerIdNumberController.dispose();
    _customerPhoneNumberController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _installmentsCountController.dispose();
    _installmentAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _items.add(
          ApplianceItem(
            name: _nameController.text,
            quantity: int.parse(_quantityController.text),
            price: double.parse(_priceController.text),
          ),
        );
        _nameController.clear();
        _quantityController.clear();
        _priceController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectFirstInstallmentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstInstallmentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _firstInstallmentDate = picked;
      });
    }
  }

  Future<void> _createInstallments(int invoiceId, String customerName) async {
    if (!_useInstallments ||
        _installmentsCountController.text.isEmpty ||
        _installmentAmountController.text.isEmpty ||
        _firstInstallmentDate == null) {
      return;
    }

    final installmentsCount = int.parse(_installmentsCountController.text);
    final installmentAmount = double.parse(_installmentAmountController.text);

    for (int i = 0; i < installmentsCount; i++) {
      final dueDate = DateTime(
        _firstInstallmentDate!.year,
        _firstInstallmentDate!.month + i,
        _firstInstallmentDate!.day,
      );
      final installment = CustomerInstallment(
        id: _uuid.v4(), // Generate a unique ID for each installment
        invoiceId: invoiceId.toString(),
        customerName: customerName,
        productName:
            _items.map((e) => e.name).join(', '), // Concatenate product names
        installmentNumber: i + 1,
        amount: installmentAmount,
        dueDate: dueDate,
      );

      await _databaseHelper.insertCustomerInstallment(installment.toMap());
    }
  }

  Future<void> _submitOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get current max invoice ID to determine if it's the first invoice
      final invoices = await _databaseHelper.getInvoices();
      final int newInvoiceId = invoices.isEmpty ? 0 : invoices.last['id'] + 1;

      final newInvoice = Invoice(
        id: newInvoiceId,
        date: DateTime.now(),
        customerName: _customerNameController.text,
        customerIdNumber: _customerIdNumberController.text.isNotEmpty
            ? _customerIdNumberController.text
            : null,
        customerPhoneNumber: _customerPhoneNumberController.text.isNotEmpty
            ? _customerPhoneNumberController.text
            : null,
        items: List.from(_items),
        installmentsCount:
            _useInstallments && _installmentsCountController.text.isNotEmpty
                ? int.parse(_installmentsCountController.text)
                : null,
        installmentAmount:
            _useInstallments && _installmentAmountController.text.isNotEmpty
                ? double.parse(_installmentAmountController.text)
                : null,
        daysBetweenInstallments: null, // Not used for monthly installments
        nextInstallmentDate: _useInstallments ? _firstInstallmentDate : null,
        paidAmount: _paidAmountController.text.isNotEmpty
            ? double.parse(_paidAmountController.text)
            : null,
      );

      // Save invoice to database
      await _databaseHelper.insertInvoice({
        'id': newInvoice.id,
        'date': newInvoice.date.toIso8601String(),
        'customer_name': newInvoice.customerName,
        'customer_id_number': newInvoice.customerIdNumber,
        'customer_phone_number': newInvoice.customerPhoneNumber,
        'items':
            jsonEncode(newInvoice.items.map((item) => item.toJson()).toList()),
        'installments_count': newInvoice.installmentsCount,
        'installment_amount': newInvoice.installmentAmount,
        'days_between_installments': newInvoice.daysBetweenInstallments,
        'next_installment_date':
            newInvoice.nextInstallmentDate?.toIso8601String(),
        'paid_amount': newInvoice.paidAmount,
      });

      // Create installments if applicable
      if (_useInstallments) {
        await _createInstallments(newInvoice.id!, newInvoice.customerName);
      }

      // Update product quantities
      for (ApplianceItem item in _items) {
        await _updateProductQuantity(item.name, item.quantity);
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePage(invoice: newInvoice),
        ),
      );

      // Clear the current order
      setState(() {
        _items.clear();
        _customerNameController.clear();
        _customerIdNumberController.clear();
        _customerPhoneNumberController.clear();
        _installmentsCountController.clear();
        _installmentAmountController.clear();
        _paidAmountController.clear();
        _useInstallments = false;
        _firstInstallmentDate = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProductQuantity(
      String productName, int soldQuantity) async {
    try {
      final products = await _databaseHelper.getProducts();
      final product = products.firstWhere(
        (p) => p['name'] == productName,
        orElse: () => <String, dynamic>{},
      );

      if (product.isNotEmpty) {
        final currentQuantity = product['quantity'] as int;
        final newQuantity = currentQuantity - soldQuantity;

        if (newQuantity >= 0) {
          await _databaseHelper.updateProduct({
            ...product,
            'quantity': newQuantity,
          });
        }
      }
    } catch (e) {
      print('Error updating product quantity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        title: const Text('Hussein TECNO - New Order',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InvoicePage()),
              );
            },
            tooltip: 'View Invoices',
          ),
          IconButton(
            icon: const Icon(Icons.schedule, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustomerInstallmentsPage()),
              );
            },
            tooltip: 'Customer Installments',
          ),
          IconButton(
            icon: const Icon(Icons.add_business, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductRegistrationPage()),
              );
            },
            tooltip: 'Register New Product',
          ),
          IconButton(
            icon: const Icon(Icons.inventory, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductsDisplayPage()),
              );
            },
            tooltip: 'View Products',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerIdNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Customer ID Number',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerPhoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Item to Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: Icon(Icons.kitchen),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) <= 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                if (double.tryParse(value) == null ||
                                    double.parse(value) <= 0) {
                                  return 'Please enter a valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_shopping_cart,
                              color: Colors.brown),
                          label: const Text('Add Item',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.brown)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _items.isEmpty
                  ? const Center(
                      child: Text('No items added yet'),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                                '${item.quantity} x ${item.price.toStringAsFixed(2)} EGP = ${item.total.toStringAsFixed(2)} EGP'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeItem(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_items.fold(0.0, (sum, item) => sum + item.total).toStringAsFixed(2)} EGP',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Installments'),
              value: _useInstallments,
              onChanged: (bool value) {
                setState(() {
                  _useInstallments = value;
                });
              },
            ),
            if (_useInstallments)
              Column(
                children: [
                  TextFormField(
                    controller: _installmentsCountController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Installments',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _installmentAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount per Installment',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(
                      _firstInstallmentDate == null
                          ? 'Select First Installment Date'
                          : 'First Installment Date: ${DateFormat('dd/MM/yyyy').format(_firstInstallmentDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectFirstInstallmentDate(context),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _paidAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount (Optional)',
                      prefixIcon: Icon(Icons.money_off),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(Icons.check_circle, color: Colors.brown),
              label: const Text(
                'Submit Order',
                style: TextStyle(fontSize: 18, color: Colors.brown),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
