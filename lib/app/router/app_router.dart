import 'package:go_router/go_router.dart';
import 'package:gia_pha/app/shell/app_shell.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/presentation/pages/article_edit_page.dart';
import 'package:gia_pha/features/articles/presentation/pages/article_list_page.dart';
import 'package:gia_pha/features/articles/presentation/pages/article_read_page.dart';
import 'package:gia_pha/features/contacts/presentation/pages/contacts_page.dart';
import 'package:gia_pha/features/family_tree/presentation/pages/tree_page.dart';
import 'package:gia_pha/features/heirlooms/presentation/pages/heirlooms_page.dart';
import 'package:gia_pha/features/home/presentation/pages/home_page.dart';
import 'package:gia_pha/features/honors/presentation/pages/honor_list_page.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/presentation/pages/person_detail_page.dart';
import 'package:gia_pha/features/members/presentation/pages/person_form_page.dart';
import 'package:gia_pha/features/members/presentation/pages/person_list_page.dart';
import 'package:gia_pha/features/members/presentation/pages/sibling_order_page.dart';
import 'package:gia_pha/features/settings/presentation/pages/settings_page.dart';

ArticleKind _kind(GoRouterState s) =>
    ArticleKind.values.byName(s.pathParameters['kind']!);

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 4 tab chính, có thanh điều hướng dưới.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/members', builder: (_, __) => const PersonListPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/documents',
            builder: (_, __) => const HeirloomsPage(title: 'Tư liệu'),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ]),
      ],
    ),

    // Các trang phủ toàn màn hình.
    GoRoute(
      path: '/tree',
      builder: (_, s) => TreePage(initialRootId: s.uri.queryParameters['root']),
    ),
    GoRoute(
      path: '/person/:id',
      builder: (_, s) => PersonDetailPage(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/person/:id/children',
      builder: (_, s) => SiblingOrderPage(parentId: s.pathParameters['id']!),
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
    GoRoute(path: '/honors', builder: (_, __) => const HonorListPage()),
    GoRoute(path: '/heirlooms', builder: (_, __) => const HeirloomsPage()),
    GoRoute(path: '/contacts', builder: (_, __) => const ContactsPage()),
    GoRoute(
      path: '/articles/:kind',
      builder: (_, s) => ArticleListPage(kind: _kind(s)),
    ),
    GoRoute(
      path: '/articles/:kind/new',
      builder: (_, s) => ArticleEditPage(kind: _kind(s)),
    ),
    GoRoute(
      path: '/articles/:kind/:id',
      builder: (_, s) =>
          ArticleReadPage(kind: _kind(s), id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/articles/:kind/:id/edit',
      builder: (_, s) =>
          ArticleEditPage(kind: _kind(s), id: s.pathParameters['id']!),
    ),
  ],
);
