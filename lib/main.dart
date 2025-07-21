import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '/pages/customer_order_page.dart';
import '/pages/invoice_page.dart';
import '/pages/product_registration_page.dart';
import '/pages/products_display_page.dart';
import '/pages/customer_installments_page.dart';
import '/pages/product_installments_page.dart';
import '/pages/product_purchase_invoice_page.dart';

void main() {
  // Initialize sqflite for desktop platforms
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hussein TECNO',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CustomerOrderPage(),
      routes: {
        '/invoice': (context) => const InvoicePage(),
        '/product_registration': (context) => const ProductRegistrationPage(),
        '/products_display': (context) => const ProductsDisplayPage(),
        '/customer_installments': (context) => const CustomerInstallmentsPage(),
        '/product_installments': (context) => const ProductInstallmentsPage(),
        '/product_purchase_invoices': (context) =>
            const ProductPurchaseInvoicePage(), // New route
      },
    );
  }
}
