import 'package:flutter/material.dart';

import '../../backend/auth_service.dart';
import '../../backend/models/user_model.dart';
import '../login/login_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const _blue = Color(0xFF0E6BFF);
  static const _ink = Color(0xFF17243A);
  static const _muted = Color(0xFF718096);

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _searchController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  String _accountFilter = 'All';
  List<UserModel> _accounts = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminPasswordController.dispose();
    _departmentController.dispose();
    _studentIdController.dispose();
    _designationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final accounts = await _authService.getManagedAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load accounts: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final result = await _authService.createManagedAccount(
        username: _usernameController.text,
        password: _passwordController.text,
        role: _selectedRole,
        displayName: _nameController.text,
        email: _emailController.text,
        department: _departmentController.text,
        adminPassword: _adminPasswordController.text.trim(),
        studentId: _studentIdController.text,
        designation: _designationController.text,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (!result.isSuccess) {
        _showMessage(result.message, isError: true);
        return;
      }

      _nameController.clear();
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      // Keep adminPasswordController filled for convenience
      _departmentController.clear();
      _studentIdController.clear();
      _designationController.clear();
      await _loadAccounts();
      if (mounted) _showMessage('Login created for ${result.user!.username}.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Could not create account: $error', isError: true);
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not log out: $error', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF167C56),
      ),
    );
  }

  List<UserModel> get _visibleAccounts {
    final query = _searchController.text.trim().toLowerCase();
    return _accounts.where((account) {
      final matchesRole =
          _accountFilter == 'All' ||
          (_accountFilter == 'Students' && account.role == UserRole.student) ||
          (_accountFilter == 'Staff' && account.role == UserRole.staff);
      final matchesQuery =
          query.isEmpty ||
          account.displayName.toLowerCase().contains(query) ||
          account.username.toLowerCase().contains(query) ||
          account.email.toLowerCase().contains(query) ||
          (account.department?.toLowerCase().contains(query) ?? false);
      return matchesRole && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final students = _accounts
        .where((user) => user.role == UserRole.student)
        .length;
    final staff = _accounts.where((user) => user.role == UserRole.staff).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Admin dashboard',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAccounts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      width: width,
                      title: 'Students',
                      count: students,
                      icon: Icons.school_outlined,
                      color: const Color(0xFF0E6BFF),
                    ),
                    _buildStatCard(
                      width: width,
                      title: 'Staff',
                      count: staff,
                      icon: Icons.badge_outlined,
                      color: const Color(0xFF7C55D9),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Create a login',
              'Set up a staff or student account',
            ),
            const SizedBox(height: 12),
            _buildCreateAccountCard(),
            const SizedBox(height: 26),
            _buildSectionTitle(
              'Accounts',
              '${_accounts.length} logins managed',
            ),
            const SizedBox(height: 12),
            _buildAccountsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E6BFF), Color(0xFF4B96F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage Smart Meet staff and student access.',
                  style: TextStyle(color: Color(0xFFEAF2FF), height: 1.4),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          CircleAvatar(
            radius: 26,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: _muted)),
      ],
    );
  }

  Widget _buildCreateAccountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              decoration: _inputDecoration(
                'Account type',
                Icons.people_outline,
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRole.student,
                  child: Text('Student'),
                ),
                DropdownMenuItem(value: UserRole.staff, child: Text('Staff')),
              ],
              onChanged: _isSaving
                  ? null
                  : (role) {
                      if (role != null) setState(() => _selectedRole = role);
                    },
            ),
            const SizedBox(height: 12),
            _textField(_nameController, 'Full name', Icons.person_outline),
            const SizedBox(height: 12),
            _textField(
              _usernameController,
              'Username / login ID',
              Icons.account_circle_outlined,
            ),
            const SizedBox(height: 12),
            _textField(
              _emailController,
              'Email address',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _textField(
              _passwordController,
              'Temporary password (at least 6 characters)',
              Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _textField(
              _departmentController,
              'Department',
              Icons.domain_outlined,
            ),
            if (_selectedRole == UserRole.student) ...[
              const SizedBox(height: 12),
              _textField(
                _studentIdController,
                'Student ID / roll number',
                Icons.badge_outlined,
              ),
            ] else ...[
              const SizedBox(height: 12),
              _textField(
                _designationController,
                'Designation',
                Icons.work_outline,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your password is needed to keep you signed in after creating the new account.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _textField(
              _adminPasswordController,
              'Your admin password',
              Icons.admin_panel_settings_outlined,
              obscureText: true,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(_isSaving ? 'Creating…' : 'Create login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool? autocorrect,
    bool? enableSuggestions,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isEmail = keyboardType == TextInputType.emailAddress;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: autocorrect ?? (!obscureText && !isEmail),
      enableSuggestions: enableSuggestions ?? (!obscureText && !isEmail),
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        if (controller == _usernameController && value.trim().length < 3) {
          return 'Use at least 3 characters';
        }
        if (controller == _passwordController && value.trim().length < 6) {
          return 'Use at least 6 characters';
        }
        if (controller == _emailController && !value.trim().contains('@')) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _muted),
      filled: true,
      fillColor: const Color(0xFFF5F8FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _blue, width: 1.4),
      ),
    );
  }

  Widget _buildAccountsCard() {
    if (_loadError != null) {
      return _messageCard(
        _loadError!,
        action: TextButton(
          onPressed: _loadAccounts,
          child: const Text('Retry'),
        ),
      );
    }
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: _cardDecoration,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final accounts = _visibleAccounts;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('Search accounts', Icons.search),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: ['All', 'Students', 'Staff'].map((filter) {
                final selected = filter == _accountFilter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => _accountFilter = filter),
                  selectedColor: const Color(0xFFDCEBFF),
                  labelStyle: TextStyle(
                    color: selected ? _blue : _muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No accounts match your search.',
                style: TextStyle(color: _muted),
              ),
            )
          else
            ...accounts.map(_buildAccountTile),
        ],
      ),
    );
  }

  Widget _buildAccountTile(UserModel account) {
    final isStudent = account.role == UserRole.student;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: CircleAvatar(
        backgroundColor: isStudent
            ? const Color(0xFFE7F1FF)
            : const Color(0xFFF0EAFE),
        child: Icon(
          isStudent ? Icons.school_outlined : Icons.badge_outlined,
          color: isStudent ? _blue : const Color(0xFF7C55D9),
        ),
      ),
      title: Text(
        account.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, color: _ink),
      ),
      subtitle: Text(
        '${account.username} · ${account.department ?? ''}\n${account.email}',
        style: const TextStyle(color: _muted, height: 1.5),
      ),
      isThreeLine: true,
      trailing: Text(
        isStudent ? 'STUDENT' : 'STAFF',
        style: TextStyle(
          color: isStudent ? _blue : const Color(0xFF7C55D9),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _messageCard(String message, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(color: Color(0x0A17243A), blurRadius: 16, offset: Offset(0, 5)),
    ],
  );
}
