# CowSense

CowSense is an integrated platform for real-time health monitoring and management of cattle, leveraging IoT sensors, cloud services, and AI-driven insights. The system is designed for both farmers and veterinarians, providing tailored mobile applications and a robust backend for data collection, analysis, and alerting.

---

## Table of Contents
- [Project Overview](#project-overview)
- [Monorepo Structure](#monorepo-structure)
- [Hardware Overview](#hardware-overview)
- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Tech Stack](#tech-stack)
- [API Overview](#api-overview)
- [Contributing](#contributing)
- [License](#license)

---

## Project Overview
CowSense aims to revolutionize livestock management by providing:
- **Continuous health monitoring** of cows using IoT sensors (temperature, heart rate, SpO2, GPS, etc.).
- **Real-time alerts** for abnormal health parameters.
- **Mobile apps** for both farmers and veterinarians, with role-specific features.
- **Cloud-based backend** for data storage, analytics, and notification delivery.

---

## Monorepo Structure
- `farmer/` — Farmer App
- `cow-sense-veteran/` — Veterinarian App
- `cowsense-server/` — Backend Server

---

## Hardware Overview
CowSense leverages modern IoT hardware to enable real-time, reliable cattle health monitoring:

- **Microcontroller:** ESP32
- **Sensors:**
  - **Temperature Sensor:** Monitors body temperature for fever or hypothermia detection ( DS18B20 )
  - **Heart Rate Sensor:** Tracks pulse for early signs of distress ( Max30100 )
  - **SpO2 Sensor:** Measures blood oxygen saturation. ( Max30100 )
  - **GPS Module:** Provides real-time location tracking for each cow
  - **Accelerometer/Gyroscope:** Detects movement, activity, and abnormal behavior (e.g., lameness, falls)
  - **Optional:** Environmental sensors that detect humidity, temperature. ( DHT22 )
- **Connectivity:** Data is transmitted via Wi-Fi from the ESP32 to the backend server

---

## Features
### Farmer App (`farmer/`)
The Farmer App is designed for ease of use in the field, providing actionable insights and real-time data to farmers:

#### Key Features
- **Real-Time Health Dashboard:**
  - View live health metrics (temperature, heart rate, SpO2, activity, and location) for each cow
  - Color-coded alerts for abnormal readings
  - Quick-glance summary and detailed view per animal
- **Push Notifications:**
  - Immediate alerts for abnormal sensor readings (e.g., fever, low oxygen)
  - Customizable notification preferences
- **Historical Data Visualization:**
  - Interactive charts for health trends over time (daily, weekly, monthly)
  - Map view for tracking movement and grazing patterns
- **Authentication & Security:**
  - Secure login via Firebase and Google Sign-In
  - Role-based access for farm staff
- **Media Uploads:**
  - Attach photos or notes to individual cows (e.g., injuries, treatments)
- **Cow Management:**
  - Add, edit, or remove cows from the herd
  - Assign tags, names, and other metadata
- **User-Friendly UI:**
  - Optimized for outdoor use (large buttons, high-contrast design)
- **Gemini Chat Integration:**
  - In-app AI-powered chat assistant (Gemini) to answer farmer queries, provide guidance, and support decision-making.
- **Real-Time Chat with Veterinarians:**
  - Direct messaging between farmers and veterinarians
  - Push notifications for new messages
- **AI Disease Detection:**
  - Integrated AI model that accepts cow images to detect and classify diseases(skin and feet), providing instant feedback.

#### Typical Workflow
1. **Login:** Farmer signs in securely via Google or email
2. **Dashboard:** Overview of herd health, with alerts highlighted
3. **Details:** Tap on a cow to view detailed health history, location, and notes
4. **Notifications:** Receive and review alerts for any abnormal readings
5. **Actions:** Add notes, upload photos, or contact a veterinarian directly from the app

### Veterinarian App (`cow-sense-veteran/`)
- Access to individual cow data
- Secure authentication and role-based access
- Onboarding and user-friendly UI

### Backend Server (`cowsense-server/`)
- RESTful API for sensor data ingestion and retrieval
- WebSocket (Socket.IO) for real-time updates
- MongoDB for data storage
- Automated alerting and notification dispatch (via Firebase Cloud Functions)
- Data validation and threshold-based alerting

---

## Architecture

```
  ┌─────────────────┐
  │   IoT Sensors   │
  └────────┬────────┘
           │
           ▼
    ┌────────────────────────────────────────────────────┐
    │  cowsense-server ( Express.js, MongoDB, Socket.IO) │
    └────────┬───────────────────────────────────────────┘
             │                     
             ├────────Notification Triggered─────┐
             │                                   │
             ▼                                   ▼
    ┌─────────────────┐                ┌─────────────────┐
    │  Farmer App     │                │ Firebase Cloud  │
    │    (Flutter)    │◄───────────────│ Messaging       │
    └─────────────────┘                └─────────────────┘ 
```

The architecture follows a standard IoT pattern:
1. **Data Collection**: IoT sensors attached to cows collect vital health metrics
2. **Data Processing**: The backend server receives, processes, and stores sensor data
3. **Real-time Updates**: Socket.IO enables instant data transmission to mobile apps
4. **Notifications**: Server triggers Firebase Cloud Messaging to send alerts and chat notifications to the Farmer App
5. **Mobile Access**: Both farmers and veterinarians access appropriate data through their respective apps
6. **Real-time Communication**: Firebase facilitates instant messaging between farmers and veterinarians

<!-- ## Getting Started
### Prerequisites
- Node.js (v18+ recommended)
- MongoDB Atlas or local MongoDB instance
- Flutter SDK (3.x)
- Firebase project (for mobile apps and notifications)

### Backend Setup
*Apply setup instructions here.*

### Run
#### Farmer App
*Apply run instructions here.*

#### Veterinarian App
*Apply run instructions here.* -->

---

## Tech Stack
- **Mobile:** Flutter, Dart, Firebase, Google Sign-In, Hive, Provider, Lottie, Charts, Maps
- **Backend:** Node.js, Express, MongoDB, Mongoose, Socket.IO, Firebase Admin SDK, dotenv, CORS
- **Notifications:** Firebase Cloud Messaging, Custom Cloud Functions

---

## API Overview
### Sensor Data Endpoints
- `POST /api/sensors/live` — Receive live sensor data, broadcast to clients, and trigger alerts.
- `POST /api/sensors/store` — Store sensor data in MongoDB.
- `GET /api/sensors/all?date=YYYY-MM-DD` — Retrieve all sensor data for a specific date.
- `GET /api/sensors/latest?tagNumber=...` — Get the latest data for a specific cow.

### Chat Endpoints
- `GET /api/chats` — Get all chats for the current user.
- `GET /api/chats/:chatId` — Get a specific chat with messages.
- `POST /api/chats` — Create a new chat.
- `POST /api/chats/:chatId/messages` — Send a new message in a chat.
- `PUT /api/chats/:chatId/messages/:messageId/read` — Mark a message as read.

### WebSocket Events
- `subscribe-cows` — Subscribe to real-time updates for specific cow IDs.
- `unsubscribe-cows` — Unsubscribe from updates.
- `join-chat` — Join a specific chat room.
- `leave-chat` — Leave a chat room.
- `new-message` — Send a new chat message.
- `message-received` — Event fired when a new message is received.
- `typing-status` — Broadcast typing status to chat participants.

---

## Contributing
Contributions are welcome! Please open issues or submit pull requests for improvements, bug fixes, or new features.

---

## License
This project is licensed under the MIT License.

---

**CowSense — Empowering smarter, healthier herds with technology.**