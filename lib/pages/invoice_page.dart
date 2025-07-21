import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/appliance_item.dart';
import '../database_helper.dart';

class InvoicePage extends StatefulWidget {
  final Invoice? invoice;

  const InvoicePage({Key? key, this.invoice}) : super(key: key);

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Invoice> _invoices = [];
  Invoice? _currentInvoice;
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoicesData = await _databaseHelper.getInvoices();
      final loadedInvoices = invoicesData.map((invoiceMap) {
        final itemsJson = jsonDecode(invoiceMap['items']);
        return Invoice(
          id: invoiceMap['id'],
          date: DateTime.parse(invoiceMap['date']),
          customerName: invoiceMap['customer_name'] ?? '',
          customerIdNumber: invoiceMap['customer_id_number'],
          customerPhoneNumber: invoiceMap['customer_phone_number'],
          items: (itemsJson as List)
              .map((item) => ApplianceItem.fromJson(item))
              .toList(),
          installmentsCount: invoiceMap['installments_count'],
          installmentAmount: invoiceMap['installment_amount'],
          daysBetweenInstallments: invoiceMap['days_between_installments'],
          nextInstallmentDate: invoiceMap['next_installment_date'] != null
              ? DateTime.parse(invoiceMap['next_installment_date'])
              : null,
          paidAmount: invoiceMap['paid_amount'],
        );
      }).toList();

      setState(() {
        _invoices = loadedInvoices;
        _isLoading = false;

        // If no current invoice is set but we have invoices, show the most recent one
        if (_currentInvoice == null && loadedInvoices.isNotEmpty) {
          _currentInvoice = loadedInvoices.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoices: $e'),
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
        title: const Text('Hussein TECNO - Invoices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(
                  child: Text(
                    'No invoices found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Row(
                  children: [
                    // Invoice list sidebar
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: Container(
                        color: Colors.brown[100],
                        child: ListView.builder(
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _invoices[index];
                            final isSelected =
                                _currentInvoice?.id == invoice.id;

                            return Container(
                              color: isSelected ? Colors.brown[300] : null,
                              child: ListTile(
                                title: Text(
                                  'Invoice #${invoice.id! - 1}', // Display 0-based ID
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer: ${invoice.customerName}'),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(invoice.date),
                                    ),
                                    Text(
                                      '${invoice.total.toStringAsFixed(2)} EGP',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    if (invoice.installmentsCount != null)
                                      Text(
                                        'Installments: ${invoice.installmentsCount}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _currentInvoice = invoice;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Invoice details
                    Expanded(
                      child: _currentInvoice == null
                          ? const Center(
                              child: Text(
                                'Select an invoice to view details',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Card(
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Invoice #${_currentInvoice!.id! - 1}', // Display 0-based ID
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(
                                                    _currentInvoice!.date),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Customer: ${_currentInvoice!.customerName}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          if (_currentInvoice!
                                                      .customerIdNumber !=
                                                  null &&
                                              _currentInvoice!
                                                  .customerIdNumber!.isNotEmpty)
                                            Text(
                                              'ID Number: ${_currentInvoice!.customerIdNumber}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          if (_currentInvoice!
                                                      .customerPhoneNumber !=
                                                  null &&
                                              _currentInvoice!
                                                  .customerPhoneNumber!
                                                  .isNotEmpty)
                                            Text(
                                              'Phone Number: ${_currentInvoice!.customerPhoneNumber}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          Text(
                                            'Time: ${DateFormat('HH:mm').format(_currentInvoice!.date)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Items:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_currentInvoice!.items.map((item) => Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: ListTile(
                                          title: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Quantity: ${item.quantity} × ${item.price.toStringAsFixed(2)} EGP',
                                          ),
                                          trailing: Text(
                                            '${item.total.toStringAsFixed(2)} EGP',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ))),
                                  const SizedBox(height: 16),
                                  Card(
                                    elevation: 4,
                                    color: Colors.green[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total:',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${_currentInvoice!.total.toStringAsFixed(2)} EGP',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_currentInvoice!.paidAmount !=
                                              null) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Paid Amount:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${_currentInvoice!.paidAmount!.toStringAsFixed(2)} EGP',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Remaining:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${_currentInvoice!.remainingAmount.toStringAsFixed(2)} EGP',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (_currentInvoice!
                                                      .installmentsCount !=
                                                  null &&
                                              _currentInvoice!
                                                      .installmentsCount! >
                                                  0) ...[
                                            const SizedBox(height: 16),
                                            const Divider(),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Installment Details:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                                'Number of Installments: ${_currentInvoice!.installmentsCount}'),
                                            Text(
                                                'Amount per Installment: ${_currentInvoice!.installmentAmount?.toStringAsFixed(2) ?? 'N/A'} EGP'),
                                            Text(
                                                'First Installment Due: ${DateFormat('dd/MM/yyyy').format(_currentInvoice!.nextInstallmentDate!)}'),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
