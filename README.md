# Smart Attendance System

A modern, touchless, real-time QR code-based attendance tracking and management application built with **Flutter**, **Dart**, **SQLite**, and **Firebase Cloud Firestore**.

Developed and Maintained by: **Avinash Pawar**

---

## 📌 Project Overview

The **Smart Attendance System** provides a seamless, touchless solution for educational institutions and organizations to record and manage attendance in real time. It eliminates manual paper-based roll calls by enabling teachers to generate dynamic, time-valid QR codes for live class sessions, which students can scan using their mobile camera or enter manually via session codes.

The application features a **Dual Database Architecture** combining local **SQLite** storage for offline access and **Firebase Cloud Firestore** for real-time cloud synchronization.

---

## 🌟 Key Features

### 1. 🔐 Role-Based Authentication & Access Control
- **Dual Login Portals:** Separate portals for **Students** and **Teachers / Admins**.
- **Strict Role Verification:** Automatically verifies registered account roles against Cloud Firestore (`users/{uid}`) during sign-in to prevent unauthorized portal access.
- **Account Registration:** Sign up with name, email, role, student/staff ID, and department selection.
- **Secure Sign-Out:** Complete session clearing and redirection back to authentication wrappers.

### 2. 👨‍🏫 Teacher Portal & Live QR Session Generation
- **Dynamic Session Creation:** Select courses and generate unique session codes.
- **Configurable Time Validity:** Choose QR code expiration duration (*2 Mins, 5 Mins, 10 Mins, 15 Mins, 30 Mins, or 1 Hour*).
- **Live Countdown Timer:** Displays real-time validity remaining (`QR VALID • 04:59 REMAINING`).
- **Automatic Expiration Handling:** Switches to a `QR CODE EXPIRED` status overlay when time elapses.
- **Live Attendance Counter:** Real-time count and checked-in student list updated as students scan in.

### 3. 📱 Student Portal & Touchless Camera Scanning
- **Mobile Camera Scanner:** Built-in scanner using `mobile_scanner` with flashlight toggle and camera switching capabilities.
- **Time Validity Validation:** Validates session expiration timestamps (`session.isExpired`) and blocks expired QR code scans.
- **Manual Code Entry:** Fallback option to enter session codes manually.
- **Personal Performance Analytics:** Attendance percentage indicator bar and individual attendance history.

### 4. 👥 Student Management
- **Department Selection Dropdown:** Department selection menu featuring *Computer Science*, *Software Engineering*, *Information Technology*, *Data Science*, *Cyber Security*, *Electrical Engineering*, and *Business Administration*.
- **Confirmation Popups:** Instant **"Student Added Successfully"** modal popups with green checkmark and student summary.
- **Real-Time Added Students List:** Instant updates to the student directory upon registration.
- **Teacher-Only Privileges:** Restricted creation, editing, and deletion controls reserved exclusively for Teacher accounts.

### 5. 📚 Course Management
- **Course Directory:** Add, update, search, and manage subject definitions (Code, Title, Instructor Name).
- **Confirmation Popups:** Instant **"Course Added Successfully"** modal popups.
- **Teacher-Only Access:** Restricted to authorized Teacher accounts.

### 6. 📊 Comprehensive Attendance Reports & Logs
- **System Statistics:** Analytics summary for Total Records, Total Sessions, and Enrolled Students.
- **Multi-Filter Log Search:** Search attendance records by student name, student ID, or session code, with dropdown filtering by course.
- **Dual Visibility:** Accessible to both Teachers (full class logs) and Students (personal attendance history).

---

## 💾 Dual Database Architecture

```
                      +-----------------------------+
                      |    Smart Attendance App     |
                      +--------------+--------------+
                                     |
             +-----------------------+-----------------------+
             |                                               |
             v                                               v
  +--------------------+                           +--------------------+
  |   SQLite Database  |                           | Firebase Firestore |
  | (sqflite Local DB) |                           | (Cloud Realtime DB)|
  +--------------------+                           +--------------------+
```

