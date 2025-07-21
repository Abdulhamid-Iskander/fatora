import 'appliance_item.dart';

class Invoice {
  final int? id; // Change to nullable int
  final DateTime date;
  final String customerName;
  final String? customerIdNumber;
  final String? customerPhoneNumber;
  final List<ApplianceItem> items;
  final int? installmentsCount;
  final double? installmentAmount;
  final int? daysBetweenInstallments;
  final DateTime? nextInstallmentDate;
  final double? paidAmount;

  Invoice({
    this.id, // Make it optional
    required this.date, 
    required this.customerName,
    this.customerIdNumber,
    this.customerPhoneNumber,
    required this.items,
    this.installmentsCount,
    this.installmentAmount,
    this.daysBetweenInstallments,
    this.nextInstallmentDate,
    this.paidAmount,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);
  
  double get remainingAmount {
    if (installmentsCount == null || installmentAmount == null) {
      return total - (paidAmount ?? 0);
    }
    return (installmentsCount! * installmentAmount!) - (paidAmount ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'customer_id_number': customerIdNumber,
      'customer_phone_number': customerPhoneNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'installments_count': installmentsCount,
      'installment_amount': installmentAmount,
      'days_between_installments': daysBetweenInstallments,
      'next_installment_date': nextInstallmentDate?.toIso8601String(),
      'paid_amount': paidAmount,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      date: DateTime.parse(json['date']),
      customerName: json['customer_name'] ?? '',
      customerIdNumber: json['customer_id_number'],
      customerPhoneNumber: json['customer_phone_number'],
      items: (json['items'] as List)
          .map((item) => ApplianceItem.fromJson(item))
          .toList(),
      installmentsCount: json['installments_count'],
      installmentAmount: json['installment_amount'],
      daysBetweenInstallments: json['days_between_installments'],
      nextInstallmentDate: json['next_installment_date'] != null 
          ? DateTime.parse(json['next_installment_date'])
          : null,
      paidAmount: json['paid_amount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'customer_id_number': customerIdNumber,
      'customer_phone_number': customerPhoneNumber,
      'items': items.map((item) => item.toJson()).toString(),
      'installments_count': installmentsCount,
      'installment_amount': installmentAmount,
      'days_between_installments': daysBetweenInstallments,
      'next_installment_date': nextInstallmentDate?.toIso8601String(),
      'paid_amount': paidAmount,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      date: DateTime.parse(map['date']),
      customerName: map['customer_name'] ?? '',
      customerIdNumber: map['customer_id_number'],
      customerPhoneNumber: map['customer_phone_number'],
      items: (map['items'] as List)
          .map((item) => ApplianceItem.fromJson(item))
          .toList(),
      installmentsCount: map['installments_count'],
      installmentAmount: map['installment_amount'],
      daysBetweenInstallments: map['days_between_installments'],
      nextInstallmentDate: map['next_installment_date'] != null 
          ? DateTime.parse(map['next_installment_date'])
          : null,
      paidAmount: map['paid_amount'],
    );
  }
}


