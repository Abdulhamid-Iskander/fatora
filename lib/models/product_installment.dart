class ProductInstallment {
  final String id;
  final String productId;
  final String productName;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;

  ProductInstallment({
    required this.id,
    required this.productId,
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
      'product_id': productId,
      'product_name': productName,
      'installment_number': installmentNumber,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory ProductInstallment.fromMap(Map<String, dynamic> map) {
    return ProductInstallment(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'],
      installmentNumber: map['installment_number'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['due_date']),
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      isPaid: map['is_paid'] == 1,
    );
  }

  ProductInstallment copyWith({
    String? id,
    String? productId,
    String? productName,
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isPaid,
  }) {
    return ProductInstallment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}


