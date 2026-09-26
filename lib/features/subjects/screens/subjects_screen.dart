import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'subject_detail_screen.dart';
import 'subject_form_screen.dart';

class Materia {
  final String nombre;
  final String profesor;
  final String iniciales;
  final double nota;

  const Materia({
    required this.nombre,
    required this.profesor,
    required this.iniciales,
    required this.nota,
  });
}

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({
    super.key,
    this.onAgregarMateria,
    this.onMateriaTap,
    this.onInicio,
    this.onCalculadora,
    this.onConfiguracion,
  });

  final VoidCallback? onAgregarMateria;
  final ValueChanged<Materia>? onMateriaTap;
  final VoidCallback? onInicio;
  final VoidCallback? onCalculadora;
  final VoidCallback? onConfiguracion;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Materia> _materias = const [
    Materia(
      nombre: 'Matemáticas',
      profesor: 'Carlos Rodríguez',
      iniciales: 'MAT',
      nota: 3.8,
    ),
    Materia(
      nombre: 'Programación',
      profesor: 'Juan Pérez',
      iniciales: 'PRO',
      nota: 4.2,
    ),
    Materia(
      nombre: 'Bases de Datos',
      profesor: 'María Gómez',
      iniciales: 'BD',
      nota: 3.2,
    ),
  ];

  String _busqueda = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _busqueda = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Materia> get _materiasFiltradas {
    if (_busqueda.isEmpty) {
      return _materias;
    }

    return _materias.where((materia) {
      return materia.nombre.toLowerCase().contains(_busqueda) ||
          materia.profesor.toLowerCase().contains(_busqueda);
    }).toList();
  }

  Color _colorNota(double nota) {
    if (nota >= 3.5) {
      return AppColors.okText;
    }

    if (nota >= 3.0) {
      return AppColors.warnText;
    }

    return AppColors.errorText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Materias'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubjectFormScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Buscador
            SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar materia',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _materiasFiltradas.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _materiasFiltradas.length,
                      itemBuilder: (context, index) {
                        final materia = _materiasFiltradas[index];

                        return _buildMateriaCard(materia);
                      },
                    ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _SubjectsBottomNavigation(
        activeIndex: 1,
        onInicio: widget.onInicio,
        onMaterias: () {},
        onCalculadora: widget.onCalculadora,
        onConfiguracion: widget.onConfiguracion,
      ),
    );
  }

  Widget _buildMateriaCard(Materia materia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(
                nombreMateria: materia.nombre,
                notaAcumulada: materia.nota,
                porcentajeEvaluado: 60,
                actividades: const [
                  Actividad(
                    nombre: 'Parcial 1',
                    porcentaje: 30,
                    nota: 3.5,
                  ),
                  Actividad(
                    nombre: 'Taller',
                    porcentaje: 20,
                    nota: 4.0,
                  ),
                  Actividad(
                    nombre: 'Quiz',
                    porcentaje: 10,
                    nota: 4.2,
                  ),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Iniciales
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  materia.iniciales,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Nombre y profesor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materia.nombre,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prof. ${materia.profesor}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Nota
              Text(
                materia.nota.toStringAsFixed(1),
                style: TextStyle(
                  color: _colorNota(materia.nota),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book,
            size: 64,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes materias registradas',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onAgregarMateria,
            child: const Text('Agregar materia'),
          ),
        ],
      ),
    );
  }
}

class _SubjectsBottomNavigation extends StatelessWidget {
  const _SubjectsBottomNavigation({
    required this.activeIndex,
    this.onInicio,
    this.onMaterias,
    this.onCalculadora,
    this.onConfiguracion,
  });

  final int activeIndex;
  final VoidCallback? onInicio;
  final VoidCallback? onMaterias;
  final VoidCallback? onCalculadora;
  final VoidCallback? onConfiguracion;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home,
            label: 'Inicio',
            active: activeIndex == 0,
            onTap: onInicio,
          ),
          _NavItem(
            icon: Icons.menu_book,
            label: 'Materias',
            active: activeIndex == 1,
            onTap: onMaterias,
          ),
          _NavItem(
            icon: Icons.calculate,
            label: 'Calculadora',
            active: activeIndex == 2,
            onTap: onCalculadora,
          ),
          _NavItem(
            icon: Icons.settings,
            label: 'Configuración',
            active: activeIndex == 3,
            onTap: onConfiguracion,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}