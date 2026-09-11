import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:vcare_admin/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:vcare_admin/features/auth/presentation/pages/admin_login_screen.dart';
import 'package:vcare_admin/features/auth/presentation/pages/register_screen.dart';
// AVA tab disabled — restore when AVA returns to the bottom nav.
// import 'package:vcare_admin/features/ava/presentation/pages/ava_screen.dart';
import 'package:vcare_admin/features/cases/presentation/pages/case_create_screen.dart';
import 'package:vcare_admin/features/cases/presentation/pages/case_detail_screen.dart';
import 'package:vcare_admin/features/cases/presentation/pages/cases_screen.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/clients/presentation/pages/client_case_create_screen.dart';
import 'package:vcare_admin/features/clients/presentation/pages/client_detail_screen.dart';
import 'package:vcare_admin/features/clients/presentation/pages/clients_screen.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/find_care_category_screen.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/find_care_screen.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/find_care_search_screen.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/medicare_provider_detail_screen.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/medicare_provider_lookup_screen.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/provider_detail_screen.dart';
import 'package:vcare_admin/features/find_care/presentation/pages/saved_providers_screen.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/pages/admin_failed_payments_screen.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/pages/admin_todo_list_screen.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/pages/pending_memberships_screen.dart';
import 'package:vcare_admin/features/home/presentation/pages/card_edit_screen.dart';
import 'package:vcare_admin/features/care_team/presentation/pages/care_team_detail_screen.dart';
import 'package:vcare_admin/features/care_team/presentation/pages/care_team_edit_screen.dart';
import 'package:vcare_admin/features/care_team/presentation/pages/care_team_screen.dart';
import 'package:vcare_admin/features/home/presentation/pages/home_activity_screen.dart';
import 'package:vcare_admin/features/home/presentation/pages/home_screen.dart';
import 'package:vcare_admin/features/home/presentation/pages/id_card_screen.dart';
import 'package:vcare_admin/features/commission/presentation/pages/commission_detail_screen.dart';
import 'package:vcare_admin/features/loadable_list_demo/presentation/pages/loadable_list_demo_screen.dart';
import 'package:vcare_admin/features/messages/presentation/pages/live_chat_screen.dart';
// My Family disabled — restore when family members return to Profile.
// import 'package:vcare_admin/features/profile/presentation/pages/family_member_edit_screen.dart';
import 'package:vcare_admin/features/account/presentation/pages/account_change_password_screen.dart';
import 'package:vcare_admin/features/account/presentation/pages/account_edit_screen.dart';
import 'package:vcare_admin/features/profile/presentation/pages/profile_screen.dart';
import 'package:vcare_admin/features/main_wrapper/presentation/pages/main_wrapper_screen.dart';
import 'package:vcare_admin/features/settings/presentation/pages/dynamic_theme_settings_screen.dart';
import 'package:vcare_admin/features/settings/presentation/pages/languages_settings_screen.dart';
import 'package:vcare_admin/features/settings/presentation/pages/settings_screen.dart';
import 'package:vcare_admin/features/splash/presentation/pages/vcare_splash_screen.dart';
import 'package:vcare_admin/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:vcare_admin/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:vcare_admin/features/documents/presentation/pages/documents_screen.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/vcare_sync/presentation/pages/vcare_parity_screens.dart'
    hide CareTeamEditScreen, FindCareCategoryScreen, NotificationsScreen;

