import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class CitationBadge extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const CitationBadge({
    Key? key,
    required this.label,
    required this.onTap,
    required this.onHover,
  }) : super(key: key);

  @override
  State<CitationBadge> createState() => _CitationBadgeState();
}

class _CitationBadgeState extends State<CitationBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover(false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _isHovered ? CyberTheme.accent : CyberTheme.borderMuted,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: _isHovered ? CyberTheme.accent : CyberTheme.borderBright,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _isHovered ? CyberTheme.background : CyberTheme.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class CyberResponseText extends StatelessWidget {
  final String text;
  final Function(String) onCitationTap;
  final Function(String, bool) onCitationHover;

  const CyberResponseText({
    Key? key,
    required this.text,
    required this.onCitationTap,
    required this.onCitationHover,
  }) : super(key: key);

  // List of medical terms to highlight in white/bold
  static const List<String> medicalEntities = [
    "meningioma",
    "dural tail sign",
    "WHO Grade I",
    "resection margin",
    "sagittal sinus patency",
    "venous congestion",
    "glioma",
    "FLAIR signal envelope",
    "DTI tractography",
    "speech and language tracts",
    "arcuate fasciculus",
    "intraoperative language mapping",
    "awake anesthesia",
    "vestibular schwannoma",
    "internal auditory canal",
    "cerebellopontine angle",
    "facial nerve function",
    "facial EMG",
    "Koos Grade III",
    "trigeminal nerve",
    "root entry zone",
    "superior cerebellar artery",
    "Teflon felt",
    "venous compression",
  ];

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const Text("Awaiting system input stream...");
    }

    final children = <InlineSpan>[];
    
    // Regular expression to find citation patterns like [1] or [1](url)
    final regex = RegExp(r'\[(\d+)\](?:\(([^)]+)\))?');
    final matches = regex.allMatches(text);

    int lastMatchEnd = 0;

    for (final match in matches) {
      // Print text before the citation match
      if (match.start > lastMatchEnd) {
        final preText = text.substring(lastMatchEnd, match.start);
        children.addAll(_parseMedicalEntities(preText));
      }

      final citationNum = match.group(1)!;
      final citationLabel = "[$citationNum]";

      // Add the citation badge
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: CitationBadge(
            label: citationLabel,
            onTap: () => onCitationTap(citationLabel),
            onHover: (isHovered) => onCitationHover(citationLabel, isHovered),
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add trailing text
    if (lastMatchEnd < text.length) {
      final postText = text.substring(lastMatchEnd);
      children.addAll(_parseMedicalEntities(postText));
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          color: CyberTheme.textWhite,
          fontSize: 15.5,
          height: 1.6,
        ),
        children: children,
      ),
    );
  }

  // Parses medical entities and formats them as bold/white
  List<InlineSpan> _parseMedicalEntities(String content) {
    final spans = <InlineSpan>[];
    
    // Sort medical entities by length descending to match longest first
    final sortedEntities = List<String>.from(medicalEntities)
      ..sort((a, b) => b.length.compareTo(a.length));

    // Combine all entities into a regex pattern
    final escapedEntities = sortedEntities.map((e) => RegExp.escape(e)).join('|');
    final entityRegex = RegExp('($escapedEntities)', caseSensitive: false);

    final entityMatches = entityRegex.allMatches(content);
    int textCursor = 0;

    for (final entityMatch in entityMatches) {
      if (entityMatch.start > textCursor) {
        spans.add(TextSpan(
          text: content.substring(textCursor, entityMatch.start),
          style: const TextStyle(color: CyberTheme.textWhite),
        ));
      }

      final matchedText = entityMatch.group(0)!;
      spans.add(TextSpan(
        text: matchedText,
        style: const TextStyle(
          color: CyberTheme.textWhite,
          fontWeight: FontWeight.w600,
          backgroundColor: Color(0xFF282828), // Subtle grey highlights for medical entities
        ),
      ));

      textCursor = entityMatch.end;
    }

    if (textCursor < content.length) {
      spans.add(TextSpan(
        text: content.substring(textCursor),
        style: const TextStyle(color: CyberTheme.textWhite),
      ));
    }

    return spans;
  }
}
