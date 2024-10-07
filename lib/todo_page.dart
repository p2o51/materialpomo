import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'focus_todo_provider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<String> _todos = [];
  final List<bool> _todoStatus = [];
  final List<int> _todoPriorities = []; // 0: low, 1: medium, 2: high
  final TextEditingController _todoController = TextEditingController();
  String? _pushedTodo;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos.addAll(prefs.getStringList('todos') ?? []);
      _todoStatus.addAll(
          (prefs.getStringList('todoStatus') ?? []).map((e) => e == 'true'));
      _todoPriorities
          .addAll((prefs.getStringList('todoPriorities') ?? []).map(int.parse));
    });
  }

  void _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', _todos);
    await prefs.setStringList(
        'todoStatus', _todoStatus.map((e) => e.toString()).toList());
    await prefs.setStringList(
        'todoPriorities', _todoPriorities.map((e) => e.toString()).toList());
  }

  void _addTodo() {
    final String newTodo = _todoController.text.trim();
    if (newTodo.isNotEmpty) {
      setState(() {
        _todos.add(newTodo);
        _todoStatus.add(false);
        _todoPriorities.add(0); // Default to low priority
        _todoController.clear();
      });
      _saveTodos();
    }
  }

  void _removeTodo(int index) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _todos.removeAt(index);
      _todoStatus.removeAt(index);
      _todoPriorities.removeAt(index);
    });

    // Update the local storage
    await prefs.setStringList('todos', _todos);
    await prefs.setStringList(
        'todoStatus', _todoStatus.map((e) => e.toString()).toList());
    await prefs.setStringList(
        'todoPriorities', _todoPriorities.map((e) => e.toString()).toList());
  }

  void _toggleTodoStatus(int index) {
    setState(() {
      _todoStatus[index] = !_todoStatus[index];
    });
    _saveTodos();
  }

  void _cyclePriority(int index) {
    setState(() {
      _todoPriorities[index] = (_todoPriorities[index] + 1) % 3;
      _sortTodos();
    });
    _saveTodos();
  }

  void _sortTodos() {
    final List<Map<String, dynamic>> todoItems = List.generate(
      _todos.length,
      (index) => {
        'todo': _todos[index],
        'status': _todoStatus[index],
        'priority': _todoPriorities[index],
      },
    );

    todoItems.sort((a, b) => b['priority'].compareTo(a['priority']));

    _todos.clear();
    _todoStatus.clear();
    _todoPriorities.clear();

    for (var item in todoItems) {
      _todos.add(item['todo']);
      _todoStatus.add(item['status']);
      _todoPriorities.add(item['priority']);
    }
  }

  double get _completionRate {
    if (_todos.isEmpty) return 0.0;
    return _todoStatus.where((status) => status).length / _todos.length;
  }

  void _pushTodo(String todo) {
    Provider.of<FocusTodoProvider>(context, listen: false).setFocusTodo(todo);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_pushedTodo ?? localizations.todoList),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _completionRate,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 4),
                itemCount: _todos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return TodoItem(
                    todo: _todos[index],
                    isCompleted: _todoStatus[index],
                    priority: _todoPriorities[index],
                    onDelete: () => _removeTodo(index),
                    onToggle: () => _toggleTodoStatus(index),
                    onPriorityChange: () => _cyclePriority(index),
                    onPush: () => _pushTodo(_todos[index]),
                  );
                },
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _todoController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: localizations.item,
                          helperText: localizations.addItemHint,
                        ),
                        onSubmitted: (_) => _addTodo(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _addTodo,
                      child: Text(localizations.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodoItem extends StatelessWidget {
  final String todo;
  final bool isCompleted;
  final int priority;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onPriorityChange;
  final VoidCallback onPush;

  const TodoItem({
    super.key,
    required this.todo,
    required this.isCompleted,
    required this.priority,
    required this.onDelete,
    required this.onToggle,
    required this.onPriorityChange,
    required this.onPush,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Dismissible(
      key: Key(todo),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.todoDeleted)),
          );
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPush();
          return false;
        }
        return true;
      },
      child: ListTile(
        leading: _buildPriorityButton(context),
        title: Text(todo),
        trailing: Checkbox(
          value: isCompleted,
          onChanged: (value) => onToggle(),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    const icon = Icon(Icons.flag);

    switch (priority) {
      case 0:
        return IconButton.outlined(
          onPressed: onPriorityChange,
          icon: icon,
        );
      case 1:
        return IconButton.filledTonal(
          onPressed: onPriorityChange,
          icon: icon,
        );
      case 2:
        return IconButton.filled(
          onPressed: onPriorityChange,
          icon: Icon(Icons.flag, color: colorScheme.onPrimary),
        );
      default:
        return IconButton.outlined(
          onPressed: onPriorityChange,
          icon: icon,
        );
    }
  }
}
