import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildrenSearchScreen extends StatefulWidget {
  final String parentEmail;

  const ChildrenSearchScreen({super.key, required this.parentEmail});

  @override
  State<ChildrenSearchScreen> createState() => _ChildrenSearchScreenState();
}

class _ChildrenSearchScreenState extends State<ChildrenSearchScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _searchController = TextEditingController();
  Map<String, dynamic>? _foundChild;
  bool _loading = false;

  Future<void> _searchChild() async {
    setState(() {
      _loading = true;
      _foundChild = null;
    });

    try {
      final snapshot = await _db.child('children').get();

      if (!snapshot.exists || snapshot.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('База данных пуста')),
        );
        setState(() => _loading = false);
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in data.entries) {
        final child = Map<String, dynamic>.from(entry.value);
        if (child['parentCode'] == _searchController.text.trim()) {
          setState(() => _foundChild = {...child, 'id': entry.key});
          break;
        }
      }

      if (_foundChild == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ребёнок с таким кодом не найден')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addChild() async {
    if (_foundChild == null) return;
    try {
      await _db
          .child('parents_children')
          .child(widget.parentEmail.replaceAll('.', '_'))
          .push()
          .set({
        'childId': _foundChild!['id'],
        'childName': _foundChild!['name'],
        'childEmail': _foundChild!['email'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ребёнок успешно добавлен!')),
      );
      setState(() => _foundChild = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Добавить ребёнка',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Введите код родителя ребёнка",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _searchChild,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Найти ребёнка"),
            ),
            const SizedBox(height: 30),
            if (_foundChild != null)
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0xFFBBDEFB),
                        child: Icon(Icons.child_care,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _foundChild!['name'] ?? '',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _foundChild!['email'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addChild,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Добавить ребёнка"),
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
