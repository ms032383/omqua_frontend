import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../theme/cyber_theme.dart';
import '../state/dashboard_state.dart';
import '../widgets/citation_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardStateController _controller = DashboardStateController();
  final TextEditingController _textInputController = TextEditingController();
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    _textInputController.dispose();
    _sidebarScrollController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ANIMATED LEFT SIDEBAR
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: _controller.isSidebarCollapsed ? 60.0 : 260.0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 60.0,
                maxWidth: 260.0,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: _controller.isSidebarCollapsed ? 60.0 : 260.0,
                  child: _controller.isSidebarCollapsed
                      ? _buildCollapsedSidebar()
                      : _buildExpandedSidebar(),
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            color: CyberTheme.borderMuted,
          ),

          // 2. MAIN CONVERSATIONAL CHAT WORKSPACE (Center Panel)
          Expanded(
            child: _buildChatWorkspace(),
          ),

          // 3. ANIMATED RIGHT REFERENCE INSPECTOR PANEL (Three-Panel Layout)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: (_controller.isRightPanelOpen && _controller.selectedCitation != null)
                ? 320.0
                : 0.0,
            child: Row(
              children: [
                // Inner Divider
                Container(
                  width: 1,
                  color: CyberTheme.borderMuted,
                ),
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 0.0,
                      maxWidth: 319.0,
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: 319.0,
                        child: _buildRightReferencePanel(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR UI ---

  Widget _buildExpandedSidebar() {
    // Group sessions by date
    final todayChats = <CaseModel>[];
    final otherChats = <CaseModel>[];

    for (final c in _controller.cases) {
      if (c.timestamp.contains("hour") || c.timestamp.contains("now") || c.timestamp.contains("minutes")) {
        todayChats.add(c);
      } else {
        otherChats.add(c);
      }
    }

    return Container(
      color: CyberTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: CyberTheme.accent, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "NEURO AI",
                      style: CyberTheme.themeData.textTheme.titleLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: CyberTheme.textGray, size: 20),
                  onPressed: () => _controller.toggleSidebar(),
                  tooltip: "Collapse Sidebar",
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => _controller.updateSearchQuery(val),
              style: const TextStyle(color: CyberTheme.textWhite, fontSize: 12),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: CyberTheme.textGray, size: 16),
                hintText: "Search chats...",
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                fillColor: CyberTheme.cardBg,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: CyberTheme.softBorderRadius,
                  borderSide: const BorderSide(color: CyberTheme.borderMuted),
                ),
              ),
            ),
          ),

          // New Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _controller.createNewChatSession();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: CyberTheme.cardBg,
                    border: Border.all(color: CyberTheme.borderMuted),
                    borderRadius: CyberTheme.softBorderRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "New Chat",
                        style: TextStyle(
                          color: CyberTheme.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.edit_square, color: CyberTheme.textGray, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick Links (Search, Notes, Workspace)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildSidebarQuickLink(Icons.search, "Search"),
                _buildSidebarQuickLink(Icons.notes, "Notes"),
                _buildSidebarQuickLink(Icons.grid_view, "Workspace"),
              ],
            ),
          ),

          const Divider(color: CyberTheme.borderMuted, height: 16),

          // Scrollable Chat History
          Expanded(
            child: Scrollbar(
              controller: _sidebarScrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _sidebarScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                  if (todayChats.isNotEmpty) ...[
                    _buildSectionHeader("Today"),
                    ...todayChats.map((c) => _buildChatItem(c)),
                  ],
                  if (otherChats.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSectionHeader("Recent Cases"),
                    ...otherChats.map((c) => _buildChatItem(c)),
                  ],
                ],
              ),
            ),
          ),

          const Divider(color: CyberTheme.borderMuted, height: 1),

          // User Profile Card at bottom
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.shade700,
                  child: const Text(
                    "M",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Mohan",
                        style: TextStyle(
                          color: CyberTheme.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: CyberTheme.textGray, size: 18),
                  onPressed: _showSettingsDialog,
                  tooltip: "Settings",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSidebar() {
    return Container(
      width: 60,
      color: CyberTheme.background,
      child: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: CyberTheme.textWhite, size: 20),
            onPressed: () => _controller.toggleSidebar(),
            tooltip: "Expand Sidebar",
          ),
          const Divider(color: CyberTheme.borderMuted),
          IconButton(
            icon: const Icon(Icons.add, color: CyberTheme.textGray),
            onPressed: () => _controller.createNewChatSession(),
            tooltip: "New Chat",
          ),
          IconButton(
            icon: const Icon(Icons.search, color: CyberTheme.textGray),
            onPressed: () => _controller.toggleSidebar(),
            tooltip: "Search",
          ),
          IconButton(
            icon: const Icon(Icons.notes, color: CyberTheme.textGray),
            onPressed: () {},
            tooltip: "Notes",
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, color: CyberTheme.textGray),
            onPressed: () {},
            tooltip: "Workspace",
          ),
          const Spacer(),
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange.shade700,
            child: const Text("M", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarQuickLink(IconData icon, String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: CyberTheme.textGray, size: 16),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: CyberTheme.textGray, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          color: CyberTheme.textGray,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChatItem(CaseModel item) {
    final isSelected = item.id == _controller.selectedCase.id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _controller.selectCase(item),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? CyberTheme.cardBg : Colors.transparent,
            borderRadius: CyberTheme.softBorderRadius,
            border: Border.all(
              color: isSelected ? CyberTheme.borderBright : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: isSelected ? CyberTheme.textWhite : CyberTheme.textGray,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(Icons.more_horiz, color: CyberTheme.textGray, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // --- MAIN CHAT WORKSPACE UI ---

  Widget _buildChatWorkspace() {
    final activeCase = _controller.selectedCase;
    final messages = activeCase.messages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top bar / Header
        _buildChatHeader(),

        // Divider
        Container(height: 1, color: CyberTheme.borderMuted),

        // 2. Scrollable Messages / Welcome Screen
        Expanded(
          child: messages.isEmpty
              ? _buildWelcomeState()
              : _buildMessagesList(messages),
        ),

        // 3. Bottom Prompt Bar Console
        _buildBottomInputBar(),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Model Selection Dropdown
          Row(
            children: [
              _buildModelSelector(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cloud_sync_outlined, color: CyberTheme.textGray, size: 18),
                onPressed: () => _showBackendConfigDialog(),
                tooltip: "Configure Backend Endpoint (${_controller.backendBaseUrl})",
              ),
            ],
          ),

          // Metadata/Stats (To preserve clinical context)
          Row(
            children: [
              if (_controller.isStreaming)
                Row(
                  children: const [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: CyberTheme.accent,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Synthesizing...",
                      style: TextStyle(color: CyberTheme.textGray, fontSize: 10),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              Text(
                "CONFIDENCE: ${_controller.aiConfidence.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: CyberTheme.textGray,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    return PopupMenuButton<String>(
      onSelected: (model) {
        _controller.selectModel(model);
      },
      color: CyberTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: CyberTheme.softBorderRadius,
        side: const BorderSide(color: CyberTheme.borderMuted),
      ),
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CyberTheme.cardBg,
          borderRadius: CyberTheme.softBorderRadius,
          border: Border.all(color: CyberTheme.borderMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _controller.selectedModel,
              style: const TextStyle(
                color: CyberTheme.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: CyberTheme.textGray,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return _controller.availableModels.map((model) {
          final isSelected = model == _controller.selectedModel;
          return PopupMenuItem<String>(
            value: model,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  model,
                  style: TextStyle(
                    color: isSelected ? CyberTheme.textWhite : CyberTheme.textGray,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: CyberTheme.accent, size: 14),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  void _showBackendConfigDialog() {
    final textController = TextEditingController(text: _controller.backendBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: CyberTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: CyberTheme.softBorderRadius,
            side: const BorderSide(color: CyberTheme.borderBright),
          ),
          title: Row(
            children: const [
              Icon(Icons.dns, color: CyberTheme.accent, size: 20),
              SizedBox(width: 10),
              Text(
                "Backend API Endpoint",
                style: TextStyle(color: CyberTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set FastAPI backend endpoint. Use localhost for local dev or paste Cloudflare Tunnel HTTPS URL when connecting to Google Cloud VM:",
                style: TextStyle(color: CyberTheme.textGray, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                style: const TextStyle(color: CyberTheme.textWhite, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "https://your-tunnel.trycloudflare.com",
                  hintStyle: const TextStyle(color: CyberTheme.textGray, fontSize: 12),
                  filled: true,
                  fillColor: CyberTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: CyberTheme.softBorderRadius,
                    borderSide: const BorderSide(color: CyberTheme.borderMuted),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: CyberTheme.softBorderRadius,
                    borderSide: const BorderSide(color: CyberTheme.accent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                textController.text = "http://localhost:8000";
              },
              child: const Text("Reset Localhost", style: TextStyle(color: CyberTheme.textGray, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTheme.accent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  _controller.setBackendBaseUrl(textController.text.trim());
                }
                Navigator.of(ctx).pop();
              },
              child: const Text("Save URL"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeState() {
    final starters = [
      "Margin guidelines for clival chordoma",
      "Vestibular schwannoma: SRS vs resection outcomes",
      "Eloquent-area glioma: MEP decline limit",
      "DAPT pre-craniotomy guidelines"
    ];

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.psychology, size: 72, color: CyberTheme.borderBright),
              const SizedBox(height: 20),
              Text(
                "Neuro AI Synthesis Engine",
                style: CyberTheme.themeData.textTheme.displayMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Closed-Domain Neurosurgical Assistant with strict citation verification.",
                style: TextStyle(color: CyberTheme.textGray, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                ),
                itemCount: starters.length,
                itemBuilder: (context, index) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        _textInputController.text = starters[index];
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CyberTheme.cardBg,
                          border: Border.all(color: CyberTheme.borderMuted),
                          borderRadius: CyberTheme.softBorderRadius,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            starters[index],
                            style: const TextStyle(
                              color: CyberTheme.textWhite,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return Scrollbar(
      controller: _chatScrollController,
      thumbVisibility: true,
      child: SelectionArea(
        child: ListView.builder(
          controller: _chatScrollController,
          itemCount: messages.length,
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemBuilder: (context, index) {
            final message = messages[index];
            final isUser = message.sender == 'user';
            final isLast = index == messages.length - 1;

            if (isUser) {
              return _buildUserBubble(message);
            } else {
              return _buildAssistantBubble(message, isLast);
            }
          },
        ),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 64, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CyberTheme.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(CyberTheme.borderRadiusValue),
            topRight: const Radius.circular(CyberTheme.borderRadiusValue),
            bottomLeft: const Radius.circular(CyberTheme.borderRadiusValue),
            bottomRight: Radius.zero,
          ),
          border: Border.all(color: CyberTheme.borderMuted),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: CyberTheme.textWhite,
            fontSize: 15.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(ChatMessage message, bool isLast) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 64),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: CyberTheme.borderBright,
              child: const Icon(
                Icons.psychology,
                color: CyberTheme.textWhite,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Message Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model Header Name
                  Text(
                    message.model ?? _controller.selectedModel,
                    style: const TextStyle(
                      color: CyberTheme.textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Response Content Text
                  CyberResponseText(
                    text: message.text,
                    onCitationTap: (citation) {
                      _showCitationDetailsFromMessage(message, citation);
                    },
                    onCitationHover: (citation, isHovered) {},
                  ),

                  // Reference links below the response (Direct User Request)
                  if (message.citations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: CyberTheme.borderMuted, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.link, size: 12, color: CyberTheme.textGray),
                        SizedBox(width: 4),
                        Text(
                          "REFERENCE LINKS",
                          style: TextStyle(
                            color: CyberTheme.textGray,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(message.citations.length, (idx) {
                        final citation = message.citations[idx];
                        final numStr = "[${idx + 1}]";
                        final title = citation['authors'] ?? citation['journal'] ?? 'Reference Paper';
                        final journal = citation['journal'] ?? 'Medical database';
                        final year = citation['year']?.toString() ?? '';
                        final docText = "$numStr $title ($journal${year.isNotEmpty ? ', $year' : ''})";

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                _controller.selectCitation(citation);
                              },
                              child: Text(
                                docText,
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 11.5,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],

                  // Small Action Menu Bar
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMiniActionButton(Icons.edit_note_outlined, "Edit", () {}),
                      _buildMiniActionButton(Icons.content_copy_outlined, "Copy", () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Response copied to clipboard"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),
                      _buildMiniActionButton(Icons.volume_up_outlined, "Speak", () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Synthesizing read aloud stream..."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),
                      _buildMiniActionButton(Icons.thumb_up_outlined, "Like", () {}),
                      _buildMiniActionButton(Icons.thumb_down_outlined, "Dislike", () {}),
                      _buildMiniActionButton(Icons.refresh_outlined, "Regenerate", () {
                        // Resubmit the last user query
                        final lastUserMsg = _controller.selectedCase.messages
                            .where((m) => m.sender == 'user')
                            .lastOrNull;
                        if (lastUserMsg != null) {
                          _controller.submitPrompt(lastUserMsg.text);
                        }
                      }),
                    ],
                  ),

                  // Suggestions Section (Stacked horizontally/vertically under the last response)
                  if (isLast && !_controller.isStreaming) ...[
                    const SizedBox(height: 16),
                    _buildSuggestionsPanel(message.text),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Tooltip(
        message: tooltip,
        textStyle: const TextStyle(fontSize: 10, color: CyberTheme.textWhite),
        decoration: BoxDecoration(color: CyberTheme.background, borderRadius: BorderRadius.circular(4.0)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.0),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(icon, color: CyberTheme.textGray, size: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsPanel(String responseText) {
    final queryText = responseText.toLowerCase();
    List<String> suggestedQuestions = [];

    if (queryText.contains("meningioma")) {
      suggestedQuestions = [
        "Review dural tail sign guidelines",
        "Double-check sagittal sinus patency",
        "What is WHO Grade I protocol?"
      ];
    } else if (queryText.contains("glioma")) {
      suggestedQuestions = [
        "Arcuate fasciculus proximity",
        "Review intraoperative language mapping guidelines",
        "DTI tractography margin validation"
      ];
    } else if (queryText.contains("schwannoma") || queryText.contains("neuroma")) {
      suggestedQuestions = [
        "Koos Grade III protocol details",
        "Monitor facial EMG responses",
        "Verify cranial nerve preservation guidelines"
      ];
    } else {
      suggestedQuestions = [
        "What model are you?",
        "How can we make our interaction more personalized?",
        "Can you adjust your tone to better fit your brand?"
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Follow up",
          style: TextStyle(
            color: CyberTheme.textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: suggestedQuestions.map((q) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    _controller.submitPrompt(q);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: CyberTheme.cardBg,
                      border: Border.all(color: CyberTheme.borderMuted),
                      borderRadius: CyberTheme.softBorderRadius,
                    ),
                    child: Text(
                      q,
                      style: const TextStyle(
                        color: CyberTheme.textWhite,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- BOTTOM INPUT CONSOLE BAR ---

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: CyberTheme.cardBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: CyberTheme.borderMuted, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.attachedImageName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: CyberTheme.borderMuted, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: CyberTheme.accent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _controller.attachedImageName!,
                        style: const TextStyle(color: CyberTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: CyberTheme.textGray, size: 14),
                        onPressed: () => _controller.clearAttachment(),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
              // Inside Left Buttons: Upload & Web Search
              IconButton(
                icon: const Icon(Icons.add, color: CyberTheme.textGray, size: 20),
                onPressed: _showUploadDialog,
                tooltip: "Upload DICOM/Paper",
              ),
              IconButton(
                icon: const Icon(Icons.explore_outlined, color: CyberTheme.textGray, size: 20),
                onPressed: () {},
                tooltip: "Web search",
              ),

              // Text Field Input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextField(
                    controller: _textInputController,
                    style: const TextStyle(color: CyberTheme.textWhite, fontSize: 15.5),
                    decoration: const InputDecoration(
                      hintText: "Send a Message",
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _controller.submitPrompt(value.trim());
                        _textInputController.clear();
                      }
                    },
                  ),
                ),
              ),

              // Inside Right Buttons: Mic & Send
              IconButton(
                icon: const Icon(Icons.mic_none, color: CyberTheme.textGray, size: 20),
                onPressed: () {},
                tooltip: "Voice input",
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward, color: CyberTheme.accent, size: 20),
                onPressed: () {
                  final value = _textInputController.text;
                  if (value.trim().isNotEmpty) {
                    _controller.submitPrompt(value.trim());
                    _textInputController.clear();
                  }
                },
                tooltip: "Send message",
              ),
            ],
          ),
          ],
          ),
        ),
      ),
    );
  }

  // --- ACTIONS & DIALOGS ---

  void _showCitationDetailsFromMessage(ChatMessage message, String citationBadgeText) {
    // Parse citation index
    int index = int.tryParse(citationBadgeText.replaceAll(RegExp(r'\D'), '')) ?? 1;
    if (index > 0 && index <= message.citations.length) {
      _controller.selectCitation(message.citations[index - 1]);
    } else {
      // Fallback
      _controller.selectCitation({
        "journal": _controller.liveJournalTitle,
        "authors": _controller.liveJournalDetails,
        "doi": "N/A",
        "url": "N/A"
      });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CyberTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: CyberTheme.softBorderRadius),
          title: const Text(
            "SETTINGS",
            style: TextStyle(color: CyberTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "USER PROFILE",
                style: TextStyle(color: CyberTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.orange.shade700,
                    child: const Text("M", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  const Text("Mohan", style: TextStyle(color: CyberTheme.textWhite, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "VERSION INFORMATION",
                style: TextStyle(color: CyberTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 6),
              const Text(
                "Neuro AI Synthesis Dashboard v1.0.0\nRunning local Ollama model llama3.2:1b & Gemini fallback.",
                style: TextStyle(color: CyberTheme.textGray, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: CyberTheme.textWhite)),
            ),
          ],
        );
      },
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CyberTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: CyberTheme.softBorderRadius),
          title: const Text(
            "SELECT MEDICAL SCAN / FILE",
            style: TextStyle(color: CyberTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open, color: CyberTheme.accent),
                title: const Text("Browse files from computer...", style: TextStyle(color: CyberTheme.textWhite, fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: const Text("Select any image (PNG, JPG) or medical scan", style: TextStyle(color: CyberTheme.textGray, fontSize: 10)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    FilePickerResult? result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['png', 'jpg', 'jpeg', 'dcm', 'dicom'],
                      withData: true,
                    );
                    if (result != null) {
                      final file = result.files.single;
                      if (file.bytes != null) {
                        String base64String = base64Encode(file.bytes!);
                        _controller.attachImage(base64String, file.name);
                      } else {
                        throw Exception("File data could not be read.");
                      }
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error picking file: $e")),
                    );
                  }
                },
              ),
              const Divider(color: CyberTheme.borderMuted),
              ListTile(
                leading: const Icon(Icons.image, color: CyberTheme.accent),
                title: const Text("Chest X-Ray (chest_xray.png)", style: TextStyle(color: CyberTheme.textWhite, fontSize: 12.5)),
                subtitle: const Text("Simulate X-Ray vision QA", style: TextStyle(color: CyberTheme.textGray, fontSize: 10)),
                onTap: () {
                  _controller.attachImage(
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
                    "chest_xray.png"
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology, color: CyberTheme.accent),
                title: const Text("Brain MRI Scan (brain_mri.png)", style: TextStyle(color: CyberTheme.textWhite, fontSize: 12.5)),
                subtitle: const Text("Simulate T1/T2 MRI brain scan QA", style: TextStyle(color: CyberTheme.textGray, fontSize: 10)),
                onTap: () {
                  _controller.attachImage(
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
                    "brain_mri.png"
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.airline_seat_flat, color: CyberTheme.accent),
                title: const Text("Spine CT Scan (spine_ct.png)", style: TextStyle(color: CyberTheme.textWhite, fontSize: 12.5)),
                subtitle: const Text("Simulate spinal cord reconstruction scan", style: TextStyle(color: CyberTheme.textGray, fontSize: 10)),
                onTap: () {
                  _controller.attachImage(
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
                    "spine_ct.png"
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: CyberTheme.textGray)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRightReferencePanel() {
    final citation = _controller.selectedCitation;
    if (citation == null) return const SizedBox.shrink();

    final title = citation['authors'] ?? 'Reference Paper';
    final journal = citation['journal'] ?? 'Medical Database';
    final year = citation['year']?.toString() ?? '';
    final doi = citation['doi'] ?? '';
    final url = citation['url'] ?? '';
    final section = citation['section'] ?? 'Results';
    final rawText = citation['raw_text'] ?? 'No text snippet available.';

    return Container(
      color: CyberTheme.cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.menu_book, color: CyberTheme.accent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "REFERENCE INFO",
                      style: TextStyle(
                        color: CyberTheme.textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: CyberTheme.textGray, size: 18),
                  onPressed: () => _controller.toggleRightPanel(forceOpen: false),
                  tooltip: "Close Panel",
                ),
              ],
            ),
          ),

          const Divider(color: CyberTheme.borderMuted, height: 1),

          // Evidence Badge & Title
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Evidence Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: CyberTheme.accent, width: 1.0),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Text(
                      "LEVEL 2 EVIDENCE",
                      style: TextStyle(
                        color: CyberTheme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title / Authors
                  Text(
                    title,
                    style: const TextStyle(
                      color: CyberTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Journal Details
                  Text(
                    "$journal ${year.isNotEmpty ? '($year)' : ''}",
                    style: const TextStyle(
                      color: CyberTheme.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Buttons (Abstract, Full-Text, Methodology)
                  Row(
                    children: [
                      _buildRightPanelTabButton(0, "Abstract"),
                      const SizedBox(width: 8),
                      _buildRightPanelTabButton(1, "Full-Text"),
                      const SizedBox(width: 8),
                      _buildRightPanelTabButton(2, "DOI Link"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  if (_controller.activeLiteratureTab == 0) ...[
                    const Text(
                      "SECTION ABSTRACT",
                      style: TextStyle(
                        color: CyberTheme.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Abstract snippet from the clinical study in the '$section' section of the journal paper. Discusses clinical trial outcomes, margins, or patient outcomes.",
                      style: const TextStyle(
                        color: CyberTheme.textGray,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ] else if (_controller.activeLiteratureTab == 1) ...[
                    const Text(
                      "VERBATIM TEXT SNIPPET",
                      style: TextStyle(
                        color: CyberTheme.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CyberTheme.background,
                        borderRadius: CyberTheme.softBorderRadius,
                        border: Border.all(color: CyberTheme.borderMuted),
                      ),
                      child: Text(
                        rawText,
                        style: const TextStyle(
                          color: CyberTheme.textWhite,
                          fontSize: 12.5,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "METHODOLOGY & LINKS",
                      style: TextStyle(
                        color: CyberTheme.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (doi.isNotEmpty) ...[
                      const Text(
                        "Digital Object Identifier (DOI)",
                        style: TextStyle(color: CyberTheme.textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        doi,
                        style: const TextStyle(color: CyberTheme.textGray, fontSize: 11.5),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (url.isNotEmpty) ...[
                      const Text(
                        "Source URL",
                        style: TextStyle(color: CyberTheme.textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Link copied to clipboard"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          url,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11.5,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanelTabButton(int index, String label) {
    final isSelected = _controller.activeLiteratureTab == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _controller.setLiteratureTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? CyberTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: isSelected ? CyberTheme.accent : CyberTheme.borderMuted,
                width: 1.0,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? CyberTheme.background : CyberTheme.textGray,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
