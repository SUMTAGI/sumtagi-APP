import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/home/home_screen.dart';
import '../screens/travel/travel_screen.dart';
import '../screens/islands/islands_screen.dart';
import '../screens/islands/island_detail_screen.dart';
import '../screens/my_page/my_page_screen.dart';
import '../screens/sub/create_trip_screen.dart';
import '../screens/sub/itinerary_screen.dart';
import '../screens/sub/checklist_screen.dart';
import '../screens/sub/budget_screen.dart';
import '../screens/sub/community_screen.dart';
import '../screens/sub/emergency_screen.dart';
import '../screens/sub/schedule_screen.dart';
import '../screens/sub/group_trip_screen.dart';
import '../screens/sub/group_join_screen.dart';
import '../screens/sub/community_write_screen.dart';
import '../screens/sub/app_settings_screen.dart';
import '../screens/sub/support_screen.dart';
import '../screens/sub/experiences_screen.dart';
import '../screens/sub/profile_edit_screen.dart';
import '../screens/sub/notification_settings_screen.dart';
import '../screens/sub/payment_methods_screen.dart';
import '../screens/sub/favorites_screen.dart';
import '../screens/sub/notifications_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/travel',
          builder: (context, state) => const TravelScreen(),
        ),
        GoRoute(
          path: '/islands',
          builder: (context, state) => const IslandsScreen(),
        ),
        GoRoute(
          path: '/my',
          builder: (context, state) => const MyPageScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/island/:id',
      builder: (context, state) => IslandDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/create-trip',
      builder: (context, state) => CreateTripScreen(
        preSelectedIsland: state.uri.queryParameters['name'],
      ),
    ),
    GoRoute(
      path: '/itinerary/:id',
      builder: (context, state) => ItineraryScreen(
        id: state.pathParameters['id']!,
        startInEditMode: state.uri.queryParameters['edit'] == 'true',
      ),
    ),
    GoRoute(
      path: '/checklist',
      builder: (context, state) => ChecklistScreen(
        tripId: state.uri.queryParameters['tripId'],
      ),
    ),
    GoRoute(
      path: '/budget',
      builder: (context, state) => BudgetScreen(
        tripId: state.uri.queryParameters['tripId'],
      ),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/community-write',
      builder: (context, state) => CommunityWriteScreen(
        type: state.uri.queryParameters['type'] ?? 'feed',
        editId: state.uri.queryParameters['editId'],
      ),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const ScheduleScreen(),
    ),
    GoRoute(
      path: '/group-trip',
      builder: (context, state) => const GroupTripScreen(),
    ),
    GoRoute(
      path: '/group-join/:code',
      builder: (context, state) => GroupJoinScreen(code: state.pathParameters['code']!),
    ),
    GoRoute(
      path: '/app-settings',
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/experiences',
      builder: (context, state) => const ExperiencesScreen(),
    ),
    GoRoute(
      path: '/profile-edit',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
