import 'package:material_ui/material_ui.dart';

import '../../employee_api.dart';
import '../login/employee_login_screen.dart';

class MiscellaneousExpenseScreen extends StatefulWidget {
  const MiscellaneousExpenseScreen({
    super.key,
    this.isLoading = false,
  });

  static const routeName = '/employee-miscellaneous-expenses';

  final bool isLoading;

  @override
  State<MiscellaneousExpenseScreen> createState() =>
      _MiscellaneousExpenseScreenState();
}

class _MiscellaneousExpenseScreenState
    extends State<MiscellaneousExpenseScreen> {
  final EmployeeApi _api = EmployeeApi();
  List<ExpenseItem> _expenses = [];
  bool _loading = false;

  bool get _isAuthenticated =>
      EmployeeSession.token != null && EmployeeSession.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isAuthenticated) {
      _loadExpenses();
    } else {
      _expenses = [
        ExpenseItem(
          id: 1,
          category: 'Supplies',
          description: 'Sample coffee filters',
          amount: 850,
          date: DateTime.now(),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list = await _api.fetchExpenses();
      if (!mounted) return;
      setState(() => _expenses = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openExpenseForm({ExpenseItem? existing}) async {
    final result = await showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ExpenseForm(initialExpense: existing),
    );
    if (result == null || !mounted) return;

    if (!_isAuthenticated) {
      setState(() {
        if (existing == null) {
          _expenses.insert(0, result);
        } else {
          final idx = _expenses.indexWhere((e) => e.id == existing.id);
          if (idx != -1) _expenses[idx] = result.copyWith(id: existing.id);
        }
      });
      return;
    }

    try {
      if (existing == null) {
        final created = await _api.createExpense(
          category: result.category,
          description: result.description,
          amount: result.amount,
          date: result.date,
        );
        if (!mounted) return;
        setState(() => _expenses.insert(0, created));
        _showFeedback('Expense recorded.');
      } else {
        final updated = await _api.updateExpense(
          id: existing.id,
          category: result.category,
          description: result.description,
          amount: result.amount,
          date: result.date,
        );
        if (!mounted) return;
        final index = _expenses.indexWhere((expense) => expense.id == existing.id);
        if (index != -1) {
          setState(() => _expenses[index] = updated);
        }
        _showFeedback('Expense updated.');
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback(e.toString());
    }
  }

  Future<void> _deleteExpense(ExpenseItem expense) async {
    final confirmed = await _confirm(
      title: 'Delete expense?',
      message: 'Delete "${expense.description}"?',
      confirmLabel: 'Delete expense',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    if (!_isAuthenticated) {
      setState(() => _expenses.removeWhere((item) => item.id == expense.id));
      return;
    }

    try {
      await _api.deleteExpense(expense.id);
      if (!mounted) return;
      setState(() => _expenses.removeWhere((item) => item.id == expense.id));
      _showFeedback('Expense deleted.');
    } catch (e) {
      if (!mounted) return;
      _showFeedback(e.toString());
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthExpenses = _expenses
        .where((expense) =>
            expense.date.year == now.year && expense.date.month == now.month)
        .toList();
    final busy = widget.isLoading || _loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miscellaneous expenses'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              tooltip: 'Refresh',
              onPressed: busy ? null : _loadExpenses,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      floatingActionButton: busy
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openExpenseForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: busy
              ? const _ExpenseState(
                  message: 'Loading expenses...',
                  isLoading: true,
                )
              : _buildContent(currentMonthExpenses),
        ),
      ),
    );
  }

  Widget _buildContent(List<ExpenseItem> currentMonthExpenses) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isAuthenticated) ...[
          const _SampleExpenseNotice(),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 360
                    ? 2
                    : 1;
            final gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: width,
                  child: _ExpenseMetric(
                    label: 'Total recorded expenses',
                    value: _money(_total(_expenses)),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ExpenseMetric(
                    label: 'Expense records',
                    value: '${_expenses.length}',
                    icon: Icons.format_list_numbered,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ExpenseMetric(
                    label: 'Current month',
                    value: _money(_total(currentMonthExpenses)),
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Expense history',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_expenses.isEmpty)
          const _ExpenseState(
            icon: Icons.receipt_long_outlined,
            message: 'No expenses recorded yet.',
          )
        else
          for (final expense in _expenses)
            _ExpenseHistoryCard(
              expense: expense,
              onEdit: () => _openExpenseForm(existing: expense),
              onDelete: () => _deleteExpense(expense),
            ),
      ],
    );
  }
}

class _SampleExpenseNotice extends StatelessWidget {
  const _SampleExpenseNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SAMPLE DATA · Local preview mode.',
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseMetric extends StatelessWidget {
  const _ExpenseMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseHistoryCard extends StatelessWidget {
  const _ExpenseHistoryCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseItem expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = MaterialLocalizations.of(context).formatMediumDate(
      expense.date,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    expense.category,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  _money(expense.amount),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(expense.description),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit expense',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete expense',
                  onPressed: onDelete,
                  color: colors.error,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({this.initialExpense});

  final ExpenseItem? initialExpense;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  static const _categories = [
    'Supplies',
    'Utilities',
    'Maintenance',
    'Transportation',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.initialExpense?.description ?? '');
  late final TextEditingController _amountController = TextEditingController(
    text: widget.initialExpense?.amount.toStringAsFixed(2) ?? '',
  );
  late String? _category = widget.initialExpense?.category;
  late DateTime _selectedDate = widget.initialExpense?.date ?? DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
    field.didChange(selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    Navigator.pop(
      context,
      ExpenseItem(
        id: widget.initialExpense?.id ?? 0,
        category: _category!,
        description: _descriptionController.text.trim(),
        amount: amount,
        date: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialExpense != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    editing ? 'Edit expense' : 'Add expense',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Expense category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value),
                    validator: (value) =>
                        value == null ? 'Choose an expense category.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a description.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₱ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || !amount.isFinite || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  FormField<DateTime>(
                    initialValue: _selectedDate,
                    validator: (value) =>
                        value == null ? 'Choose an expense date.' : null,
                    builder: (field) => InkWell(
                      onTap: () => _pickDate(field),
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(field.value ?? _selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(editing ? 'Save changes' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseState extends StatelessWidget {
  const _ExpenseState({
    required this.message,
    this.icon,
    this.isLoading = false,
  });

  final String message;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(
                icon,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

double _total(List<ExpenseItem> expenses) =>
    expenses.fold(0, (total, expense) => total + expense.amount);

String _money(num amount) => '₱${amount.toStringAsFixed(2)}';