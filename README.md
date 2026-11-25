# Driver Location Tracking & Offline Synchronization

A Flutter-based driver location tracking application designed to capture GPS coordinates, store location records locally, and synchronize them with a backend API when network connectivity is available.

The application is built with a focus on reliability, offline-first data handling, background location tracking on Android, and duplicate-safe synchronization.

---

## Project Overview

Driver Location Tracking is designed to help capture and manage driver location records even when internet connectivity is unavailable.

The application collects location coordinates from the device, stores them in a local SQLite database, and synchronizes pending records with the backend when connectivity becomes available.

### Key Features

- **GPS Location Tracking:** Captures real device latitude and longitude.
- **Start / Stop Tracking:** Allows users to control location tracking.
- **Background Tracking (Android):** Uses an Android foreground service to continue location collection while the app is minimized or the screen is locked.
- **Offline-First Storage:** Stores captured location records locally using SQLite.
- **Automatic Synchronization:** Attempts to synchronize pending records when network connectivity returns.
- **Duplicate Prevention:** Uses unique location IDs and backend-side duplicate handling.
- **Retry Handling:** Retries failed synchronization requests.
- **Connectivity Monitoring:** Detects network connectivity changes.
- **Location History:** Displays previously captured location records.
- **Dashboard Statistics:** Displays total, synchronized, pending, and failed records.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application |
| Dart | Application programming language |
| GetX | State management and dependency handling |
| SQLite / sqflite | Local location storage |
| Geolocator | Device GPS location access |
| flutter_foreground_task | Android foreground service |
| Dio | HTTP API communication |
| connectivity_plus | Network connectivity monitoring |
| UUID | Unique location record identifiers |

---

## Application Architecture

The application follows a feature-oriented separation of responsibilities.

```text
lib/
├── controllers/
│   └── tracking_controller.dart
│
├── data/
│   ├── database/
│   │   └── database_helper.dart
│   │
│   └── models/
│       └── location_model.dart
│
├── services/
│   ├── background_tracking_service.dart
│   ├── tracking_task_handler.dart
│   ├── location_api_service.dart
│   └── location_sync_service.dart
│
├── screens/
│   └── tracking/
│       └── tracking_screen.dart
│
└── main.dart
```

### Architecture Responsibilities

**Controllers**
- Manage application tracking state.
- Coordinate GPS, database, connectivity, and synchronization services.
- Update dashboard information.

**Models**
- Represent location records.
- Convert location objects to and from database maps.
- Maintain synchronization status and retry information.

**Database Layer**
- Store location records locally.
- Retrieve pending records.
- Update synchronization status.
- Provide dashboard statistics.

**Services**
- Handle GPS tracking and foreground service execution.
- Communicate with backend APIs.
- Manage synchronization and retry operations.

---

## Location Data Structure

Each captured location contains the following information:

| Field | Description |
|---|---|
| id | Unique location identifier |
| latitude | GPS latitude |
| longitude | GPS longitude |
| captured_at | Location capture timestamp in UTC |
| status | Synchronization status |
| retry_count | Number of failed synchronization batches |
| last_error | Most recent synchronization error, if available |

### Synchronization Status

- `pending` – Location is stored locally and awaiting synchronization.
- `synced` – Location has been successfully synchronized.
- `failed` – Previous synchronization attempt failed.

---

## Offline-First Synchronization Workflow

The application follows an offline-first approach.

```text
       GPS Location Captured
                |
                v
       Generate Unique ID
                |
                v
        Save to SQLite
                |
                v
       Check Connectivity
                |
          +-----+-----+
          |           |
        Online       Offline
          |           |
          v           v
      Send API     Keep Record
          |        as Pending
          v
    Backend Response
          |
     +----+----+
     |         |
   Success   Failure
     |         |
     v         v
   Mark      Retry /
   Synced    Mark Failed
```

### Synchronization Strategy

1. Capture the device location.
2. Generate a unique identifier for the record.
3. Save the record in SQLite.
4. Check network availability.
5. Send pending records to the backend when online.
6. Mark successfully processed records as synchronized.
7. Retain unsuccessful records for subsequent retry attempts.

The backend uses unique location IDs to prevent duplicate database records.

---

## Background Location Tracking

The Android implementation uses `flutter_foreground_task` to run a foreground service while location tracking is active.

The service:
- Captures actual device GPS coordinates.
- Runs periodic location capture tasks.
- Stores captured records in the local SQLite database.
- Displays a persistent tracking notification.
- Communicates captured location information back to the main application.

### Android Permissions

The Android manifest includes permissions for:

- Internet access
- Fine location
- Coarse location
- Foreground service
- Foreground service location
- Notifications
- Wake lock

### Important Platform Considerations

- The tracking service should be started while the application is visible.
- Android displays a persistent notification during foreground tracking.
- Battery optimization and manufacturer-specific restrictions can affect background execution.
- Force-stopping the application from Android Settings terminates its services.
- Background tracking behavior may vary across Android versions and device manufacturers.

**iOS:** The current background tracking implementation is Android-focused. A production iOS implementation requires appropriate Core Location configuration, background location capabilities, permission handling, and additional platform-specific testing.

---

## Backend Integration

The Flutter application communicates with the Node.js backend using REST APIs.

Configure the backend base URL in:

```text
lib/services/location_api_service.dart
```

Example development configuration:

```dart
static const String baseUrl = 'http://192.168.1.2:3000';
```

Replace the example IP with the actual development machine IP address when running on another network.

For production, use a secure HTTPS backend URL.

### API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/v1/health` | Check backend health |
| POST | `/api/v1/locations` | Submit one location |
| POST | `/api/v1/locations/bulk` | Synchronize multiple locations |
| GET | `/api/v1/locations` | Retrieve location history |
| GET | `/api/v1/locations/:id` | Retrieve a location by ID |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.41.9 or a compatible newer version
- Dart SDK compatible with the Flutter SDK
- Android Studio
- Android SDK
- A physical Android device or Android emulator
- Running backend API

### 1. Clone the Repository

```bash
git clone <YOUR_FLUTTER_REPOSITORY_URL>
cd driver_location_tracking_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Backend URL

Open:

```text
lib/services/location_api_service.dart
```

Set the appropriate backend URL.

### 4. Run Static Analysis

```bash
flutter analyze
```

### 5. Run Automated Tests

```bash
flutter test
```

### 6. Run the Application

```bash
flutter run
```

---

## Testing

The Flutter project includes automated unit tests for the location model.

The current model tests cover:

- Location object creation.
- Conversion from location model to Map.
- Conversion from Map to location model.
- Status updates using `copyWith`.
- Clearing previous error information.

Run tests using:

```bash
flutter test
```

Additional manual testing should cover:

- Start and stop tracking.
- Actual GPS capture.
- Offline location storage.
- Connectivity restoration.
- Background location collection.
- Duplicate-safe synchronization.
- Retry behavior after failed API requests.

---

## Limitations and Future Improvements

Potential future enhancements include:

- Dedicated iOS background location implementation.
- More comprehensive integration and widget tests.
- Improved background synchronization scheduling.
- Configurable location capture intervals.
- Authentication and driver-specific authorization.
- Production monitoring and structured logging.
- Secure production deployment with HTTPS.

---

## Project Objective

The objective of this project is to demonstrate practical implementation of GPS tracking, offline-first storage, background execution on Android, REST API integration, and reliable synchronization in a Flutter application.

---

## Author

**Developed as a technical assessment project**

**Project:** Driver Location Tracking & Offline Synchronization

**Technology:** Flutter, Dart, SQLite, Node.js REST API