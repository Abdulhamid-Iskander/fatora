class CustomerInstallment {
  final String id;
  final String invoiceId;
  final String customerName;
  final String productName; // New field
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;

  CustomerInstallment({
    required this.id,
    required this.invoiceId,
    required this.customerName,
    required this.productName,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'customer_name': customerName,
      'product_name': productName,
      'installment_number': installmentNumber,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory CustomerInstallment.fromMap(Map<String, dynamic> map) {
    return CustomerInstallment(
      id: map['id'],
      invoiceId: map['invoice_id'],
      customerName: map['customer_name'],
      productName: map['product_name'],
      installmentNumber: map['installment_number'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['due_date']),
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      isPaid: map['is_paid'] == 1,
    );
  }

  CustomerInstallment copyWith({
    String? id,
    String? invoiceId,
    String? customerName,
    String? productName,
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isPaid,
  }) {
    return CustomerInstallment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      customerName: customerName ?? this.customerName,
      productName: productName ?? this.productName,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}


