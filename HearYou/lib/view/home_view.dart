import 'package:flutter/material.dart';

class HomeViewModel {
  final String userName;
  final String userPhotoUrl;
  final List<Map<String, dynamic>> items;
  final List<String> sliderImages;
  final int currentImageIndex;
  final List<String> agentSuggestions;
  final TextEditingController agentController;
  final bool agentLoading;
  final String? agentAnswer;
  final GlobalKey cameraKey;
  final GlobalKey alertsKey;
  final GlobalKey eventsKey;
  final GlobalKey sosKey;
  final GlobalKey sliderKey;

  const HomeViewModel({
    required this.userName,
    required this.userPhotoUrl,
    required this.items,
    required this.sliderImages,
    required this.currentImageIndex,
    required this.agentSuggestions,
    required this.agentController,
    required this.agentLoading,
    required this.agentAnswer,
    required this.cameraKey,
    required this.alertsKey,
    required this.eventsKey,
    required this.sosKey,
    required this.sliderKey,
  });
}

class HomeAssistantPanel extends StatelessWidget {
  final bool isDarkMode;
  final HomeViewModel model;
  final void Function(String? text) onSendAgentCommand;

  const HomeAssistantPanel({
    super.key,
    required this.isDarkMode,
    required this.model,
    required this.onSendAgentCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FractionallySizedBox(
        heightFactor: 0.6,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? const [Color(0xFF1F1A24), Color(0xFF2A2234)]
                  : const [Color(0xFFF7F3FF), Color(0xFFEDE6FF)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDarkMode
                  ? Colors.deepPurpleAccent.withOpacity(0.25)
                  : const Color(0xFFE5D6F8),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.6)
                    : const Color(0xFFB388FF).withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent,
                          Color(0xFF7E57C2),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  if (model.agentLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: model.agentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSendAgentCommand(null),
                      decoration: InputDecoration(
                        hintText: 'Ask to change settings... ',
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF2B2234) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: model.agentLoading ? null : () => onSendAgentCommand(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
              if (model.agentAnswer != null && model.agentAnswer!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2B2234) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.deepPurpleAccent.withOpacity(0.25)
                          : const Color(0xFFE5D6F8),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    model.agentAnswer!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: model.agentSuggestions.map((s) {
                  return ActionChip(
                    label: Text(s),
                    onPressed: model.agentLoading ? null : () => onSendAgentCommand(s),
                    backgroundColor: isDarkMode ? const Color(0xFF2B2234) : Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isDarkMode
                            ? Colors.deepPurpleAccent.withOpacity(0.25)
                            : const Color(0xFFE5D6F8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreenView extends StatelessWidget {
  final HomeViewModel model;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenSettings;
  final void Function(int index) onGridTap;
  final VoidCallback onOpenAssistantPanel;

  const HomeScreenView({
    super.key,
    required this.model,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenSettings,
    required this.onGridTap,
    required this.onOpenAssistantPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: model.userPhotoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        model.userPhotoUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: Colors.grey[600]);
                        },
                      ),
                    )
                  : Icon(Icons.person, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            if (model.userName.isNotEmpty)
              Text(
                model.userName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
          ],
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: onToggleTheme,
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.all(50.0)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Card(
                      key: model.sliderKey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          model.sliderImages[model.currentImageIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: model.items.length,
                    itemBuilder: (context, index) {
                      final item = model.items[index];
                      final key = item['title'] == 'Camera'
                          ? model.cameraKey
                          : item['title'] == 'Alerts'
                              ? model.alertsKey
                              : item['title'] == 'Events'
                                  ? model.eventsKey
                                  : item['title'] == 'SOS'
                                      ? model.sosKey
                                      : null;
                      return InkWell(
                        onTap: () => onGridTap(index),
                        child: Card(
                          key: key,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDarkMode
                                    ? const [Color(0xFF1F1A24), Color(0xFF2A2234)]
                                    : const [Colors.white, Color(0xFFF7ECFF)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.deepPurpleAccent.withOpacity(0.25)
                                    : const Color(0xFFE5D6F8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.transparent
                                      : const Color(0xFFB388FF).withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurpleAccent,
                                        Color(0xFF7E57C2),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    item['title'] == 'Camera'
                                        ? Icons.photo_camera
                                        : item['title'] == 'Alerts'
                                            ? Icons.notifications_active
                                            : item['title'] == 'Events'
                                                ? Icons.event_note
                                                : Icons.emergency,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Material(
                color: isDarkMode ? Colors.deepPurpleAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                elevation: 6,
                child: isDarkMode
                    ? InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onOpenAssistantPanel,
                        child: const Center(
                          child: Icon(Icons.auto_awesome, color: Colors.white),
                        ),
                      )
                    : Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF0B8F6), Color(0xFFE0C4FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onOpenAssistantPanel,
                          child: const Center(
                            child: Icon(Icons.auto_awesome, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


