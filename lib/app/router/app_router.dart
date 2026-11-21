import 'package:go_router/go_router.dart';
import 'package:gia_pha/features/family_tree/presentation/pages/tree_page.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/presentation/pages/person_detail_page.dart';
import 'package:gia_pha/features/members/presentation/pages/person_form_page.dart';
import 'package:gia_pha/features/members/presentation/pages/person_list_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const PersonListPage()),
    GoRoute(
      path: '/tree',
      builder: (_, s) => TreePage(initialRootId: s.uri.queryParameters['root']),
    ),
    GoRoute(
      path: '/person/:id',
      builder: (_, s) => PersonDetailPage(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/form',
      builder: (_, s) {
        final q = s.uri.queryParameters;
        return PersonFormPage(
          personId: q['id'],
          anchorId: q['anchor'],
          addAs: AddAs.values.asNameMap()[q['as']],
        );
      },
    ),
  ],
);
