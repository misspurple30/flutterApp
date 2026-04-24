import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _userService = UserService();
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  void _openChat(UserModel other) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(otherUser: other)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    isDense: true,
                  ),
                ),
              ),
              TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Conversations'),
                  Tab(text: 'Utilisateurs'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ConversationsTab(
            uid: _uid,
            query: _query,
            chatService: _chatService,
            userService: _userService,
            onOpenChat: _openChat,
          ),
          _UsersTab(
            uid: _uid,
            query: _query,
            userService: _userService,
            onOpenChat: _openChat,
          ),
        ],
      ),
    );
  }
}

// ---------------- Conversations tab ----------------

class _ConversationsTab extends StatelessWidget {
  final String uid;
  final String query;
  final ChatService chatService;
  final UserService userService;
  final void Function(UserModel) onOpenChat;

  const _ConversationsTab({
    required this.uid,
    required this.query,
    required this.chatService,
    required this.userService,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: chatService.watchUserChatRooms(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorState(message: snap.error.toString());
        }
        final rooms = snap.data ?? [];
        if (rooms.isEmpty) {
          return const _EmptyState(
            icon: Icons.forum_outlined,
            title: 'Aucune conversation',
            subtitle:
                "Passez à l'onglet Utilisateurs pour démarrer un nouveau chat.",
          );
        }
        return ListView.separated(
          itemCount: rooms.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
          itemBuilder: (_, i) => _ConversationTile(
            room: rooms[i],
            uid: uid,
            userService: userService,
            query: query,
            onTap: onOpenChat,
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatRoomModel room;
  final String uid;
  final UserService userService;
  final String query;
  final void Function(UserModel) onTap;

  const _ConversationTile({
    required this.room,
    required this.uid,
    required this.userService,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUid = room.otherParticipant(uid);
    return StreamBuilder<UserModel?>(
      stream: userService.watchUser(otherUid),
      builder: (context, snap) {
        final other = snap.data;
        if (other == null) return const SizedBox.shrink();
        if (query.isNotEmpty &&
            !other.displayName.toLowerCase().contains(query)) {
          return const SizedBox.shrink();
        }
        final unread = room.unreadCount[uid] ?? 0;
        final isMe = room.lastSenderId == uid;
        final preview =
            isMe ? 'Vous : ${room.lastMessage}' : room.lastMessage;

        return ListTile(
          onTap: () => onTap(other),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: UserAvatar(
            photoUrl: other.photoUrl,
            displayName: other.displayName,
            radius: 26,
            showOnlineIndicator: true,
            isOnline: other.isOnline,
          ),
          title: Text(
            other.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread > 0
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey,
              fontWeight:
                  unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormatter.listPreview(room.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: unread > 0 ? AppColors.primary : Colors.grey,
                  fontWeight:
                      unread > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- Users tab ----------------

class _UsersTab extends StatelessWidget {
  final String uid;
  final String query;
  final UserService userService;
  final void Function(UserModel) onOpenChat;

  const _UsersTab({
    required this.uid,
    required this.query,
    required this.userService,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: userService.watchAllOtherUsers(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorState(message: snap.error.toString());
        }
        var users = snap.data ?? [];
        if (query.isNotEmpty) {
          users = users
              .where((u) =>
                  u.displayName.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query))
              .toList();
        }
        if (users.isEmpty) {
          return const _EmptyState(
            icon: Icons.group_outlined,
            title: 'Aucun utilisateur',
            subtitle: "Aucun autre utilisateur ne correspond.",
          );
        }
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              onTap: () => onOpenChat(u),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              leading: UserAvatar(
                photoUrl: u.photoUrl,
                displayName: u.displayName,
                radius: 26,
                showOnlineIndicator: true,
                isOnline: u.isOnline,
              ),
              title: Text(
                u.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                u.isOnline
                    ? 'En ligne'
                    : 'Vu ${DateFormatter.lastSeen(u.lastSeen)}',
                style: TextStyle(
                  color: u.isOnline ? Colors.green : Colors.grey,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary),
            );
          },
        );
      },
    );
  }
}

// ---------------- Shared placeholders ----------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
