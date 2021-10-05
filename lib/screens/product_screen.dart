import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:productos_app/providers/product_form_provider.dart';
import 'package:productos_app/services/product_service.dart';
import 'package:productos_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductsService>(context);
    return ChangeNotifierProvider(
      create: (_) => ProductFormProvider(productService.selectedProduct),
      child: ProductsScreenBody(productService: productService),
    );
  }
}

class ProductsScreenBody extends StatelessWidget {
  const ProductsScreenBody({
    Key? key,
    required this.productService,
  }) : super(key: key);

  final ProductsService productService;

  @override
  Widget build(BuildContext context) {
    final productForm = Provider.of<ProductFormProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        //Para ocultar el teclado cuando se hace scroll
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Stack(
              children: [
                ProductImage(url: productService.selectedProduct.picture),
                Positioned(
                  top: 60,
                  left: 20,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final picker = new ImagePicker();
                      final PickedFile? pickedFile = await picker.getImage(
                        source: ImageSource.camera,
                        imageQuality: 100,
                      );
                      if (pickedFile == null) {
                        print('No Selecciono nada');
                        return;
                      }
                      print('Tenemos imagen ${pickedFile.path}');
                      productService
                          .updateeSelectedProductImage(pickedFile.path);
                    },
                  ),
                ),
                SizedBox(
                  height: 100,
                )
              ],
            ),
            _ProductForm(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        child: productService.isSvaving
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(
                Icons.save_outlined,
              ),
        onPressed: productService.isSvaving
            ? null
            : () async {
                if (!productForm.isValidForm()) return;
                final String? imageUrl = await productService.uploadImage();
                print(imageUrl);
                if (imageUrl != null) productForm.product.picture = imageUrl;
                await productService.saverOrCreateProduct(productForm.product);
              },
      ),
    );
  }
}

class _ProductForm extends StatelessWidget {
  const _ProductForm({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productForm = Provider.of<ProductFormProvider>(context);
    final product = productForm.product;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
        ),
        width: double.infinity,
        height: 300,
        decoration: _buildBoxDecoration(),
        child: Form(
          key: productForm.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              TextFormField(
                initialValue: product.name,
                onChanged: (value) => product.name = value,
                validator: (value) {
                  if (value == null || value.length < 1)
                    return 'El nombre es obligatorio';
                },
                decoration: InputDecoration(
                  hintText: 'Nombre del product',
                  labelText: 'Nombre',
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                initialValue: '${product.price}',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^(\d+)?\.?\d{0,2}'))
                ],
                onChanged: (value) {
                  if (double.tryParse(value) == null) {
                    product.price = 0;
                  } else {
                    product.price = double.parse(value);
                  }
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '\$150',
                  labelText: 'Precio',
                ),
              ),
              SizedBox(height: 30),
              SwitchListTile.adaptive(
                activeColor: Colors.indigo,
                value: product.available,
                title: Text('Disponible'),
                onChanged: productForm.updateAvailability,
              ),
              SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      );
}
