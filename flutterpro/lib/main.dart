import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sqflite.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const TodoHome(),
    );
  }
}

class TodoHome extends StatefulWidget {
  const TodoHome({super.key});

  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> with TickerProviderStateMixin {
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  Map<int, bool> expanded = {};
  late TabController controller;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);
    loadTasks();
  }

  Future<void> loadTasks() async {
    final data = await TodoDB.instance.getTasks();
    setState(() {
      tasks = data;
      filteredTasks = tasks;
      expanded = {for (var t in tasks) t['id'] as int: false};
      filterTasks();
    });
  }

  void filterTasks() {
    if (searchQuery.isEmpty) {
      filteredTasks = tasks;
    } else {
      filteredTasks = tasks
          .where((t) =>
              (t['title'] as String).toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  void showTaskDialog({Map<String, dynamic>? task}) {
    final titleController = TextEditingController(text: task?['title'] ?? '');
    final descController = TextEditingController(text: task?['description'] ?? '');
    final isEditing = task != null;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? "Edit Task" : "Add Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Title *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot save task without title!"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      await TodoDB.instance.updateTask(
                        task!['id'],
                        titleController.text.trim(),
                        descController.text.trim(),
                      );
                    } else {
                      await TodoDB.instance.addTask(
                        titleController.text.trim(),
                        descController.text.trim(),
                      );
                    }
                    await loadTasks();
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? "Update" : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteTask(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () async {
              await TodoDB.instance.deleteTask(id);
              await loadTasks();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uncompleted = filteredTasks.where((t) => t['isDone'] == 0).toList();
    final completed = filteredTasks.where((t) => t['isDone'] == 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My To-Do"),
        bottom: TabBar(
          controller: controller,
          tabs: const [
            Tab(text: "Uncompleted"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filterTasks();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: [
                buildList(uncompleted),
                buildList(completed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
          child: Text("No tasks", style: TextStyle(fontSize: 18)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final task = list[index];
        final isExpanded = expanded[task['id']] ?? false;

        // Generate random pastel color for variety
        final colors = [
          Colors.pink.shade100,
          Colors.orange.shade100,
          Colors.green.shade100,
          Colors.blue.shade100,
          Colors.purple.shade100,
          Colors.yellow.shade100,
        ];
        final bgColor = colors[task['id'] % colors.length];

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              )),
          child: Container(
            key: ValueKey(task['id']),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: task['isDone'] == 1 ? Colors.grey.shade300 : bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Checkbox(
                    value: task['isDone'] == 1,
                    onChanged: (_) async {
                      await TodoDB.instance.markDone(
                          task['id'], task['isDone'] == 1 ? 0 : 1);
                      await loadTasks();
                    },
                  ),
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: task['isDone'] == 1
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => showTaskDialog(task: task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteTask(task['id']),
                      ),
                    ],
                  ),
                  onTap: () =>
                      setState(() => expanded[task['id']] = !isExpanded),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(task['description'] ?? ""),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
