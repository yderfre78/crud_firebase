import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:productos_app/models/models.dart';

class ProductsService extends ChangeNotifier {
  final String _baseUrl = 'flutter-products-dda75-default-rtdb.firebaseio.com';

  final List<Product> products = [];
  late Product selectedProduct;
  final storage = new FlutterSecureStorage();
  File? newPictureFile;

  bool isLoading = true;
  bool isSvaving = false;

  ProductsService() {
    this.loadProducts();
  }

  Future<List<Product>> loadProducts() async {
    this.isLoading = true;
    notifyListeners();
    final url = Uri.https(
      _baseUrl,
      'products.json',
      {'auth': await storage.read(key: 'token') ?? ''},
    );
    final res = await http.get(url);
    final Map<String, dynamic> productsMap = json.decode(res.body);
    productsMap.forEach((key, value) {
      final tempProduct = Product.fromMap(value);
      tempProduct.id = key;
      this.products.add(tempProduct);
    });
    this.isLoading = false;
    notifyListeners();

    return this.products;
  }

  Future saverOrCreateProduct(Product product) async {
    isSvaving = true;
    notifyListeners();

    if (product.id == null) {
      await this.creatProduct(product);
    } else {
      await this.updateProduct(product);
    }

    isSvaving = false;
    notifyListeners();
  }

  Future<String> updateProduct(Product product) async {
    final url = Uri.https(
      _baseUrl,
      'products/${product.id}.json',
      {'auth': await storage.read(key: 'token') ?? ''},
    );
    final resp = await http.put(
      url,
      body: product.toJson(),
    );
    final decodeData = resp.body;

    final index =
        this.products.indexWhere((element) => element.id == product.id);
    this.products[index] = product;

    return product.id!;
  }

  Future<String> creatProduct(Product product) async {
    final url = Uri.https(
      _baseUrl,
      'products.json',
      {'auth': await storage.read(key: 'token') ?? ''},
    );
    final resp = await http.post(url, body: product.toJson());
    final decodeData = json.decode(resp.body);
    print(decodeData);
    product.id = decodeData['name'];
    this.products.add(product);

    return product.id!;
  }

  void updateeSelectedProductImage(String path) {
    this.selectedProduct.picture = path;
    this.newPictureFile = File.fromUri(
      Uri(path: path),
    );
    notifyListeners();
  }

  Future<String?> uploadImage() async {
    if (this.newPictureFile == null) return null;
    this.isSvaving = true;
    notifyListeners();
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/dmw5mgxxf/image/upload?upload_preset=rn5aosmf');
    final imageUpLoadRequest = http.MultipartRequest('POST', url);

    final file =
        await http.MultipartFile.fromPath('file', newPictureFile!.path);
    imageUpLoadRequest.files.add(file);

    final streamResponse = await imageUpLoadRequest.send();
    final resp = await http.Response.fromStream(streamResponse);

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      print('Algo salio mal');
      print(resp.body);
      return null;
    }
    this.newPictureFile = null;
    final decodeData = json.decode(resp.body);
    return decodeData['secure_url'];
  }
}
