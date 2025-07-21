import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database_helper.dart';
import 'product_registration_page.dart';

class ProductsDisplayPage extends StatefulWidget {
  const ProductsDisplayPage({Key? key}) : super(key: key);

  @override
  State<ProductsDisplayPage> createState() => _ProductsDisplayPageState();
}

class _ProductsDisplayPageState extends State<ProductsDisplayPage> {
  List<Product> _products = [];
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productsData = await _databaseHelper.getProducts();
      final loadedProducts = productsData.map((productMap) {
        return Product.fromMap(productMap);
      }).toList();

      setState(() {
        _products = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _databaseHelper.deleteProduct(productId);
      await _loadProducts(); // Reload the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Product ID', product.id),
                _buildDetailRow('Manufacturer', product.manufacturer),
                _buildDetailRow(
                    'Price', '${product.price.toStringAsFixed(2)} EGP'),
                _buildDetailRow('Purchase Date',
                    '${product.purchaseDate.day}/${product.purchaseDate.month}/${product.purchaseDate.year}'),
                _buildDetailRow('Paid to Manufacturer',
                    '${product.paidToManufacturer.toStringAsFixed(2)} EGP'),
                _buildDetailRow('Available Quantity', '${product.quantity}'),
                _buildDetailRow('Remaining Amount',
                    '${product.remainingAmount.toStringAsFixed(2)} EGP'),
                if (product.notes != null && product.notes!.isNotEmpty)
                  _buildDetailRow('Notes', product.notes!),
                if (product.installmentsCount != null)
                  _buildDetailRow(
                      'Number of Installments', '${product.installmentsCount}'),
                if (product.installmentAmount != null)
                  _buildDetailRow('Installment Amount',
                      '${product.installmentAmount!.toStringAsFixed(2)} EGP'),
                if (product.daysBetweenInstallments != null)
                  _buildDetailRow('Days Between Installments',
                      '${product.daysBetweenInstallments}'),
                if (product.nextInstallmentDate != null)
                  _buildDetailRow('Next Installment Date',
                      '${product.nextInstallmentDate!.day}/${product.nextInstallmentDate!.month}/${product.nextInstallmentDate!.year}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getQuantityColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity <= 5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Registered Products',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No registered products found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Total Products',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_products.length}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Total Quantity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_products.fold(0, (sum, product) => sum + product.quantity)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_products.where((product) => product.quantity == 0).length}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getQuantityColor(product.quantity),
                                child: Text(
                                  '${product.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Manufacturer: ${product.manufacturer}'),
                                  Text(
                                      'Price: ${product.price.toStringAsFixed(2)} EGP'),
                                  Text(
                                    'Available Quantity: ${product.quantity}',
                                    style: TextStyle(
                                      color:
                                          _getQuantityColor(product.quantity),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (product.remainingAmount > 0)
                                    Text(
                                      'Remaining: ${product.remainingAmount.toStringAsFixed(2)} EGP',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (product.installmentsCount != null)
                                    Text(
                                      'Installments: ${product.installmentsCount} × ${product.installmentAmount?.toStringAsFixed(2) ?? '0'} EGP',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductRegistrationPage(
                                                  productToEdit: product),
                                        ),
                                      ).then((_) =>
                                          _loadProducts()); // Refresh list after editing
                                    },
                                    tooltip: 'Edit Product',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () =>
                                        _showProductDetails(product),
                                    tooltip: 'View Details',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmation(product),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                              onTap: () => _showProductDetails(product),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
