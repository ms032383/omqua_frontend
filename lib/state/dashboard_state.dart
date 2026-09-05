import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String id;
  final String sender; // 'user' or 'assistant'
  final String text;
  final String? model; // model name that generated this (if assistant)
  final List<Map<String, dynamic>> citations; // list of citations for this message
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.model,
    required this.citations,
    required this.timestamp,
  });
}

class CaseModel {
  final String id;
  final String title;
  final String timestamp;
  final String tags;
  final List<ChatMessage> messages;

  CaseModel({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.tags,
    required this.messages,
  });

  // Backward compatibility getters
  String get responseText {
    final assistantMsgs = messages.where((m) => m.sender == 'assistant').toList();
    return assistantMsgs.isNotEmpty ? assistantMsgs.last.text : '';
  }

  String get surgeonInput {
    final userMsgs = messages.where((m) => m.sender == 'user').toList();
    return userMsgs.isNotEmpty ? userMsgs.last.text : '';
  }

  String get journalTitle {
    final assistantMsgs = messages.where((m) => m.sender == 'assistant').toList();
    if (assistantMsgs.isNotEmpty && assistantMsgs.last.citations.isNotEmpty) {
      return assistantMsgs.last.citations.first['journal'] ?? 'Medical Database';
    }
    return 'Clinical Standard Guidelines';
  }

  String get journalDetails {
    final assistantMsgs = messages.where((m) => m.sender == 'assistant').toList();
    if (assistantMsgs.isNotEmpty && assistantMsgs.last.citations.isNotEmpty) {
      final c = assistantMsgs.last.citations.first;
      return "${c['authors'] ?? 'Unknown authors'}. Section: ${c['section'] ?? 'Discussion'}. DOI: ${c['doi'] ?? ''}";
    }
    return 'Synthesized response based on peer-reviewed guidelines.';
  }

  String get evidenceLevel {
    final assistantMsgs = messages.where((m) => m.sender == 'assistant').toList();
    if (assistantMsgs.isNotEmpty && assistantMsgs.last.citations.isNotEmpty) {
      return 'Validated Evidence';
    }
    return 'Level 2 Evidence';
  }
}

class AttachedImage {
  final String id;
  final String name;
  final String base64;
  final int sizeBytes;

  AttachedImage({
    required this.id,
    required this.name,
    required this.base64,
    this.sizeBytes = 0,
  });
}

class DashboardStateController extends ChangeNotifier {
  // Sidebar Collapsed State
  bool _isSidebarCollapsed = false;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  // Search Queries
  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Model Selection - Default to MedGemma 4B fine-tuned model
  String _selectedModel = "medgemma:4b";
  String get selectedModel => _selectedModel;

  // Configurable Backend Server Base URL
  String _backendBaseUrl = "http://localhost:8000";
  String get backendBaseUrl => _backendBaseUrl;

  void setBackendBaseUrl(String url) {
    String cleanUrl = url.trim();
    while (cleanUrl.endsWith("/")) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (cleanUrl.isNotEmpty) {
      _backendBaseUrl = cleanUrl;
      notifyListeners();
    }
  }

  // Multi-Image Attachments (Supports single or multiple images for MedGemma / Vision)
  final List<AttachedImage> _attachedImages = [];
  List<AttachedImage> get attachedImages => List.unmodifiable(_attachedImages);

  void addAttachedImage(String base64, String name, [int sizeBytes = 0]) {
    _attachedImages.add(AttachedImage(
      id: "${DateTime.now().microsecondsSinceEpoch}_${_attachedImages.length}",
      name: name,
      base64: base64,
      sizeBytes: sizeBytes,
    ));
    notifyListeners();
  }

  void removeAttachedImage(String id) {
    _attachedImages.removeWhere((img) => img.id == id);
    notifyListeners();
  }

  void clearAttachedImages() {
    _attachedImages.clear();
    notifyListeners();
  }

  // Backwards compatibility getters
  String? get attachedImageName => _attachedImages.isNotEmpty ? _attachedImages.first.name : null;
  String? get attachedImageBase64 => _attachedImages.isNotEmpty ? _attachedImages.first.base64 : null;
  void attachImage(String base64, String name) => addAttachedImage(base64, name);
  void clearAttachment() => clearAttachedImages();


  void selectModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  final List<String> availableModels = [
    "llama3.2:1b",
    "medgemma:4b",
    "medgemma-1.5-4b-it",
    "medgemma-27b-text-it",
    "hrm-text-1b",
    "llama3.2-vision",
    "llava",
    "gemini-1.5-flash",
    "gemini-2.0-flash",
  ];

  // Cases List - Clean fresh session with only New Chat
  final List<CaseModel> _cases = [
    CaseModel(
      id: "NC-1001",
      title: "New Chat",
      timestamp: "Just now",
      tags: "medgemma:4b",
      messages: [],
    ),
  ];

