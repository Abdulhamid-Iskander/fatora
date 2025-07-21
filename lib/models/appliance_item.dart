class ApplianceItem {
  String name;
  int quantity;
  double price;

  ApplianceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'price': price};
  }

  factory ApplianceItem.fromJson(Map<String, dynamic> json) {
    return ApplianceItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }
}