class AppRouter {
  static const splash = "/splash";
  static const onboarding = "/onboarding";
  static const login = "/login";
  static const register = "/register";
  static const forgotPassword = "/forgot_password";
  static const resetPassword = "/reset-password";
  static const home = "/home";
  static const clients = "/clients";
  static const clientDetail = "/clients/:id";
  static const clientCaseCreate = "/clients/:id/cases/create";
  // Mock advocate requests replaced by Cases tab — constants kept commented
  // for reference if deep-links need restoration.
  // static const requests = "/requests";
  // static const requestDetail = "/requests/:id";
  // static const requestNew = "/requests/new";
  static const cases = "/cases";
  static const caseCreate = "/cases/create";
  static const caseDetail = "/cases/:id";
  static const findCare = "/find-care";
  static const findCareCategory = "/find-care/category/:slug";
  static const findCareSearch = "/find-care/search";
  static const costLookup = "/find-care/cost";
  static const medicareProviderLookup = "/find-care/medicare-providers";
  static const medicareProviderDetail = "/provider/medicare/:npi";
  static const providerDetail = "/provider/:id";
  static const procedureDetail = "/procedure/:id";
  static const messages = "/messages";
  static const groupChat = "/groups/:id";
  static const groupInfo = "/groups/:id/info";
  static const ava = "/ava";
  static const profile = "/profile";
  static const documents = "/profile/documents";
  // My Family disabled — restore when family members return to Profile.
  // static const familyMemberNew = "/profile/family/new";
  // static const familyMemberEdit = "/profile/family/:id";
  static const profileEdit = "/profile/edit";
  static const profilePassword = "/profile/password";
  // Address edit removed from Profile — agent leftover route kept commented.
  // static const profileAddress = "/profile/address";
  static const helpSupport = "/help";
  static const privacySecurity = "/privacy-security";
  static const notifications = "/notifications";
  static const languages = "/languages";
  static const dynamicTheme = "/dynamic_theme";
  static const settings = "/settings";
  static const loadableListDemo = "/loadable_list_demo";
  static const idCard = "/id-card";
  static const careTeam = "/care-team";
  static const careTeamDetail = "/care-team/:id";
  static const activity = "/activity";
  static const sales = "/sales";
  static const savedProviders = "/profile/saved-providers";
  static const idCardNew = "/id-card/new";
  static const idCardEdit = "/id-card/:id";
  static const careTeamNew = "/care-team/new";
  static const careTeamEdit = "/care-team/:id/edit";
  static const idCardName = "id-card";
  static const idCardNewName = "id-card-new";
  static const idCardEditName = "id-card-edit";
  static const careTeamName = "care-team";
  static const careTeamNewName = "care-team-new";
  static const careTeamEditName = "care-team-edit";
  static const careTeamDetailName = "care-team-detail";
  static const activityName = "activity";
  static const adminFailedPaymentsName = "admin-failed-payments";
  static const adminTodoListName = "admin-todo-list";
  static const pendingMembershipsName = "pending-memberships";
  static const salesName = "sales";
  static const homeSalesName = "home-sales";
  static const savedProvidersName = "saved-providers";
  static const clientsName = "clients";
  static const clientDetailName = "client-detail";
  static const clientCaseCreateName = "client-case-create";
  // static const requestNewName = "request-new";
  // static const requestDetailName = "request-detail";
  static const caseCreateName = "case-create";
  static const caseDetailName = "case-detail";
  static const findCareCategoryName = "find-care-category";
  static const findCareSearchName = "find-care-search";
  static const costLookupName = "cost-lookup";
  static const medicareProviderLookupName = "medicare-provider-lookup";
  static const medicareProviderDetailName = "medicare-provider-detail";
  static const providerDetailName = "provider-detail";
  static const procedureDetailName = "procedure-detail";
  static const groupChatName = "group-chat";
  static const groupInfoName = "group-info";
  static const documentsName = "documents";
  // My Family disabled — restore when family members return to Profile.
  // static const familyMemberNewName = "family-member-new";
  // static const familyMemberEditName = "family-member-edit";
  static const profileEditName = "profile-edit";
  static const profilePasswordName = "profile-password";
  // static const profileAddressName = "profile-address";
  static const helpSupportName = "help-support";
  static const privacySecurityName = "privacy-security";
  static const notificationsName = "notifications";

  static String toName(String path) => path.replaceFirst("/", "");

  /// Drives GoRouter to re-run [_redirect] when the session is cleared.
  ///
  /// Without this, an automatic (token-expiry) logout only clears session data
  /// but never removes the [StatefulShellRoute] from the page stack.
  static final AppRouterRefreshNotifier refreshNotifier =
      AppRouterRefreshNotifier();

  static AppRouterSession? _session;
  static bool _sessionStarted = false;

  /// The session backing the widget tree that is currently mounted.
  static AppRouterSession get session =>
      _session ??= AppRouterSession(initialLocation: splash);

  /// Router for the current session.
  static GoRouter get router => session.router;

  /// Root Navigator Key
  static GlobalKey<NavigatorState> get rootNavigatorKey =>
      session.rootNavigatorKey;

