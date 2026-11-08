# EvNavi — EV Route Optimizer & Charging Assistant ⚡🚗

**EvNavi** is an intelligent EV trip planner and navigator designed to alleviate electric vehicle **range anxiety**. It calculates realistic battery consumption considering real-world elevation profiles, predicts exact depletion points, and automatically finds and routes through operational EV charging stations along the way.

---

## ✨ Features

- 🔋 **Battery-Aware Route Planning**: Accurately computes remaining battery life factoring in elevation gain, descent, and regenerative braking.
- ⚡ **Charging Stop Planner**: Automatically detects when battery falls below buffer threshold and recommends nearby operational charging stations.
- 🗺️ **Multi-Waypoint Navigation**: Recalculates full road navigation route through all scheduled charging stops using OSRM.
- 📍 **Interactive Map & Live Navigation**: Real-time GPS tracking with turn-by-turn guidance, speedometer, and nearby station discovery.
- 🌐 **Free & Open APIs**: Integrates Nominatim (OpenStreetMap), OSRM, Open Elevation, and OpenChargeMap with no proprietary API lock-in.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.5.0 or higher)
- [Python 3.9+](https://www.python.org/) (optional, only if using backend)

---

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/ev_app.git
cd ev_app
```

---

### 2. Configure Environment Variables

The project uses a `.env` file to securely manage API keys without committing them to source control.

1. Copy the template file:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and insert your [OpenChargeMap](https://openchargemap.org/site/develop/api) API key:
   ```env
   OCM_API_KEY=your_openchargemap_api_key_here
   ```

---

### 3. Install Dependencies & Run

#### Run Flutter Frontend
```bash
# Get Flutter packages
flutter pub get

# Run on Chrome
flutter run -d chrome --dart-define-from-file=.env

# Run on Windows Desktop
flutter run -d windows --dart-define-from-file=.env

# Run on Android (Connected Device / Emulator)
flutter run -d android --dart-define-from-file=.env
```

*(Tip: In VS Code, you can simply press **F5** to start debugging with `.env` configured automatically).*

---

### 4. (Optional) Run Python FastAPI Backend

The Flutter app is serverless-first and connects directly to open public services. However, a Python FastAPI backend is also included if you prefer backend aggregation:

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env  # configure backend/.env
uvicorn main:app --reload --port 8000
```

---

## 🛡️ Security & API Keys

- Never commit `.env` or sensitive credentials to GitHub.
- Keep `.gitignore` updated (both root and backend `.env` files are gitignored).
- Pass sensitive keys at compile/runtime using Flutter's native `--dart-define-from-file=.env`.

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
