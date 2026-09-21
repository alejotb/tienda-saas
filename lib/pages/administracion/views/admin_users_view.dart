import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/backend/supabase/database/tables/usuarios.dart';
import 'package:baul_pandora/backend/supabase/database/tables/pedidos.dart';
import 'package:intl/intl.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    // Logic is handled by FutureBuilder, but we ensure the loading state is managed
    setState(() => _isLoading = false);
  }

  // Helper to calculate total spent for a specific user
  Future<double> _calculateTotalSpent(String userId) async {
    final orders = await PedidosTable().queryRows(
      queryFn: (q) => q.eq('user_id', userId).eq('status', 'pagado'),
    );
    
    double sum = 0;
    for (var order in orders) {
      sum += order.totalPrice ?? 0.0;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Directorio de Usuarios',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar usuario por nombre o email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                ),
              ),
              const SizedBox(height: 24),
              
              // Users Table
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildUsersTable(),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildUsersTable() {
    return FutureBuilder<List<UsuariosRow>>(
      future: UsuariosTable().queryRows(
        queryFn: (q) {
          if (_searchQuery.isNotEmpty) {
            q = q.or('nombre_completo.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%');
          }
          return q;
        },
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        if (users.isEmpty) return const Center(child: Text('No se encontraron usuarios'));

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: FlutterFlowTheme.of(context).primaryBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Usuario', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Fecha Registro', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Total Gastado', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Acciones', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: users.length,
                separatorBuilder: (context, index) => Divider(color: FlutterFlowTheme.of(context).alternate),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return UserTableRow(user: user);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class UserTableRow extends StatelessWidget {
  final UsuariosRow user;

  const UserTableRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Usuario (Avatar + Info)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: (user.photoPath != null && (user.photoPath?.length ?? 0) > 0)
                      ? NetworkImage(user.photoPath!)
                      : null,
                  child: (user.photoPath == null || (user.photoPath?.length ?? 0) == 0)
                      ? Text(user.nombre?.substring(0, 1).toUpperCase() ?? 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombre ?? 'Sin nombre',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user.email ?? 'Sin email',
                      style: FlutterFlowTheme.of(context).bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Fecha de Registro
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('dd/MM/yyyy').format(user.createdAt),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
          ),
          // Total Gastado (Calculated)
          Expanded(
            flex: 1,
            child: FutureBuilder<double>(
              future: _calculateTotalSpent(user.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                return Text(
                  '\$${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          // Acciones
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Abriendo perfil de ${user.nombre}...')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.block_outlined, size: 20, color: Colors.red),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usuario ${user.nombre} bloqueado')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<double> _calculateTotalSpent(String userId) async {
    final orders = await PedidosTable().queryRows(
      queryFn: (q) => q.eq('user_id', userId).eq('status', 'pagado'),
    );
    double sum = 0;
    for (var order in orders) {
      sum += order.totalPrice ?? 0.0;
    }
    return sum;
  }
}