- **Local Persistence (SQLite via `sqflite`):** Stores `students`, `courses`, `sessions`, and `attendance` tables locally for instant loading and offline reliability.
- **Cloud Storage (Firebase Cloud Firestore):** Synchronizes `users`, `students`, `courses`, `sessions`, and `attendance` collections across multiple devices in real time.
- **Non-Blocking Resilient Sync:** Operations execute smoothly without UI freezing or network blocking.

---

## 📁 Project Architecture & File Structure

```text
lib/
│
├── database/
│   └── db_helper.dart                 # SQLite Database Helper & Migration Manager
│
├── models/
│   ├── student.dart                   # Student Data Model
│   ├── course.dart                    # Course Data Model
│   ├── attendance_session.dart        # Session & Expiry Data Model
│   └── attendance_record.dart         # Attendance Record Model
│
├── services/
│   ├── firebase_service.dart          # Firebase Auth & Cloud Firestore Integration
│   └── attendance_service.dart        # Business Logic & State Provider
│
├── views/
│   ├── auth_wrapper.dart              # Auth Stream Listener & Route Guard
│   ├── login_screen.dart              # Multi-Role Sign-In Screen
│   ├── create_account_screen.dart     # Account Registration Screen
│   ├── home_screen.dart               # Adaptive Main Shell & Navigation Hub
│   ├── teacher_dashboard.dart         # Teacher Console & Live Session Generator
│   ├── student_dashboard.dart         # Student Console & Attendance History
│   ├── manage_students_screen.dart    # Student Directory & Management
│   ├── manage_courses_screen.dart     # Course Directory & Management
│   ├── qr_generator_screen.dart       # Live QR Code & Expiry Countdown Screen
│   ├── qr_scanner_screen.dart         # Camera QR Scanner Screen
│   └── attendance_reports_screen.dart # Attendance Analytics & Reports Log
│
├── widgets/
│   └── responsive_layout.dart         # Mobile/Tablet/Desktop Responsive Layout
│
├── firebase_options.dart              # Generated Firebase Platform Configuration
└── main.dart                          # Application Entry Point & Provider Setup
```

---

## 🛠️ Technology Stack & Dependencies

- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.13.5`)
- **State Management:** [Provider](https://pub.dev/packages/provider) (`^6.1.2`)
- **Backend & Cloud Services:**
  - [Firebase Core](https://pub.dev/packages/firebase_core) (`^3.10.1`)
  - [Firebase Auth](https://pub.dev/packages/firebase_auth) (`^5.5.1`)
  - [Cloud Firestore](https://pub.dev/packages/cloud_firestore) (`^5.6.2`)
- **Local Database:** [sqflite](https://pub.dev/packages/sqflite) (`^2.3.0`) & [path](https://pub.dev/packages/path) (`^1.9.0`)
- **QR Code Tools:**
  - [qr_flutter](https://pub.dev/packages/qr_flutter) (`^4.1.0`) - Live QR Code Rendering
  - [mobile_scanner](https://pub.dev/packages/mobile_scanner) (`^6.0.0`) - Camera Barcode/QR Scanning
- **Utilities:** [intl](https://pub.dev/packages/intl) (`^0.19.0`) for date/time formatting

---

## 🚀 Getting Started

### Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.13.5 or higher)
- Install [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter plugins
- An Android/iOS device or emulator with camera permissions

### Installation & Run Steps

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your-username/smartattendance.git
   cd smartattendance
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   Ensure your `firebase_options.dart` contains valid credentials for your Firebase project (`smart-attendance-sys-app`). Enable **Email/Password Authentication** and **Cloud Firestore** in your Firebase Console.

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 👤 Developer Profile

- **Project Lead & Developer:** **Avinash Pawar**
- **Application:** Smart Attendance System
- **Platform:** Cross-platform (Android, iOS, Web, Desktop)

---

## 📄 License

This project is developed for educational and institutional attendance management purposes.
