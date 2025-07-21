class Product {
  final String id;
  final String name;
  final String manufacturer;
  final double price; // This will be the total price
  final double? unitPrice; // New optional field for unit price
  final DateTime purchaseDate;
  final double paidToManufacturer;
  final int quantity;
  final String? notes;
  final int? installmentsCount;
  final double? installmentAmount;
  final int? daysBetweenInstallments;
  final DateTime? nextInstallmentDate;

  Product({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.price,
    this.unitPrice, // Make it optional
    required this.purchaseDate,
    required this.paidToManufacturer,
    required this.quantity,
    this.notes,
    this.installmentsCount,
    this.installmentAmount,
    this.daysBetweenInstallments,
    this.nextInstallmentDate,
  });

  double get remainingAmount {
    if (installmentsCount == null || installmentAmount == null) {
      return price - paidToManufacturer;
    }
    return (installmentsCount! * installmentAmount!) - paidToManufacturer;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'price': price,
      'unit_price': unitPrice, // Add to map
      'purchase_date': purchaseDate.toIso8601String(),
      'paid_to_manufacturer': paidToManufacturer,
      'quantity': quantity,
      'notes': notes,
      'installments_count': installmentsCount,
      'installment_amount': installmentAmount,
      'days_between_installments': daysBetweenInstallments,
      'next_installment_date': nextInstallmentDate?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      manufacturer: map['manufacturer'],
      price: map['price'],
      unitPrice: map['unit_price'], // Read from map
      purchaseDate: DateTime.parse(map['purchase_date']),
      paidToManufacturer: map['paid_to_manufacturer'],
      quantity: map['quantity'],
      notes: map['notes'],
      installmentsCount: map['installments_count'],
      installmentAmount: map['installment_amount'],
      daysBetweenInstallments: map['days_between_installments'],
      nextInstallmentDate: map['next_installment_date'] != null 
          ? DateTime.parse(map['next_installment_date'])
          : null,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? manufacturer,
    double? price,
    double? unitPrice,
    DateTime? purchaseDate,
    double? paidToManufacturer,
    int? quantity,
    String? notes,
    int? installmentsCount,
    double? installmentAmount,
    int? daysBetweenInstallments,
    DateTime? nextInstallmentDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      price: price ?? this.price,
      unitPrice: unitPrice ?? this.unitPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      paidToManufacturer: paidToManufacturer ?? this.paidToManufacturer,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      daysBetweenInstallments: daysBetweenInstallments ?? this.daysBetweenInstallments,
      nextInstallmentDate: nextInstallmentDate ?? this.nextInstallmentDate,
    );
  }
}


