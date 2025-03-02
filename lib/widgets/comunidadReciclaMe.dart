import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recila_me/widgets/fondoDifuminado.dart';
import 'package:recila_me/clases/funciones.dart';

class ComunidadRecicladoraScreen extends StatefulWidget {
  final String userEmail;

  const ComunidadRecicladoraScreen({super.key, required this.userEmail});

  @override
  _ComunidadRecicladoraScreenState createState() =>
      _ComunidadRecicladoraScreenState();
}

class _ComunidadRecicladoraScreenState
    extends State<ComunidadRecicladoraScreen> {
  List<String> ciudades = [];
  String? selectedCiudad;
  String _selectedFilter = 'Materiales reciclados'; // Filtro inicial
  final List<String> _filters = [
    'Materiales reciclados',
    'Impacto ambiental',
    'Ciudad'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Comunidad ReciclaMe',
          style: TextStyle(fontFamily: 'Artwork', fontSize: 24),
        ),
        backgroundColor: Colors.green.shade200,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.infoCircle),
            onPressed: () {
              Funciones.mostrarModalDeAyuda(
                context: context,
                titulo: 'Ayuda',
                mensaje:
                    'Selecciona un filtro para visualizar el informe de reciclado de la comunidad.',
              );
            },
          ),
        ],
      ),
      body: BlurredBackground(
        blurStrength: 3.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        isDense: true,
                        menuMaxHeight: 250,
                        icon: Icon(FontAwesomeIcons.caretDown),
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por',
                          prefixIcon: Icon(FontAwesomeIcons.filter),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _filters.map((String filter) {
                          return DropdownMenuItem<String>(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                            if (_selectedFilter == 'Ciudad') {
                              _cargarCiudades();
                            }
                          });
                        },
                      ),
                    ),
                    if (_selectedFilter == 'Ciudad')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButtonFormField<String>(
                          isDense: true,
                          menuMaxHeight: 250,
                          icon: Icon(FontAwesomeIcons.caretDown),
                          value: selectedCiudad,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar ciudad',
                            prefixIcon: Icon(FontAwesomeIcons.city),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: ciudades.map((String ciudad) {
                            return DropdownMenuItem<String>(
                              value: ciudad,
                              child: Text(ciudad),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCiudad = newValue;
                            });
                          },
                        ),
                      ),
                    SizedBox(
                      height: constraints.maxHeight * 0.7,
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedFilter == 'Materiales reciclados') {
      return _buildMaterialesReciclados();
    } else if (_selectedFilter == 'Impacto ambiental') {
      return _buildImpactoAmbiental();
    } else if (_selectedFilter == 'Ciudad' && selectedCiudad != null) {
      return _buildCiudad();
    } else {
      return Center(child: Text('Selecciona un filtro válido.'));
    }
  }

  Widget _buildMaterialesReciclados() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuario').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar datos: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No se han encontrado usuarios registrados.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final usuarios = snapshot.data!.docs;
        return FutureBuilder<Map<String, int>>(
          future: _obtenerReciclajePorUsuario(usuarios),
          builder: (context, reciclajeSnapshot) {
            if (reciclajeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (reciclajeSnapshot.hasError) {
              return Center(
                child: Text(
                  "Error al calcular reciclaje: ${reciclajeSnapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!reciclajeSnapshot.hasData || reciclajeSnapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No hay datos de reciclaje disponibles.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }

            final reciclajePorUsuario = reciclajeSnapshot.data!;
            return ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                final email = usuario['correo'];
                final ciudad = usuario['ciudad'] ??
                    'Ciudad no especificada'; // Mostrar la ciudad
                final reciclado = reciclajePorUsuario[email] ?? 0;

                return Card(
                  color: Colors.grey.withOpacity(0.1),
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "${usuario['nombre']} ${usuario['apellido']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Ciudad: $ciudad'), // Mostrar la ciudad
                    trailing: Text(
                      '$reciclado objetos reciclados',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildImpactoAmbiental() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuario').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("Cargando datos de usuarios...");
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint("Error al cargar usuarios: ${snapshot.error}");
          return Center(
            child: Text(
              "Error al cargar datos: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint("No hay usuarios registrados.");
          return const Center(
            child: Text(
              "No se han encontrado usuarios registrados.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final usuarios = snapshot.data!.docs;
        return FutureBuilder<Map<String, double>>(
          future: _obtenerImpactoAmbientalPorUsuario(usuarios),
          builder: (context, impactoSnapshot) {
            if (impactoSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint("Calculando impacto ambiental...");
              return const Center(child: CircularProgressIndicator());
            }
            if (impactoSnapshot.hasError) {
              debugPrint(
                  "Error al calcular impacto ambiental: ${impactoSnapshot.error}");
              return Center(
                child: Text(
                  "Error al calcular impacto ambiental: ${impactoSnapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!impactoSnapshot.hasData || impactoSnapshot.data!.isEmpty) {
              debugPrint("No hay datos de impacto ambiental.");
              return const Center(
                child: Text(
                  "No hay datos de impacto ambiental disponibles.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }

            final impactoPorUsuario = impactoSnapshot.data!;
            return ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                final email = usuario['correo'];
                final ciudad = usuario['ciudad'] ?? 'Ciudad no especificada';
                final impacto = impactoPorUsuario[email] ?? 0.0;

                // Valor de referencia: 10,000 kg de CO₂ al año (huella promedio)
                const huellaReferencia = 10000.0;
                final porcentajeReduccion = (impacto / huellaReferencia) * 100;

                return Card(
                  color: Colors.grey.withOpacity(0.1),
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "${usuario['nombre']} ${usuario['apellido']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Ciudad: $ciudad'),
                    trailing: Text(
                      '${porcentajeReduccion.toStringAsFixed(2)}% reducción(estimado)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCiudad() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuario')
          .where('ciudad', isEqualTo: selectedCiudad)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar datos: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No se han encontrado personas en esta zona.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        final usuarios = snapshot.data!.docs;
        return FutureBuilder<Map<String, int>>(
          future: _obtenerReciclajePorUsuario(usuarios),
          builder: (context, reciclajeSnapshot) {
            if (reciclajeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (reciclajeSnapshot.hasError) {
              return Center(
                child: Text(
                  "Error al calcular reciclaje: ${reciclajeSnapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!reciclajeSnapshot.hasData || reciclajeSnapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No hay datos de reciclaje para esta ciudad.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }

            final reciclajePorUsuario = reciclajeSnapshot.data!;
            final totalRecicladoCiudad =
                reciclajePorUsuario.values.reduce((a, b) => a + b);

            return ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                final email = usuario['correo'];
                final reciclado = reciclajePorUsuario[email] ?? 0;
                final porcentaje = totalRecicladoCiudad > 0
                    ? (reciclado / totalRecicladoCiudad) * 100
                    : 0;

                return Card(
                  color: Colors.grey.withOpacity(0.1),
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "${usuario['nombre']} ${usuario['apellido']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Ciudad: ${usuario['ciudad']}'),
                    trailing: Text(
                      '${porcentaje.toStringAsFixed(1)}% participación',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, int>> _obtenerReciclajePorUsuario(
      List<QueryDocumentSnapshot> usuarios) async {
    final reciclajePorUsuario = <String, int>{};

    for (final usuario in usuarios) {
      final email = usuario['correo'];
      final historialSnapshot = await FirebaseFirestore.instance
          .collection('historial')
          .where('email', isEqualTo: email)
          .get();
      reciclajePorUsuario[email] = historialSnapshot.docs.length;
    }

    return reciclajePorUsuario;
  }

  Future<Map<String, double>> _obtenerImpactoAmbientalPorUsuario(
      List<QueryDocumentSnapshot> usuarios) async {
    final impactoPorUsuario = <String, double>{};

    try {
      for (final usuario in usuarios) {
        final email = usuario['correo'];
        debugPrint("Calculando impacto ambiental para el usuario: $email");

        final historialSnapshot = await FirebaseFirestore.instance
            .collection('historial')
            .where('email', isEqualTo: email)
            .get();

        if (historialSnapshot.docs.isEmpty) {
          debugPrint("No hay datos de reciclaje para el usuario: $email");
          impactoPorUsuario[email] = 0.0;
          continue;
        }

        final itemsReciclados = <String, int>{};
        for (final doc in historialSnapshot.docs) {
          final item =
              doc['item'] as String? ?? 'Desconocido'; // Usamos el campo "item"
          itemsReciclados[item] = (itemsReciclados[item] ?? 0) + 1;
        }

        final reduccionCO2 = _calcularReduccionTotal(itemsReciclados);
        impactoPorUsuario[email] = reduccionCO2;
        debugPrint("Impacto ambiental calculado para $email: $reduccionCO2 kg CO₂");
      }
    } catch (e) {
      debugPrint("Error al calcular impacto ambiental: $e");
      throw e; // Relanzamos el error para que FutureBuilder lo maneje
    }

    return impactoPorUsuario;
  }

  double _calcularReduccionTotal(Map<String, int> materiales) {
    double total = 0;
    materiales.forEach((material, cantidad) {
      final reduccionPorUnidad = _obtenerReduccionPorMaterial(material);
      total += cantidad * reduccionPorUnidad;
    });
    return total;
  }

  double _obtenerReduccionPorMaterial(String material) {
    const reducciones = {
      'Plastico': 0.5, // 0.5 kg de CO₂ por unidad
      'Vidrio': 0.8, // 0.8 kg de CO₂ por unidad
      'Aluminio':
          5.0, // 5.0 kg de CO₂ por unidad (el aluminio reciclado ahorra mucha energía)
      'Carton': 0.4, // 0.4 kg de CO₂ por unidad
      'Isopor': 0.2, // 0.2 kg de CO₂ por unidad
      'Papel': 0.3, // 0.3 kg de CO₂ por unidad
      'Residuos':
          0.1, // 0.1 kg de CO₂ por unidad (valor genérico para residuos no especificados)
      'Metal': 1.0, // 1.0 kg de CO₂ por unidad
    };
    return reducciones[material] ??
        0.0; // Si el material no está en la lista, retornamos 0.0
  }

  Future<void> _cargarCiudades() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ciudades')
          .where('pais', isEqualTo: 'Paraguay')
          .get();
      List<String> ciudadesObtenidas =
          snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
      setState(() {
        ciudades = ciudadesObtenidas;
      });
    } catch (e) {
      await Funciones.saveDebugInfo('Error al cargar ciudades: $e');
    }
  }
}
