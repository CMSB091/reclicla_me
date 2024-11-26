import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResumenGrafico extends StatefulWidget {
  final Map<String, int> resumen;

  const ResumenGrafico({Key? key, required this.resumen}) : super(key: key);

  @override
  _ResumenGraficoState createState() => _ResumenGraficoState();
}

class _ResumenGraficoState extends State<ResumenGrafico> {
  int? _selectedIndex; // Índice de la sección seleccionada

  @override
  Widget build(BuildContext context) {
    final data = widget.resumen.entries.toList();
    final total = widget.resumen.values.reduce((a, b) => a + b);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = null), // Restaura el estado al original al tocar fuera
      child: PieChart(
        PieChartData(
          startDegreeOffset: 180, // Empieza desde la parte superior
          sections: data.asMap().entries.map((entry) {
            final index = entry.key;
            final material = entry.value.key;
            final cantidad = entry.value.value;
            final porcentaje = (cantidad / total) * 100;

            return PieChartSectionData(
              color: _getColorForIndex(index),
              value: porcentaje,
              title: '${material}\n${porcentaje.toStringAsFixed(1)}%',
              titleStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035, // Texto proporcional
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              radius: _selectedIndex == index ? 180 : 160 , // Resalta la sección seleccionada
              titlePositionPercentageOffset: 0.55,
            );
          }).toList(),
          sectionsSpace: 4, // Espacio entre las secciones
          centerSpaceRadius: 20, // Espacio central pequeño
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
              if (event.isInterestedForInteractions && response != null && response.touchedSection != null) {
                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                setState(() {
                  // Alterna entre seleccionar y deseleccionar
                  _selectedIndex = (_selectedIndex == touchedIndex) ? null : touchedIndex;
                });
              } else if (response == null || response.touchedSection == null) {
                setState(() => _selectedIndex = null); // Deselecciona si no toca ninguna sección
              }
            },
          ),
        ),
      ),
    );
  }

  // Método para asignar colores dinámicos
  Color _getColorForIndex(int index) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
