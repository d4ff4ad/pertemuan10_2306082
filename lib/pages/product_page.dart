import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<ProductModel> products = [];

  XFile? selectedImage;
  final picker = ImagePicker();
  late TextEditingController imgController;

  Future<void> pickImage(StateSetter setDialogImage) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setDialogImage(() {
        selectedImage = image;
        imgController.text = image.path;
      });
    }
  }

  Future<void> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> productList = prefs.getStringList('products') ?? [];
    setState(() {
      products = productList
          .map((item) => ProductModel.fromJson(item))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> productList = products.map((item) => item.toJson()).toList();
    await prefs.setStringList('products', productList);
  }

  Future<void> addProduct(ProductModel product) async {
    setState(() {
      products.add(product);
    });
    await saveProducts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Produk berhasil ditambahkan"),
      ),
    );
  }

  Future<void> updateProduct(int index, ProductModel product) async {
    setState(() {
      products[index] = product;
    });
    await saveProducts();
  }

  Future<void> deleteProduct(int index) async {
    setState(() {
      products.removeAt(index);
    });
    await saveProducts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Produk berhasil dihapus"),
      ),
    );
  }

  Future<String> convertImageToBase64(XFile image) async {
    Uint8List bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  void showForm({ProductModel? product, int? index}) {
    final formKey = GlobalKey<FormState>();
    
    selectedImage = null;
    imgController = TextEditingController(
      text: product?.image ?? "",
    );

    TextEditingController nameController = TextEditingController(
      text: product?.name ?? "",
    );
    TextEditingController descController = TextEditingController(
      text: product?.desc ?? "",
    );
    TextEditingController priceController = TextEditingController(
      text: product?.price.toString() ?? "",
    );

    Widget buildPreviewImage() {
      // 1. Jika ada gambar baru yang sedang dipilih dari galeri
      if (selectedImage != null) {
        return FutureBuilder<Uint8List>(
          future: selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            // 2. Tampilkan loader jika data gambar belum siap
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            
            // Tampilkan preview gambar baru yang dipilih
            return Image.memory(
              snapshot.data!,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              
            );
          },
        );
      }
      
      // 3. Jika tidak ada gambar baru, cek apakah produk ini sudah punya gambar sebelumnya
      if (product?.image.isNotEmpty ?? false) {
        return Image.memory(
          base64Decode(product!.image),
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
      
      // Jika benar-benar tidak ada gambar sama sekali
      return const SizedBox.shrink();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product == null ? "Tambah" : "Edit Produk"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nama"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nama tidak boleh kosong";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: "Deskripsi"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Deskripsi tidak boleh kosong";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: "Harga"),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Harga tidak boleh kosong";
                      }
                      final price = int.tryParse(value);
                      if (price == null || price <= 0) {
                        return "Harga harus berupa angka lebih dari 0";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => pickImage(setState),
                    icon: const Icon(Icons.image),
                    label: const Text("Pilih Gambar"),
                  ),
                  buildPreviewImage(),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    String imageBase64 = product?.image ?? "";
                    if (selectedImage != null) {
                      imageBase64 = await convertImageToBase64(selectedImage!);
                    }

                    final newProduct = ProductModel(
                      name: nameController.text,
                      desc: descController.text,
                      price: int.parse(priceController.text),
                      image: imageBase64,
                    );
                    if (product == null) {
                      addProduct(newProduct);
                    } else {
                      updateProduct(index!, newProduct);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  product == null ? "Simpan" : "Perbaharui"
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produk", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showForm(),
                    child: const Text("Tambah Produk"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text("Belum ada produk"))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onDelete: () => deleteProduct(index),
                          onEdit: () => showForm(product: product, index: index),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(product: product),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}