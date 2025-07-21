import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer_installment.dart';
import '../database_helper.dart';

class CustomerInstallmentsPage extends StatefulWidget {
  const CustomerInstallmentsPage({Key? key}) : super(key: key);

  @override
  State<CustomerInstallmentsPage> createState() =>
      _CustomerInstallmentsPageState();
}

class _CustomerInstallmentsPageState extends State<CustomerInstallmentsPage> {
  List<CustomerInstallment> _installments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, paid, overdue
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  Future<void> _loadInstallments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final installmentsData = await _databaseHelper.getCustomerInstallments();
      final loadedInstallments = installmentsData.map((installmentMap) {
        return CustomerInstallment.fromMap(installmentMap);
      }).toList();

      setState(() {
        _installments = loadedInstallments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading installments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CustomerInstallment> get _filteredInstallments {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'pending':
        return _installments
            .where((installment) => !installment.isPaid)
            .toList();
      case 'paid':
        return _installments
            .where((installment) => installment.isPaid)
            .toList();
      case 'overdue':
        return _installments
            .where((installment) =>
                !installment.isPaid && installment.dueDate.isBefore(now))
            .toList();
      default:
        return _installments;
    }
  }

  Future<void> _markAsPaid(CustomerInstallment installment) async {
    try {
      await _databaseHelper.markInstallmentAsPaid(
          installment.id, DateTime.now());
      await _loadInstallments(); // Reload the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Installment marked as paid!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating installment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInstallmentDetails(CustomerInstallment installment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Installment #${installment.installmentNumber}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Customer', installment.customerName),
                _buildDetailRow(
                    'Product', installment.productName), // Display product name
                _buildDetailRow('Invoice ID', installment.invoiceId),
                _buildDetailRow(
                    'Installment Number', '${installment.installmentNumber}'),
                _buildDetailRow(
                    'Amount', '${installment.amount.toStringAsFixed(2)} EGP'),
                _buildDetailRow('Due Date',
                    DateFormat('dd/MM/yyyy').format(installment.dueDate)),
                _buildDetailRow(
                    'Status', installment.isPaid ? 'Paid' : 'Pending'),
                if (installment.isPaid && installment.paidDate != null)
                  _buildDetailRow('Paid Date',
                      DateFormat('dd/MM/yyyy').format(installment.paidDate!)),
              ],
            ),
          ),
          actions: [
            if (!installment.isPaid)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markAsPaid(installment);
                },
                child: const Text('Mark as Paid',
                    style: TextStyle(color: Colors.green)),
              ),
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

  Color _getInstallmentColor(CustomerInstallment installment) {
    if (installment.isPaid) return Colors.green;

    final now = DateTime.now();
    if (installment.dueDate.isBefore(now)) return Colors.red; // Overdue
    if (installment.dueDate.difference(now).inDays <= 7)
      return Colors.orange; // Due soon

    return Colors.blue; // Normal
  }

  IconData _getInstallmentIcon(CustomerInstallment installment) {
    if (installment.isPaid) return Icons.check_circle;

    final now = DateTime.now();
    if (installment.dueDate.isBefore(now)) return Icons.warning; // Overdue
    if (installment.dueDate.difference(now).inDays <= 7)
      return Icons.schedule; // Due soon

    return Icons.pending; // Normal
  }

  @override
  Widget build(BuildContext context) {
    final filteredInstallments = _filteredInstallments;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513), // Brown color
        title: const Text('Customer Installments',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstallments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('All (${_installments.length})'),
                          selected: _selectedFilter == 'all',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'all';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                              'Pending (${_installments.where((i) => !i.isPaid).length})'),
                          selected: _selectedFilter == 'pending',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'pending';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                              'Paid (${_installments.where((i) => i.isPaid).length})'),
                          selected: _selectedFilter == 'paid',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'paid';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                              'Overdue (${_installments.where((i) => !i.isPaid && i.dueDate.isBefore(DateTime.now())).length})'),
                          selected: _selectedFilter == 'overdue',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'overdue';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Statistics card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_installments.fold(0.0, (sum, installment) => sum + installment.amount).toStringAsFixed(2)} EGP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Paid Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_installments.where((i) => i.isPaid).fold(0.0, (sum, installment) => sum + installment.amount).toStringAsFixed(2)} EGP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Pending Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_installments.where((i) => !i.isPaid).fold(0.0, (sum, installment) => sum + installment.amount).toStringAsFixed(2)} EGP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Installments list
                Expanded(
                  child: filteredInstallments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No installments found',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredInstallments.length,
                          itemBuilder: (context, index) {
                            final installment = filteredInstallments[index];
                            final color = _getInstallmentColor(installment);
                            final icon = _getInstallmentIcon(installment);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color,
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  '${installment.customerName} - ${installment.productName} - Installment #${installment.installmentNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Amount: ${installment.amount.toStringAsFixed(2)} EGP'),
                                    Text(
                                        'Due: ${DateFormat('dd/MM/yyyy').format(installment.dueDate)}'),
                                    Text(
                                      'Status: ${installment.isPaid ? 'Paid' : 'Pending'}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!installment.isPaid)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.payment,
                                          color: Colors.green,
                                        ),
                                        onPressed: () =>
                                            _markAsPaid(installment),
                                        tooltip: 'Mark as Paid',
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _editInstallment(installment),
                                      tooltip: 'Edit Installment',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteInstallment(installment.id),
                                      tooltip: 'Delete Installment',
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _showInstallmentDetails(installment),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _editInstallment(CustomerInstallment installment) {
    final _editAmountController =
        TextEditingController(text: installment.amount.toString());
    final _editDueDateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(installment.dueDate));
    DateTime _editedDueDate = installment.dueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Installment #${installment.installmentNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _editAmountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _editedDueDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365 * 5)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    _editedDueDate = picked;
                    _editDueDateController.text =
                        DateFormat('dd/MM/yyyy').format(_editedDueDate);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(_editDueDateController.text),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedInstallment = installment.copyWith(
                  amount: double.parse(_editAmountController.text),
                  dueDate: _editedDueDate,
                );
                try {
                  await _databaseHelper
                      .updateCustomerInstallment(updatedInstallment.toMap());
                  await _loadInstallments();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Installment updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating installment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteInstallment(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Installment'),
          content:
              const Text('Are you sure you want to delete this installment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Assuming you have a delete method in your DatabaseHelper
                  // For now, let's just remove it from the list
                  // You'll need to implement actual database deletion
                  // await _databaseHelper.deleteCustomerInstallment(id);
                  _installments.removeWhere((element) => element.id == id);
                  await _loadInstallments(); // Reload from database after actual deletion
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Installment deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting installment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
