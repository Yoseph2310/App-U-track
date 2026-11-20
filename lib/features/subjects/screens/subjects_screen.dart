import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../tasks/services/subject_service.dart';
import 'subject_detail_screen.dart';
import 'subject_form_screen.dart';
import '../../tasks/services/grade_service.dart';

class Materia {
  final String id;
  final String nombre;
  final String profesor;
  final String iniciales;
  final double nota;
  final List<Map<String, dynamic>> esquemaEvaluacion;

  const Materia({
    required this.id,
    required this.nombre,
    required this.profesor,
    required this.iniciales,
    required this.nota,
    required this.esquemaEvaluacion,
  });
}

/// Copia en memoria de las materias del usuario, para que la pantalla
/// Materias se muestre al instante en vez de esperar la consulta cada vez.
class SubjectsCache {
  SubjectsCache._();

  static String? _userId;
  static List<Materia>? _materias;
  static Future<List<Materia>>? _pending;

  /// Materias guardadas del usuario, o null si aún no se han cargado.
  static List<Materia>? get(String userId) =>
      _userId == userId ? _materias : null;

  /// Precarga las materias (se llama al entrar a Inicio).
  static void preload(String userId) {
    refresh(userId).catchError((_) => <Materia>[]);
  }

  /// Consulta las materias en Firestore y actualiza la copia guardada.
  /// Si ya hay una consulta en curso, reutiliza esa.
  static Future<List<Materia>> refresh(String userId) {
    final pending = _pending;
    if (pending != null && _userId == userId) return pending;

    if (_userId != userId) _materias = null;
    _userId = userId;

    final future = _fetch(userId);
    _pending = future;
    return future.then((materias) {
      if (_userId == userId) _materias = materias;
      return materias;
    }).whenComplete(() {
      if (identical(_pending, future)) _pending = null;
    });
  }

  static Future<List<Materia>> _fetch(String userId) async {
    final subjects = await SubjectService().getSubjects(userId);
    final gradeService = GradeService();

    // Las notas de todas las materias se calculan al mismo tiempo
    // (antes se hacía una por una y por eso tardaba).
    final notas = await Future.wait(
      subjects.map(
        (subject) =>
            gradeService.calculateWeightedGrade(userId, subject.id ?? ''),
      ),
    );

    return [
      for (var i = 0; i < subjects.length; i++)
        Materia(
          id: subjects[i].id ?? '',
          nombre: subjects[i].name,
          profesor: subjects[i].teacher ??
              tr('Sin profesor asignado', 'No teacher assigned'),
          iniciales: subjects[i]
              .name
              .split(' ')
              .where((word) => word.isNotEmpty)
              .take(2)
              .map((word) => word[0].toUpperCase())
              .join(),
          nota: notas[i],
          esquemaEvaluacion: subjects[i].evaluationScheme,
        ),
    ];
  }
}

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final SubjectService _subjectService = SubjectService();

  List<Materia> _materias = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  String _busqueda = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _busqueda = _searchController.text.toLowerCase();
      });
    });

    _loadMaterias();
  }



  /// Carga las materias. Si ya hay una copia guardada, la muestra al
  /// instante y actualiza en segundo plano, sin el indicador de carga.
  Future<void> _loadMaterias() async {
    final userId = _userId;

    if (userId == null) {
      setState(() {
        _errorMessage = tr(
          'Debes iniciar sesión para ver tus materias.',
          'You must sign in to see your subjects.',
        );
        _isLoading = false;
      });
      return;
    }

    final cached = SubjectsCache.get(userId);
    setState(() {
      _errorMessage = null;
      if (cached != null) {
        _materias = cached;
        _isLoading = false;
      } else {
        _isLoading = true;
      }
    });

    try {
      final materias = await SubjectsCache.refresh(userId);
      if (!mounted) return;
      setState(() {
        _materias = materias;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Si ya se estaba mostrando la copia guardada, se deja así.
      if (cached != null) return;
      setState(() {
        _errorMessage = tr(
          'No se pudieron cargar las materias.',
          'Could not load the subjects.',
        );
        _isLoading = false;
      });
    }
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
        title: Text(tr('Materias', 'Subjects')),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubjectFormScreen(),
                ),
              );

              if (mounted) {
                await _loadMaterias();
              }
            },
            icon: Icon(Icons.add, color: AppColors.primary, size: 24),
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
                decoration: InputDecoration(
                  hintText: tr('Buscar materia', 'Search subject'),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.errorText),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadMaterias,
                            child: Text(tr('Reintentar', 'Retry')),
                          ),
                        ],
                      ),
                    )
                  : _materiasFiltradas.isEmpty
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

    );
  }

  Future<void> _editarMateria(Materia materia) async {
    final userId = _userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            'Debes iniciar sesión para editar materias.',
            'You must sign in to edit subjects.',
          )),
        ),
      );
      return;
    }

    try {
      final subject = await _subjectService.getSubject(
        userId,
        materia.id,
      );

      if (!mounted) return;

      if (subject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(
              'No se encontró la materia seleccionada.',
              'The selected subject was not found.',
            )),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubjectFormScreen(
            materia: subject,
          ),
        ),
      );

      if (mounted) {
        await _loadMaterias();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            'No se pudo abrir la materia para editarla.',
            'Could not open the subject to edit it.',
          )),
        ),
      );
    }
  }


  Future<void> _eliminarMateria(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Eliminar materia', 'Delete subject')),
        content: Text(
          tr(
            '¿Estás seguro de que deseas eliminar "${materia.nombre}"? '
                'También se eliminarán sus notas registradas.',
            'Are you sure you want to delete "${materia.nombre}"? '
                'Its recorded grades will also be deleted.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              tr('Eliminar', 'Delete'),
              style: TextStyle(color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final userId = _userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            'Debes iniciar sesión para eliminar materias.',
            'You must sign in to delete subjects.',
          )),
        ),
      );
      return;
    }

    final eliminado = await _subjectService.deleteSubject(
      userId,
      materia.id,
    );

    if (!mounted) return;

    if (eliminado) {
      await _loadMaterias();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            'Materia eliminada correctamente.',
            'Subject deleted successfully.',
          )),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(
            'No se pudo eliminar la materia.',
            'Could not delete the subject.',
          )),
        ),
      );
    }
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
                  subjectId: materia.id,
                  nombreMateria: materia.nombre,
                  notaAcumulada: materia.nota,
                  esquemaEvaluacion: materia.esquemaEvaluacion,
                ),
            ),
          ).then((_) => _loadMaterias());
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Iniciales
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  materia.iniciales,
                  style: TextStyle(
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
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        'Prof. ${materia.profesor}',
                        'Prof. ${materia.profesor}',
                      ),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Nota

// Botón para eliminar la materia
          IconButton(
            tooltip: tr('Eliminar materia', 'Delete subject'),
            onPressed: () => _eliminarMateria(materia),
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.errorText,
              size: 22,
            ),
          ),

              IconButton(
                tooltip: tr('Editar materia', 'Edit subject'),
                onPressed: () => _editarMateria(materia),
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 22,
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

          Icon(
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
          Icon(Icons.menu_book, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            tr(
              'Aún no tienes materias registradas',
              "You don't have any subjects registered yet",
            ),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubjectFormScreen(),
                ),
              );

              if (mounted) {
                await _loadMaterias();
              }
            },
            child: Text(tr('Agregar materia', 'Add subject')),
          ),
        ],
      ),
    );
  }
}