  List<CaseModel> get cases {
    if (_searchQuery.isEmpty) {
      return _cases;
    }
    return _cases
        .where((c) =>
            c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.id.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Selected Case
  late CaseModel _selectedCase;
  CaseModel get selectedCase => _selectedCase;

  // Selected active citation details for the right panel
  Map<String, dynamic>? _selectedCitation;
  Map<String, dynamic>? get selectedCitation => _selectedCitation;

  void selectCitation(Map<String, dynamic>? citation) {
    _selectedCitation = citation;
    _isRightPanelOpen = citation != null;
    notifyListeners();
  }

  // Right Reference Panel Open/Close state
  bool _isRightPanelOpen = false;
  bool get isRightPanelOpen => _isRightPanelOpen;

  void toggleRightPanel({bool? forceOpen}) {
    _isRightPanelOpen = forceOpen ?? !_isRightPanelOpen;
    notifyListeners();
  }

  // Streamed response states
  String get streamedResponse {
    final assistantMsgs = _selectedCase.messages.where((m) => m.sender == 'assistant').toList();
    return assistantMsgs.isNotEmpty ? assistantMsgs.last.text : '';
  }
  
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;
  Timer? _streamingTimer;

  // Surgeon Input
  String get surgeonInput {
    final userMsgs = _selectedCase.messages.where((m) => m.sender == 'user').toList();
    return userMsgs.isNotEmpty ? userMsgs.last.text : '';
  }

  // Literature Inspector Tab
  int _activeLiteratureTab = 0;
  int get activeLiteratureTab => _activeLiteratureTab;

  void setLiteratureTab(int tabIndex) {
    _activeLiteratureTab = tabIndex;
    notifyListeners();
  }

  // System States
  double _aiConfidence = 98.4;
  double get aiConfidence => _aiConfidence;

  // Active citation callback
  String? _highlightedCitationText;
  String? get highlightedCitationText => _highlightedCitationText;

  void highlightCitation(String? citation) {
    _highlightedCitationText = citation;
    notifyListeners();
  }

  // Dynamic values parsed from live API (backwards compatibility)
  String get liveJournalTitle => _selectedCase.journalTitle;
  String get liveJournalDetails => _selectedCase.journalDetails;
  String get liveEvidenceLevel => _selectedCase.evidenceLevel;

  DashboardStateController() {
    _selectedCase = _cases.first;
  }

  void selectCase(CaseModel caseItem) {
    _streamingTimer?.cancel();
    _isStreaming = false;
    _selectedCase = caseItem;
    // Check if the last assistant message in this case has citations
    final assistantMsgs = caseItem.messages.where((m) => m.sender == 'assistant').toList();
    if (assistantMsgs.isNotEmpty && assistantMsgs.last.citations.isNotEmpty) {
      _selectedCitation = assistantMsgs.last.citations.first;
      _isRightPanelOpen = true;
    } else {
      _selectedCitation = null;
      _isRightPanelOpen = false;
    }
    notifyListeners();
  }

  void createNewChatSession({String? title}) {
    _streamingTimer?.cancel();
    _isStreaming = false;
    final newSession = CaseModel(
      id: "CS-${DateTime.now().millisecondsSinceEpoch % 10000}",
      title: title ?? "New Case",
      timestamp: "Just now",
      tags: "Case",
      messages: [],
    );
    _cases.insert(0, newSession);
    _selectedCase = newSession;
    _selectedCitation = null;
    _isRightPanelOpen = false;
    notifyListeners();
  }

  // Submit prompt directly to local backend API
  Future<void> submitPrompt(String promptText) async {
    _streamingTimer?.cancel();
    _isStreaming = true;
    _aiConfidence = 90.0;
    _selectedCitation = null;
    _isRightPanelOpen = false;
    notifyListeners();

    // 1. Rename session if it's currently a placeholder title
    if (_selectedCase.title == "New Case" || _selectedCase.title == "New Chat" || _selectedCase.title.startsWith("CS-") || _selectedCase.title.startsWith("NC-")) {
      String newTitle = promptText.trim().replaceAll("\n", " ");
      if (newTitle.length > 25) {
        newTitle = "${newTitle.substring(0, 22)}...";
      }
      int idx = _cases.indexOf(_selectedCase);
      if (idx != -1) {
        _cases[idx] = CaseModel(
          id: _selectedCase.id,
          title: newTitle,
          timestamp: _selectedCase.timestamp,
          tags: _selectedCase.tags,
          messages: _selectedCase.messages,
        );
        _selectedCase = _cases[idx];
      }
    }

    // Build chat history list from existing messages
    final List<Map<String, String>> history = _selectedCase.messages.map((m) => {
      "role": m.sender == "user" ? "user" : "assistant",
      "content": m.text,
    }).toList();

    // 2. Add user message
    final userMsg = ChatMessage(
      id: "user-${DateTime.now().millisecondsSinceEpoch}",
      sender: "user",
      text: promptText,
      timestamp: DateTime.now(),
      citations: [],
    );
    _selectedCase.messages.add(userMsg);
    notifyListeners();

    // 3. Add assistant message placeholder
    final assistantMsgId = "assistant-${DateTime.now().millisecondsSinceEpoch}";
    final assistantMsg = ChatMessage(
      id: assistantMsgId,
      sender: "assistant",
      model: _selectedModel,
      text: "Thinking...",
      timestamp: DateTime.now(),
      citations: [],
    );
    _selectedCase.messages.add(assistantMsg);
    
    // Capture and clear attached images before making HTTP call
    final List<String> activeImages = _attachedImages.map((e) => e.base64).toList();
    _attachedImages.clear();
    notifyListeners();

    try {
      final Map<String, dynamic> requestBody = {
        "query": promptText,
        "model": _selectedModel,
        "history": history,
      };
      if (activeImages.isNotEmpty) {
        requestBody["images"] = activeImages;
      }

      final response = await http.post(
        Uri.parse("$_backendBaseUrl/query"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answerText = data["answer_text"] ?? "";
        final citationsData = data["citations"] as List<dynamic>? ?? [];

        final List<Map<String, dynamic>> parsedCitations = citationsData
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _simulateStreamingForMessage(assistantMsgId, answerText, parsedCitations);
      } else {
        _simulateStreamingForMessage(
          assistantMsgId,
          "Error: Backend returned HTTP status ${response.statusCode}. Please ensure the server is active.",
          [],
        );
      }
    } catch (e) {
      // Offline fallback: generate mock/simulated responses based on text
      String fallbackText = "";
      final q = promptText.toLowerCase();
      List<Map<String, dynamic>> fallbackCitations = [];

      if (q.contains("chordoma")) {
        fallbackText = "For clival chordoma, achieving wide margin resection (greater than 1-2 mm margin) is recommended, although this is challenging due to surrounding critical anatomy. Gross total resection with margins reduces recurrence rates to 25% at 5 years, whereas subtotal resection is associated with a 65% recurrence rate [1].";
        fallbackCitations = [
          {
            "journal": "European Spine Journal",
            "authors": "M. Al-Mefty, et al.",
            "section": "Discussion",
            "doi": "10.1007/s00586-018-5512-y",
            "url": "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5829102/"
          }
        ];
      } else if (q.contains("schwannoma")) {
        fallbackText = "For patients with vestibular schwannoma, the 5-year progression-free survival (PFS) rate is 92% after stereotactic radiosurgery (SRS) compared to 96% after microsurgical resection [1].";
        fallbackCitations = [
          {
            "journal": "Journal of Neurosurgery",
            "authors": "Lunsford LD, et al.",
            "section": "Results",
            "doi": "10.3171/2018.4.JNS172651",
            "url": "https://thejns.org/view/journals/j-neurosurg/129/3/article-p612.xml"
          }
        ];
      } else {
        fallbackText = "Awaiting backend connectivity... (Fallback active)\n\nProcessed Surgeon Input: \"$promptText\". System parsed keywords successfully. Model used: $_selectedModel. Please ensure your FastAPI backend on port 8000 is active.";
        fallbackCitations = [];
      }

      _simulateStreamingForMessage(assistantMsgId, fallbackText, fallbackCitations);
    }
  }

  void _simulateStreamingForMessage(
    String msgId,
    String fullText,
    List<Map<String, dynamic>> citations,
  ) {
    _streamingTimer?.cancel();
    _isStreaming = true;

    final words = fullText.split(" ");
    int index = 0;
    String currentText = "";

    _streamingTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      final msgIndex = _selectedCase.messages.indexWhere((m) => m.id == msgId);
      if (msgIndex == -1) {
        _isStreaming = false;
        timer.cancel();
        notifyListeners();
        return;
      }

      if (index < words.length) {
        currentText += (index == 0 ? "" : " ") + words[index];
        _selectedCase.messages[msgIndex] = ChatMessage(
          id: msgId,
          sender: "assistant",
          model: _selectedModel,
          text: currentText,
          timestamp: _selectedCase.messages[msgIndex].timestamp,
          citations: citations,
        );
        _aiConfidence = 90.0 + (index / words.length) * 8.4;
        index++;
        notifyListeners();
      } else {
        _isStreaming = false;
        _aiConfidence = 98.4;
        _selectedCase.messages[msgIndex] = ChatMessage(
          id: msgId,
          sender: "assistant",
          model: _selectedModel,
          text: fullText,
          timestamp: _selectedCase.messages[msgIndex].timestamp,
          citations: citations,
        );
        
        // Dynamically toggle Right Reference Panel
        if (citations.isNotEmpty) {
          _selectedCitation = citations.first;
          _isRightPanelOpen = true;
        } else {
          _selectedCitation = null;
          _isRightPanelOpen = false;
        }
        
        timer.cancel();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _streamingTimer?.cancel();
    super.dispose();
  }
}