  /// Navigator key for root Shell Route
  static GlobalKey<NavigatorState> get shellNavigatorKey =>
      session.shellNavigatorKey;

  /// Replaces the active session with one that owns freshly built routes.
  ///
  /// [StatefulShellRoute] creates a single
  /// `GlobalKey<StatefulNavigationShellState>` when it is constructed and
  /// reuses it for every shell it ever builds. When one router outlives a
  /// sign-out, signing back in can mount a second shell under that same key
  /// while the previous one is still leaving — Flutter cannot reuse a route
  /// that is not `willBePresent`, so it builds a new one — and that throws
  /// "Duplicate GlobalKey" followed by element lifecycle assertions on every
  /// later frame. Handing each sign-in its own router makes the collision
  /// impossible because the new shell key has never been mounted.
  ///
  /// The first call adopts the boot session, which starts at [splash] so the
  /// splash screen can decide where to go. Later calls are made in response to
  /// a sign-in, so they land where the user belongs.
  static AppRouterSession startSession({required bool loggedIn}) {
    if (!_sessionStarted) {
      _sessionStarted = true;
      return session;
    }
    return _session = AppRouterSession(
      initialLocation: loggedIn ? home : login,
    );
  }

  static String? _redirect(BuildContext context, GoRouterState state) {
    final unprotected = [
      splash,
      onboarding,
      login,
      register,
      forgotPassword,
      resetPassword,
    ];

    if (state.matchedLocation == onboarding) {
      return login;
    }

    if (unprotected.contains(state.matchedLocation)) {
      return null;
    }

    final container = ProviderScope.containerOf(context);
    final loggedIn = container.read(userLoggedInStateProvider);
    if (loggedIn) return null;
    return login;
  }

