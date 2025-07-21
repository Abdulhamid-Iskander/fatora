import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../database_helper.dart';

class ProductPurchaseInvoicePage extends StatefulWidget {
  const ProductPurchaseInvoicePage({Key? key}) : super(key: key);

  @override
  State<ProductPurchaseInvoicePage> createState() =>
      _ProductPurchaseInvoicePageState();
}

class _ProductPurchaseInvoicePageState
    extends State<ProductPurchaseInvoicePage> {
  List<Product> _purchasedProducts = [];
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadPurchasedProducts();
  }

  Future<void> _loadPurchasedProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productsData = await _databaseHelper.getProducts();
      final loadedProducts = productsData.map((productMap) {
        return Product.fromMap(productMap);
      }).toList();

      setState(() {
        _purchasedProducts = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading purchased products: $e'),
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
        title: const Text('Hussein TECNO - Product Purchase Invoices',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchasedProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchasedProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No product purchase invoices found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _purchasedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _purchasedProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product: ${product.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Manufacturer: ${product.manufacturer}'),
                            Text(
                                'Purchase Date: ${DateFormat('dd/MM/yyyy').format(product.purchaseDate)}'),
                            Text('Quantity: ${product.quantity}'),
                            Text(
                                'Total Price: ${product.price.toStringAsFixed(2)} EGP'),
                            Text(
                                'Paid to Manufacturer: ${product.paidToManufacturer.toStringAsFixed(2)} EGP'),
                            if (product.notes != null &&
                                product.notes!.isNotEmpty)
                              Text('Notes: ${product.notes}'),
                            if (product.installmentsCount != null &&
                                product.installmentsCount! > 0) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Installment Details:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                  'Number of Installments: ${product.installmentsCount}'),
                              Text(
                                  'Amount per Installment: ${product.installmentAmount?.toStringAsFixed(2) ?? 'N/A'} EGP'),
                              Text(
                                  'Next Installment Due: ${product.nextInstallmentDate != null ? DateFormat('dd/MM/yyyy').format(product.nextInstallmentDate!) : 'N/A'}'),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
