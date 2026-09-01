class Product {
  final String id, name, category, sku, unit;
  final double price, stock, costPrice, minStock;
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.sku = '',
    this.unit = 'pcs',
    this.costPrice = 0,
    this.minStock = 0,
  });
}

class CartItem {
  final Product product;
  final double qty;
  const CartItem({required this.product, required this.qty});
  double get subtotal => product.price * qty;
  CartItem copyWith({double? qty}) => CartItem(product: product, qty: qty ?? this.qty);
}