  static List<RouteBase> _buildRoutes() {
    return [
      GoRoute(
        path: splash,
        name: toName(splash),
        pageBuilder: (_, state) =>
            _pageBuilder(state: state, child: const VcareSplashScreen()),
      ),
      GoRoute(
        path: onboarding,
        name: toName(onboarding),
        pageBuilder: (_, state) =>
            _pageBuilder(state: state, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: login,
        name: toName(login),
        pageBuilder: (_, state) =>
            _pageBuilder(state: state, child: const AdminLoginScreen()),
      ),
      GoRoute(
        path: register,
        name: toName(register),
        pageBuilder: (_, state) =>
            _pageBuilder(state: state, child: const RegisterScreen()),
      ),
      GoRoute(
        path: forgotPassword,
        name: toName(forgotPassword),
        pageBuilder: (_, state) =>
            _pageBuilder(state: state, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: resetPassword,
        name: toName(resetPassword),
        pageBuilder: (_, state) => _pageBuilder(
          state: state,
          child: ResetPasswordScreen(
            token: state.uri.queryParameters['token'],
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) =>
            MainWrapperScreen(shell: shell, state: state),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: clients,
                name: clientsName,
                pageBuilder: (_, state) =>
                    _pageBuilder(state: state, child: const ClientsScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: clientDetailName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: ClientDetailScreen(
                        clientId: state.pathParameters['id'] ?? '',
                        clientType:
                            state.uri.queryParameters['clientType']
                                    ?.toUpperCase() ==
                                'GROUP'
                            ? ClientListType.group
                            : ClientListType.individual,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'cases/create',
                        name: clientCaseCreateName,
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: ClientCaseCreateScreen(
                            clientId: state.pathParameters['id'] ?? '',
                            prefillClient: state.extra is CaseCreationClient
                                ? state.extra as CaseCreationClient
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: cases,
                name: toName(cases),
                pageBuilder: (_, state) =>
                    _pageBuilder(state: state, child: const CasesScreen()),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: caseCreateName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const CaseCreateScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    name: caseDetailName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: CaseDetailScreen(
                        caseId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Providers/Find-care tab replaced by Cases. Find-care routes remain
          // reachable as top-level GoRoutes outside the shell.
          // Sales tab replaced by Provider. Commission/sales remain under Home
          // via [homeSalesName] (`/home/sales`).
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: sales,
          //       name: salesName,
          //       pageBuilder: (_, state) => _pageBuilder(
          //         state: state,
          //         child: const CommissionDetailScreen(),
          //       ),
          //     ),
          //   ],
          // ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: home,
                name: toName(home),
                pageBuilder: (_, state) =>
                    _pageBuilder(state: state, child: const HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'id-card',
                    name: idCardName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const IdCardScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: idCardNewName,
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: const CardEditScreen(),
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        name: idCardEditName,
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: CardEditScreen(
                            cardId: state.pathParameters['id'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'care-team',
                    name: careTeamName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const CareTeamScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: careTeamNewName,
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: const CareTeamEditScreen(),
                        ),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        name: careTeamEditName,
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: CareTeamEditScreen(
                            memberId: state.pathParameters['id'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'activity',
                    name: activityName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const HomeActivityScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'failed-payments',
                    name: adminFailedPaymentsName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const AdminFailedPaymentsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'todo-list',
                    name: adminTodoListName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const AdminTodoListScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'pending-memberships',
                    name: pendingMembershipsName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const PendingMembershipsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'sales',
                    name: homeSalesName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const CommissionDetailScreen(showBack: true),
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: notificationsName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const NotificationsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: toName(settings),
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const SettingsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'languages',
                        name: toName(languages),
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: const LanguagesSettingsScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'dynamic_theme',
                        name: toName(dynamicTheme),
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: const DynamicThemeSettingsScreen(),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'help',
                    name: helpSupportName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const HelpSupportScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'privacy-security',
                    name: privacySecurityName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const PrivacySecurityScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'loadable_list_demo',
                    name: toName(loadableListDemo),
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const LoadableListDemoScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: messages,
                name: toName(messages),
                pageBuilder: (_, state) => _pageBuilder(
                  state: state,
                  child: LiveChatScreen(
                    openNewChat: state.uri.queryParameters['newChat'] == '1',
                    peerUserId: state.uri.queryParameters['userId'],
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'care-team/:id',
                    name: careTeamDetailName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: CareTeamDetailScreen(
                        memberId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:id',
                    name: groupChatName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: GroupChatScreen(
                        groupId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'info',
                        name: groupInfoName,
                        pageBuilder: (_, state) => _pageBuilder(
                          state: state,
                          transitionType: TransitionType.slide,
                          child: GroupInfoScreen(
                            groupId: state.pathParameters['id'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: profile,
                name: toName(profile),
                pageBuilder: (_, state) =>
                    _pageBuilder(state: state, child: const ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: profileEditName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const AccountEditScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'password',
                    name: profilePasswordName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: const AccountChangePasswordScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'documents',
                    name: documentsName,
                    pageBuilder: (_, state) => _pageBuilder(
                      state: state,
                      transitionType: TransitionType.slide,
                      child: DocumentsScreen(
                        initialDocumentId:
                            state.uri.queryParameters['documentId'],
                        initialDocumentSource:
                            state.uri.queryParameters['documentSource'] ??
                            state.uri.queryParameters['source'],
                        openDocumentOnLoad:
                            state.uri.queryParameters['openDocument'] == 'true' ||
                            state.uri.queryParameters['open'] == 'true',
                        initialFileName: state.uri.queryParameters['fileName'],
                      ),
                    ),
                  ),
                  // My Family disabled — restore when family members return to Profile.
                  // GoRoute(
                  //   path: 'family/new',
                  //   name: familyMemberNewName,
                  //   pageBuilder: (_, state) => _pageBuilder(
                  //     state: state,
                  //     transitionType: TransitionType.slide,
                  //     child: const FamilyMemberEditScreen(),
                  //   ),
                  // ),
                  // GoRoute(
                  //   path: 'family/:id',
                  //   name: familyMemberEditName,
                  //   pageBuilder: (_, state) => _pageBuilder(
                  //     state: state,
                  //     transitionType: TransitionType.slide,
                  //     child: FamilyMemberEditScreen(
                  //       memberId: state.pathParameters['id'],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          // AVA tab disabled — restore when AVA returns to the bottom nav.
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: ava,
          //       name: toName(ava),
          //       pageBuilder: (_, state) =>
          //           _pageBuilder(state: state, child: const AvaScreen()),
          //     ),
          //   ],
          // ),
        ],
      ),
      // Find-care moved outside the shell (Providers tab replaced by Cases).
      GoRoute(
        path: findCare,
        name: toName(findCare),
        pageBuilder: (_, state) => _pageBuilder(
          state: state,
          transitionType: TransitionType.slide,
          child: const FindCareScreen(),
        ),
        routes: [
          GoRoute(
            path: 'category/:slug',
            name: findCareCategoryName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: FindCareCategoryScreen(
                slug: state.pathParameters['slug'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: 'search',
            name: findCareSearchName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: FindCareSearchScreen(
                initialQuery: state.uri.queryParameters['q'],
              ),
            ),
          ),
          GoRoute(
            path: 'cost',
            name: costLookupName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: const CostLookupScreen(),
            ),
          ),
          GoRoute(
            path: 'medicare-providers',
            name: medicareProviderLookupName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: const MedicareProviderLookupScreen(),
            ),
          ),
          GoRoute(
            path: 'provider/medicare/:npi',
            name: medicareProviderDetailName,
            pageBuilder: (_, state) {
              final extra = state.extra;
              MedicareProviderLookupRow? passedRow;
              Map<String, String>? passedRaw;
              if (extra is Map) {
                final row = extra['row'];
                final raw = extra['raw'];
                if (row is MedicareProviderLookupRow) {
                  passedRow = row;
                }
                if (raw is Map) {
                  passedRaw = raw.map(
                    (key, value) => MapEntry(
                      key.toString(),
                      value.toString(),
                    ),
                  );
                }
              }
              return _pageBuilder(
                state: state,
                transitionType: TransitionType.slide,
                child: MedicareProviderDetailScreen(
                  npi: state.pathParameters['npi'] ?? '',
                  passedRow: passedRow,
                  passedRaw: passedRaw,
                ),
              );
            },
          ),
          GoRoute(
            path: 'provider/:id',
            name: providerDetailName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: ProviderDetailScreen(
                providerId: state.pathParameters['id'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: 'procedure/:id',
            name: procedureDetailName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: ProcedureDetailScreen(
                procedureId: state.pathParameters['id'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: 'saved-providers',
            name: savedProvidersName,
            pageBuilder: (_, state) => _pageBuilder(
              state: state,
              transitionType: TransitionType.slide,
              child: const SavedProvidersScreen(),
            ),
          ),
        ],
      ),
    ];
  }

  /// Page builder helper function
  static Page<T> _pageBuilder<T>({
    required GoRouterState state,
    required Widget child,
    TransitionType transitionType = TransitionType.none,
  }) {
    if (transitionType == TransitionType.none) {
      // Navigator skips null-keyed pages when matching new pages to existing
      // routes, and `Page.canUpdate` only compares runtime type and key — so
      // keyless pages of the same type are indistinguishable to it.
      return NoTransitionPage<T>(key: state.pageKey, child: child);
    }

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        if (transitionType == TransitionType.scale) {
          return ScaleTransition(scale: animation, child: child);
        }

        if (transitionType == TransitionType.fade) {
          return FadeTransition(opacity: animation, child: child);
        }

        if (transitionType == TransitionType.slide) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.5, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        }

        return AlignTransition(
          alignment: animation.drive(
            Tween(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
            ).chain(CurveTween(curve: Curves.ease)),
          ),
          child: child,
        );
      },
    );
  }
}

/// Transition type for route
enum TransitionType { slide, scale, fade, align, none }

/// One router and its navigator keys, scoped to a single sign-in.
///
/// Everything here is per-instance on purpose. Route objects must not be shared
/// between sessions: see [AppRouter.startSession].
class AppRouterSession {
  AppRouterSession({required String initialLocation})
    : rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavigator'),
      shellNavigatorKey = GlobalKey<NavigatorState>(
        debugLabel: 'shellNavigator',
      ) {
    router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      refreshListenable: AppRouter.refreshNotifier,
      redirect: AppRouter._redirect,
      routes: AppRouter._buildRoutes(),
    );
  }

  final GlobalKey<NavigatorState> rootNavigatorKey;
  final GlobalKey<NavigatorState> shellNavigatorKey;
  late final GoRouter router;
}

/// Lightweight [Listenable] used as the router's `refreshListenable`.
///
/// Call [refresh] when the authenticated session is cleared so GoRouter
/// re-evaluates redirects and disposes the [StatefulShellRoute].
class AppRouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
