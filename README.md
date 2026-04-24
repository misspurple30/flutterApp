# Flutter Chat App

Application de chat en temps réel construite avec **Flutter** et **Firebase**.
Messagerie 1-à-1, envoi d'images, statut en ligne, accusés de lecture,
thème clair/sombre et interface française.

---

## ✨ Fonctionnalités

- Authentification email / mot de passe (inscription, connexion, reset)
- Liste d'utilisateurs et liste de conversations en temps réel
- Chat 1-à-1 avec Firestore (streams temps réel, bulles, séparateurs de jour)
- Envoi d'images via Firebase Storage
- Indicateur de présence (en ligne / vu il y a X)
- Compteurs de messages non lus + accusés de lecture (✓ / ✓✓)
- Photo de profil et pseudo modifiables
- Thème clair / sombre / système, avec persistance
- Design Material 3 + Google Fonts (Inter)
- Localisation française (dates, formats)

---

## 🗂 Structure du projet

```
lib/
├── main.dart                  # Point d'entrée + Provider + thème + locales
├── firebase_options.dart      # Configuration Firebase (à générer)
├── models/                    # UserModel, MessageModel, ChatRoomModel
├── services/                  # AuthService, UserService, ChatService, StorageService
├── providers/                 # ThemeProvider (ChangeNotifier)
├── screens/                   # auth_gate, login, register, home, chat, profile, settings
├── widgets/                   # UserAvatar, MessageBubble, DaySeparator
├── utils/                     # Validators, DateFormatter
└── theme/                     # AppTheme (light / dark)

firestore.rules                # Règles de sécurité Firestore
firestore.indexes.json         # Index composites requis
storage.rules                  # Règles Firebase Storage
```

---

## 🚀 Mise en route

### 1. Prérequis

- Flutter SDK ≥ 3.19
- Un compte Firebase + un projet créé sur <https://console.firebase.google.com>
- CLI : `npm install -g firebase-tools` et `dart pub global activate flutterfire_cli`

### 2. Configurer Firebase

Dans la console Firebase :

1. Activer **Authentication → Email/Password**
2. Créer une base **Firestore** en mode production
3. Activer **Cloud Storage**

Puis, depuis la racine du projet :

```bash
flutterfire configure
```

Cette commande génère automatiquement `lib/firebase_options.dart`
avec les clés de votre projet (elle remplace le template fourni).

### 3. Déployer les règles de sécurité

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 4. Installer et lancer

```bash
flutter pub get
flutter run
```

---

## 🔐 Modèle de données Firestore

```
users/{uid}
  uid, email, displayName, photoUrl,
  createdAt, lastSeen, isOnline

chatRooms/{roomId}         # roomId = uidA_uidB (triés)
  id, participants[2],
  lastMessage, lastSenderId, lastMessageTime,
  unreadCount: { uid: int }

  messages/{messageId}
    id, senderId, receiverId,
    content, type ('text' | 'image'),
    timestamp, isRead
```

L'ID de chaque salon est déterministe (`buildId` dans `ChatRoomModel`),
ce qui évite les doublons quand deux utilisateurs démarrent un chat.

L'envoi de message se fait en **transaction** pour créer la room si
nécessaire et incrémenter les compteurs de non-lus de manière atomique.

---

## 🧪 Utilisation

1. Lancez l'app et créez deux comptes (ou utilisez deux émulateurs)
2. Depuis l'onglet **Utilisateurs**, sélectionnez l'autre compte
3. Envoyez du texte ou une image
4. L'autre côté voit le message apparaître en direct, avec accusé de lecture
5. La liste **Conversations** affiche la dernière activité et les non-lus

---

## ⚠️ Notes

- `lib/firebase_options.dart` fourni est un **template**. Exécutez
  `flutterfire configure` pour y mettre vos vraies clés.
- La présence "en ligne" est gérée via les callbacks de cycle de vie Flutter
  (`didChangeAppLifecycleState`). Pour un marquage offline parfait même en cas
  de crash, un jour, ajoutez Firebase Realtime Database + `onDisconnect()`.
- Les notifications push (FCM) ne sont pas incluses dans ce build.

---

## 📄 Licence

MIT — libre à vous de réutiliser et d'adapter.
