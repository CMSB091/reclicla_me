import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recila_me/widgets/item_detail_screen.dart';
import 'add_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artículos en Donación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddItemScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      _navigateToItemDetail(
                        context,
                        item['imageUrl'],
                        item['title'] ?? 'Sin título',
                        item['description'] ?? 'Sin descripción',
                        item['contact'] ?? 'Sin contacto',
                      );
                    },
                    child: Image.network(
                      item['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain, // Mostrar la imagen completa en la miniatura
                    ),
                  ),
                  title: Text(item['titulo'] ?? 'Sin título'), // Mostrar el título
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['description'] ?? 'Sin descripción'), // Mostrar la descripción
                      Text('Contacto: ${item['contact'] ?? 'Sin contacto'}'), // Mostrar el contacto
                    ],
                  ),
                  onTap: () {
                    _navigateToItemDetail(
                      context,
                      item['imageUrl'],
                      item['titulo'] ?? 'Sin título',
                      item['description'] ?? 'Sin descripción',
                      item['contact'] ?? 'Sin contacto',
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Función para navegar a la página de detalles del artículo
  void _navigateToItemDetail(BuildContext context, String imageUrl, String title, String description, String contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(
          imageUrl: imageUrl,
          title: title,
          description: description,
          contact: contact,
        ),
      ),
    );
  }
}