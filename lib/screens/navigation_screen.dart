import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/home_screen.dart';
import 'package:event_buddy/screens/my_events_content.dart';
import 'package:event_buddy/screens/profile_screen.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedPageIndexProvider = NotifierProvider<SelectedPageNotifier, int>(
  SelectedPageNotifier.new,
);

class SelectedPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int index) {
    state = index;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final eventSearchProvider =
    FutureProvider.family<List<QueryDocumentSnapshot>, String>((
      ref,
      query,
    ) async {
      if (query.isEmpty) return [];

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('events')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs;
    });

class NavigationScreen extends ConsumerWidget {
  final bool? isOrganizer;
  final String userName;

  const NavigationScreen({super.key, required this.userName, this.isOrganizer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedPageIndexProvider);

    final pages = [
      HomeScreen(isOrganizer: isOrganizer ?? true),
      MyEventsContent(isOrganizer: isOrganizer ?? true),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.card,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: selectedIndex,
          onTap: (index) {
            ref.read(selectedPageIndexProvider.notifier).setPage(index);
          },
        ),
      ),
    );
  }
}

// class CustomSearchDelegate extends SearchDelegate {
//   final WidgetRef ref;
//   final bool? isOrganizer;

//   CustomSearchDelegate({required this.ref, this.isOrganizer});

//   @override
//   ThemeData appBarTheme(BuildContext context) {
//     final theme = Theme.of(context);
//     return theme.copyWith(
//       appBarTheme: const AppBarTheme(
//         backgroundColor: AppColors.card,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.white),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         hintStyle: const TextStyle(color: Colors.white70),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30),
//           borderSide: BorderSide.none,
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide.none,
//         ),
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.2),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//         constraints: const BoxConstraints(
//           maxWidth: double.infinity,
//           minHeight: 40,
//         ),
//       ),
//       textTheme: theme.textTheme.copyWith(
//         titleLarge: const TextStyle(color: Colors.white, fontSize: 18),
//       ),
//     );
//   }

//   @override
//   List<Widget>? buildActions(BuildContext context) {
//     return [
//       if (query.isNotEmpty)
//         IconButton(
//           icon: const Icon(Icons.clear),
//           onPressed: () {
//             query = '';
//             ref.read(searchQueryProvider.notifier).clear();
//           },
//         ),
//     ];
//   }

//   @override
//   Widget? buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () => close(context, null),
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     if (query.isEmpty) {
//       return const Center(
//         child: Text(
//           'Search events...',
//           style: TextStyle(
//             fontSize: 16,
//             color: Color.fromRGBO(113, 128, 150, 1.0),
//           ),
//         ),
//       );
//     }

//     return Consumer(
//       builder: (context, ref, child) {
//         final searchResults = ref.watch(eventSearchProvider(query));

//         return searchResults.when(
//           data: (results) {
//             if (results.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No events found.',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Color.fromRGBO(113, 128, 150, 1.0),
//                   ),
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: results.length,
//               itemBuilder: (context, index) {
//                 var event = results[index];
//                 var data = event.data() as Map<String, dynamic>;

//                 return Card(
//                   margin: const EdgeInsets.symmetric(
//                     vertical: 6,
//                     horizontal: 8,
//                   ),
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.all(12),
//                     leading: Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         color: const Color.fromRGBO(102, 126, 234, 0.1),
//                       ),
//                       child: const Icon(
//                         Icons.event,
//                         color: Color.fromRGBO(102, 126, 234, 1.0),
//                       ),
//                     ),
//                     title: Text(
//                       data['name'] ?? 'No Name',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 15,
//                       ),
//                     ),
//                     subtitle: Text(
//                       data['description'] ?? '',
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontSize: 13),
//                     ),
//                     onTap: () {
//                       close(context, null);
//                       context.push('/event/${event.id}', extra: event);
//                     },
//                   ),
//                 );
//               },
//             );
//           },
//           loading: () => const Center(
//             child: CircularProgressIndicator(
//               color: Color.fromRGBO(102, 126, 234, 1.0),
//             ),
//           ),
//           error: (error, stack) => Center(
//             child: Text(
//               'Error: ${error.toString()}',
//               style: const TextStyle(color: Colors.red),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     if (query.isEmpty) {
//       return const Center(
//         child: Text(
//           'Type to search events...',
//           style: TextStyle(
//             fontSize: 16,
//             color: Color.fromRGBO(113, 128, 150, 1.0),
//           ),
//         ),
//       );
//     }

//     return Consumer(
//       builder: (context, ref, child) {
//         final searchResults = ref.watch(eventSearchProvider(query));

//         return searchResults.when(
//           data: (results) {
//             if (results.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No matching events found.',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Color.fromRGBO(113, 128, 150, 1.0),
//                   ),
//                 ),
//               );
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: results.length,
//               itemBuilder: (context, index) {
//                 var event = results[index];
//                 var data = event.data() as Map<String, dynamic>;

//                 return Card(
//                   margin: const EdgeInsets.symmetric(
//                     vertical: 6,
//                     horizontal: 8,
//                   ),
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.all(12),
//                     leading: Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         color: const Color.fromRGBO(102, 126, 234, 0.1),
//                       ),
//                       child: const Icon(
//                         Icons.event,
//                         color: Color.fromRGBO(102, 126, 234, 1.0),
//                       ),
//                     ),
//                     title: Text(
//                       data['name'] ?? 'No Name',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 15,
//                       ),
//                     ),
//                     subtitle: Text(
//                       data['description'] ?? '',
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontSize: 13),
//                     ),
//                     onTap: () {
//                       close(context, null);
//                       context.push('/event/${event.id}', extra: event);
//                     },
//                   ),
//                 );
//               },
//             );
//           },
//           loading: () => const Center(
//             child: CircularProgressIndicator(
//               color: Color.fromRGBO(102, 126, 234, 1.0),
//             ),
//           ),
//           error: (error, stack) => Center(
//             child: Text(
//               'Error: ${error.toString()}',
//               style: const TextStyle(color: Colors.red),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget buildImage(String? base64String) {
//     if (base64String == null || base64String.isEmpty) {
//       return const Icon(Icons.image_not_supported);
//     }
//     try {
//       Uint8List bytes = base64Decode(base64String);
//       return Image.memory(bytes, fit: BoxFit.cover);
//     } catch (e) {
//       return const Icon(Icons.error);
//     }
//   }
// }

// extension SearchExtension on WidgetRef {
//   void showEventSearch(BuildContext context, bool? isOrganizer) {
//     showSearch(
//       context: context,
//       delegate: CustomSearchDelegate(ref: this, isOrganizer: isOrganizer),
//     );
//   }
// }
