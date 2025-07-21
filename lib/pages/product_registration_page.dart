import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../database_helper.dart';

class ProductRegistrationPage extends StatefulWidget {
  final Product? productToEdit;

  const ProductRegistrationPage({Key? key, this.productToEdit})
      : super(key: key);

  @override
  State<ProductRegistrationPage> createState() =>
      _ProductRegistrationPageState();
}

class _ProductRegistrationPageState extends State<ProductRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _priceController =
      TextEditingController(); // This will be for total price
  final _unitPriceController =
      TextEditingController(); // New controller for unit price
  final _paidToManufacturerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _installmentsCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _firstInstallmentDate;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _nameController.text = widget.productToEdit!.name;
      _manufacturerController.text = widget.productToEdit!.manufacturer;
      _priceController.text = widget.productToEdit!.price.toString();
      _unitPriceController.text = widget.productToEdit!.unitPrice?.toString() ??
          ''; // Populate unit price
      _selectedDate = widget.productToEdit!.purchaseDate;
      _paidToManufacturerController.text =
          widget.productToEdit!.paidToManufacturer.toString();
      _quantityController.text = widget.productToEdit!.quantity.toString();
      _notesController.text = widget.productToEdit!.notes ?? '';
      _installmentsCountController.text =
          widget.productToEdit!.installmentsCount?.toString() ?? '';
      _installmentAmountController.text =
          widget.productToEdit!.installmentAmount?.toString() ?? '';
      _firstInstallmentDate = widget.productToEdit!.nextInstallmentDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _priceController.dispose();
    _unitPriceController.dispose(); // Dispose new controller
    _paidToManufacturerController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _installmentsCountController.dispose();
    _installmentAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.productToEdit?.id ?? _uuid.v4(), // Use UUID for new products
        name: _nameController.text,
        manufacturer: _manufacturerController.text,
        price: double.parse(_priceController.text), // Total price
        unitPrice: _unitPriceController.text.isEmpty
            ? null
            : double.parse(_unitPriceController.text), // Optional unit price
        purchaseDate: _selectedDate,
        paidToManufacturer: double.parse(_paidToManufacturerController.text),
        quantity: int.parse(_quantityController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        installmentsCount: _installmentsCountController.text.isEmpty
            ? null
            : int.parse(_installmentsCountController.text),
        installmentAmount: _installmentAmountController.text.isEmpty
            ? null
            : double.parse(_installmentAmountController.text),
        daysBetweenInstallments: null, // Not used for monthly installments
        nextInstallmentDate: _firstInstallmentDate,
      );

      try {
        if (widget.productToEdit == null) {
          await _databaseHelper.insertProduct(product.toMap());
        } else {
          await _databaseHelper.updateProduct(product.toMap());
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productToEdit == null
                ? 'Product saved successfully!'
                : 'Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form for new product registration
        if (widget.productToEdit == null) {
          _formKey.currentState!.reset();
          _nameController.clear();
          _manufacturerController.clear();
          _priceController.clear();
          _unitPriceController.clear(); // Clear unit price
          _paidToManufacturerController.clear();
          _quantityController.clear();
          _notesController.clear();
          _installmentsCountController.clear();
          _installmentAmountController.clear();
          setState(() {
            _selectedDate = DateTime.now();
            _firstInstallmentDate = null;
          });
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        title: Text(
          widget.productToEdit == null
              ? 'Register New Product'
              : 'Edit Product',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                        'Basic Information (Required)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          prefixIcon: Icon(Icons.kitchen),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer Name',
                          prefixIcon: Icon(Icons.factory),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter manufacturer name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Total Price (for all quantity)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total price';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Please enter a valid total price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price (Optional)',
                          prefixIcon: Icon(Icons.money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Please enter a valid unit price';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paidToManufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Paid to Manufacturer',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount paid to manufacturer';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) < 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Installment Information (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _installmentsCountController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Installments',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Please enter a valid number of installments';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _installmentAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Installment Amount',
                          prefixIcon: Icon(Icons.money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Please enter a valid installment amount';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectFirstInstallmentDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'First Installment Date',
                            prefixIcon: Icon(Icons.event),
                          ),
                          child: Text(
                            _firstInstallmentDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(_firstInstallmentDate!)
                                : 'Select date',
                          ),
                        ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: const Icon(Icons.save),
                  label: Text(widget.productToEdit == null
                      ? 'Register Product'
                      : 'Update Product'),
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
    );
  }
}
