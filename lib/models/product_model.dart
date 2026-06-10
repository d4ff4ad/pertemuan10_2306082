import 'dart:convert';






class ProductModel{
    //inisialisasi product    
    final String name;
    final String description;
    final int price;

    //constructor
    ProductModel({
        required this.name,
        required this.description,
        required this.price,
    });

    //objek to map
    Map<String, dynamic> toMap() {
        return {
            'name': name,
            'description': description,
            'price': price,
        };
    }

    //map to objek
    factory ProductModel.fromMap(
        Map<String, dynamic> map) {
        return ProductModel(
            name: map['name'] ?? "",
            description: map['description'] ?? "",
            price: map['price'] ?? 0,
        );
    }

    //OBJECT -> JSON STRING
    String toJson() => json.encode(toMap());

    //JSON STRING -> OBJECT
    factory ProductModel.fromJson(String source) {
        return ProductModel.fromMap(
            json.decode(source)
        );
    }
    
}