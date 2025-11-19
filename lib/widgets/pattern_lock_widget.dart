import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:google_fonts/google_fonts.dart';

class PatternLockWidget extends StatefulWidget {
  final Function(List<int>) onCompleted;
  final Function(List<int>)? onChanged;
  final String? title;
  final String? subtitle;
  final bool showConfirmPattern;
  final String? confirmTitle;
  final String? confirmSubtitle;

  const PatternLockWidget({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.title,
    this.subtitle,
    this.showConfirmPattern = false,
    this.confirmTitle,
    this.confirmSubtitle,
  });

  @override
  State<PatternLockWidget> createState() => _PatternLockWidgetState();
}

class _PatternLockWidgetState extends State<PatternLockWidget> {
  List<int> _confirmedPattern = [];
  bool _isConfirming = false;
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isConfirming) ...[
          _buildTitle(widget.title ?? 'Создайте графический ключ'),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            _buildSubtitle(widget.subtitle!),
          ],
        ] else ...[
          _buildTitle(widget.confirmTitle ?? 'Подтвердите графический ключ'),
          if (widget.confirmSubtitle != null) ...[
            const SizedBox(height: 8),
            _buildSubtitle(widget.confirmSubtitle!),
          ],
        ],
        const SizedBox(height: 32),
        _buildPatternLock(),
        const SizedBox(height: 20),
        if (_showError)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isConfirming ? 'Графические ключи не совпадают' : 'Минимум 4 точки',
              style: GoogleFonts.nunito(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: GoogleFonts.nunito(
        fontSize: 16,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPatternLock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: PatternLock(
        selectedColor: Theme.of(context).primaryColor,
        notSelectedColor: Colors.grey[300]!,
        pointRadius: 8,
        showInput: true,
        fillPoints: true,
        dimension: 3,
        relativePadding: 0.7,
        onInputComplete: _onPatternComplete,
      ),
    );
  }

  void _onPatternComplete(List<int> pattern) {
    if (pattern.length < 4) {
      setState(() {
        _showError = true;
      });
      return;
    }

    if (!widget.showConfirmPattern) {
      widget.onCompleted(pattern);
      return;
    }

    if (!_isConfirming) {
      setState(() {
        _confirmedPattern = pattern;
        _isConfirming = true;
        _showError = false;
      });
    } else {
      if (_listsEqual(_confirmedPattern, pattern)) {
        widget.onCompleted(pattern);
      } else {
        setState(() {
          _showError = true;
        });
        
        // Reset after showing error
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isConfirming = false;
              _confirmedPattern = [];
              _showError = false;
            });
          }
        });
      }
    }
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void reset() {
    setState(() {
      _confirmedPattern = [];
      _isConfirming = false;
      _showError = false;
    });
  }
}