import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PinInputWidget extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool obscureText;
  final String? title;
  final String? subtitle;

  const PinInputWidget({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.obscureText = true,
    this.title,
    this.subtitle,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  String _pin = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
        // PIN dots display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: index < _pin.length
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: index < _pin.length && !widget.obscureText
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : null,
              ),
              child: index < _pin.length && widget.obscureText
                  ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Number pad
        Container(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Rows 1-3 (1-9)
              for (int row = 0; row < 3; row++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (col) {
                      final number = row * 3 + col + 1;
                      return _buildNumberButton(number);
                    },
                  ),
                ),
              const SizedBox(height: 10),
              // Row 4 (0 and backspace)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 70), // Empty space for alignment
                  _buildNumberButton(0),
                  _buildBackspaceButton(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(int number) {
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.all(5),
      child: ElevatedButton(
        onPressed: () => _addDigit(number.toString()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          elevation: 2,
        ),
        child: Text(
          number.toString(),
          style: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.all(5),
      child: ElevatedButton(
        onPressed: _removeDigit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          elevation: 2,
        ),
        child: Icon(
          Icons.backspace_outlined,
          size: 24,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _addDigit(String digit) {
    if (_pin.length < widget.length) {
      setState(() {
        _pin += digit;
      });
      
      widget.onChanged?.call(_pin);
      
      if (_pin.length == widget.length) {
        widget.onCompleted(_pin);
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      widget.onChanged?.call(_pin);
    }
  }

  void clear() {
    setState(() {
      _pin = '';
    });
    widget.onChanged?.call(_pin);
  }
}