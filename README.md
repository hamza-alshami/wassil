# WASSIL — وصّل

**وصّل – وين طلبي؟** تطبيق عربي لمتابعة الطلبات وتفاصيلها. يدعم عرض آخر نسخة محفوظة من الطلبات عند تعذر الوصول إلى MockAPI.

## Overview

WASSIL is a small Flutter customer app for viewing orders, delivery status, order items, delivery milestones, and delivery address. The current scope includes the orders list and order details. It does not include authentication, maps, live tracking, or notifications.

## Implemented features

- Arabic interface with right-to-left direction.
- Orders list with order number, date, total, and localized status.
- Pull to refresh.
- Order details with items, quantities, prices, total, address, and delivery timeline.
- Loading, error with retry, and empty states.
- SQLite persistence of orders and their nested items and timeline.
- Offline fallback with a banner that explains when cached data is displayed and may be stale.
- Fresh API data replaces the stored snapshot in a SQLite transaction to avoid duplicate records.

## Technology

- Flutter and Dart (`^3.11.0` SDK constraint).
- Riverpod (`flutter_riverpod`) for presentation state.
- connectivity_plus for current network checks and foreground connectivity changes.
- Dio for HTTP requests.
- sqflite and path for SQLite persistence.
- sqflite_common_ffi for isolated in-memory SQLite repository tests.
- google_fonts with IBM Plex Sans Arabic.
- Flutter Material icons and localization delegates.

Lucide Icons are not currently a dependency; the app uses Flutter Material icons.

## Architecture

The app uses a feature-based structure with MVVM and a repository boundary. It keeps the implementation small: domain entities and a repository contract are provided where they clarify the orders feature, without introducing a separate use-case layer.

```text
lib/
├── app/                         # Root MaterialApp and localization setup
├── core/
│   ├── database/                # SQLite connection and schema
│   ├── network/                 # Dio client configuration
│   └── theme/                   # Shared colors and typography
├── features/orders/
│   ├── data/
│   │   ├── datasources/         # MockAPI and SQLite access
│   │   ├── models/              # JSON parsing and validation
│   │   └── repositories/        # Remote/local data coordination
│   ├── domain/
│   │   ├── entities/            # Order and nested value objects
│   │   └── repositories/        # Repository contract and result metadata
│   └── presentation/
│       ├── pages/               # Orders and order details screens
│       ├── view_models/         # Riverpod AsyncNotifier and providers
│       └── widgets/             # Cards, badges, and state widgets
└── main.dart                    # Application entry point

test/
└── features/orders/
    ├── data/models/             # JSON model tests
    ├── data/repositories/       # Repository and SQLite tests
    └── presentation/            # ViewModel and widget tests
```

## Setup and run

Install Flutter and Android tooling, then fetch packages:

```sh
flutter pub get
```

Create `dart_defines.local.json` in the project root using the ignored local file format:

```json
{
  "MOCKAPI_KEY": "your-key"
}
```

The local file is excluded by `.gitignore`. Do not commit it or place the key in Dart source. The example template is `dart_defines.example.json` and contains no real key.

In VS Code, select **Wassel (local MockAPI)** from `.vscode/launch.json`; it passes the local define file when starting Flutter. Alternatively run:

```sh
flutter run --dart-define-from-file=dart_defines.local.json
```

If `MOCKAPI_KEY` is absent, Dio omits the authentication header instead of failing during app startup. A remote request may then be rejected by MockAPI; the repository uses cached orders if available and otherwise the UI presents an error with a retry action.

## API contract

- Base URL: `https://api.mockapi.com`
- Method and path: `GET /orders`
- Authentication: `x-api-key` request header
- Response: a JSON object whose `data` field is a list of orders.

Example response:

```json
{
  "data": [
    {
      "orderNumber": "ORD-1001",
      "date": "2026-11-25T09:00:00Z",
      "total": 21800,
      "status": "pending",
      "customerName": "أحمد محمد",
      "address": "شارع الزبيري، قرب جولة الثقافة، صنعاء",
      "items": [
        { "name": "أرز بسمتي", "quantity": 2, "price": 6500 },
        { "name": "زيت دوار الشمس", "quantity": 1, "price": 5200 },
        { "name": "سكر أبيض", "quantity": 2, "price": 1800 }
      ],
      "timeline": [
        { "title": "تم استلام الطلب", "completed": true },
        { "title": "بانتظار تأكيد الطلب", "completed": false }
      ]
    }
  ]
}
```

`OrdersRemoteDataSource` validates the response envelope. `OrderModel` converts each JSON object and its nested item and timeline objects into domain entities, rejecting invalid required fields with a `FormatException`.

## Local storage and Offline First

SQLite stores orders, order items, delivery timeline steps, and the last successful sync time in `wassel_orders.db`. Order children reference their parent order, and the complete snapshot is replaced inside one transaction. A failed API refresh does not delete or overwrite the last saved snapshot.

At startup and before refresh, the repository checks whether a network interface is available. If none is available, it loads SQLite immediately without waiting for an API timeout. When connectivity changes while the app is open, the ViewModel switches to the cached state on disconnect and starts an API refresh on reconnect. It also checks connectivity when the app resumes. On a Dio failure or invalid remote payload, the repository restores the saved SQLite snapshot. Cached data is labeled as potentially old. Opening an order's details uses the complete order object already loaded from the API or SQLite; it does not make another network request.

The connectivity plugin reports network interfaces, not guaranteed Internet access. A Wi-Fi or mobile connection without working Internet is detected by the API request failure and handled through the same SQLite fallback.

## UI states

- **Loading:** progress indicator while the initial repository load is pending.
- **Error:** explanatory message and retry action when loading fails and no cache exists.
- **Empty:** message and pull-to-refresh when the successful result contains no orders.
- **Success:** orders list, with an online or cached-data banner based on repository metadata.

## Tests

Tests use fake Dio responses and the FFI SQLite database; they do not require internet access. The repository test also verifies that remote orders are sorted newest first before they are cached.

```sh
flutter test test/features/orders/data/models/order_model_test.dart
flutter test test/features/orders/data/repositories/orders_repository_test.dart
flutter test test/features/orders/presentation/view_models/orders_view_model_test.dart
flutter test test/features/orders/presentation/orders_page_test.dart
flutter analyze
flutter test
```

The repository tests use an in-memory database and close it in `tearDown`, so each test has an isolated database connection.

## Manual offline check

1. Run the app with internet access and confirm that orders load.
2. Close the app without clearing its storage.
3. Disable internet on the emulator or device and launch the app again.
4. Confirm the saved orders and offline/stale-data banner are visible.
5. Open an order and confirm its items, address, and delivery milestones are present.
6. Restore internet and pull down to refresh the list.

## Project status

The orders list, order details, MockAPI integration, refresh interaction, and SQLite offline fallback are implemented. The test suite is organized across model, repository, ViewModel, and widget responsibilities and currently contains 25 tests. MockAPI is configured with five Arabic order records (ORD-1001 through ORD-1005); validate that each API-provided total matches its line items before using the records as business data.
