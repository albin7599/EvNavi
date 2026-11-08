# EvNavi — EV Trip Planner & Navigator for Electric Vehicles
### Project Report Content Document
#### Department of Computer Science and Engineering | Mini Project Report (Semester VI)

---

## Table of Contents

1. [Abstract](#abstract)  
2. [Introduction](#introduction)  
3. [Problem Statement](#problem-statement)  
4. [Objectives](#objectives)  
5. [Scope of the Project](#scope-of-the-project)  
6. [Comparative Analysis of Existing Systems](#comparative-analysis-of-existing-systems)  
7. [Limitations of Existing Systems](#limitations-of-existing-systems)  
8. [Proposed System Overview](#proposed-system-overview)  
9. [Software Requirements Specification (SRS)](#software-requirements-specification-srs)  
10. [System Analysis and Design](#system-analysis-and-design)  
11. [APIs Used](#apis-used)  
12. [Algorithms & Calculations](#algorithms--calculations)  
13. [Module-wise Implementation](#module-wise-implementation)  
14. [Development Environment](#development-environment)  
15. [Conclusion](#conclusion)  

---

## Abstract

**EvNavi** is a cross-platform mobile application built with Flutter for Android and iOS that solves one of the most significant challenges in electric vehicle (EV) adoption — **range anxiety**. The app plans optimal EV routes by calculating how far the vehicle can travel on its current battery charge (factoring in real-world elevation changes), identifies where the vehicle needs to stop for charging, and locates real, operational charging stations nearby at each stop.

The application integrates with multiple free, publicly available APIs including **OpenStreetMap (Nominatim)** for geocoding, **OSRM (Open Source Routing Machine)** for road routing, **Open Elevation API** for terrain data, and **OpenChargeMap** for real-world charging station data. A battery planning algorithm computes charging stops using cumulative effective distance modelling with elevation-aware energy consumption and regenerative braking simulation.

The system is composed of a Flutter frontend and an optional Python FastAPI backend, making it entirely open-source and deployable without commercial API costs.

---

## Introduction

The global adoption of electric vehicles is accelerating, with millions of EVs on roads worldwide. One of the primary concerns for EV drivers — especially on long trips — is "**range anxiety**": the fear of running out of charge before reaching the destination or a charging station. Unlike petrol vehicles where fuel stations are abundant and refuelling takes 2–5 minutes, EV charging stations are fewer and charging takes 20–60 minutes.

The EvNavi application addresses this challenge thoughtfully. It does not merely show a straight-line route; instead, it:
- Calculates the **effective energy consumption** along a road route using real elevation data.
- Determines precisely **where on the route** the battery will be depleted (considering hills, regeneration, and terrain).
- Identifies real, **operational EV charging stations** near those points.
- Recalculates the final route **through the chosen charging stops** to give a realistic, multi-waypoint road path.
- Provides a **live navigation mode** with real-time GPS tracking and a speedometer.

---

## Problem Statement

Electric vehicles represent a clean, sustainable mode of transport, but widespread adoption is hindered by:

1. **Range Anxiety**: Drivers are uncertain how far their EV can travel on a given charge.
2. **Lack of Intelligent Charging Stop Planning**: Existing apps treat all road segments equally, ignoring the massive impact of elevation gain/loss on energy consumption.
3. **Incomplete Charging Station Data**: Many apps either show petrol stations or have outdated EV charger data.
4. **No Personalised Vehicle Parameters**: Existing solutions rarely allow users to input their vehicle's current battery percentage and maximum range.
5. **Absence of Terrain-Aware Planning**: Climbing a hill consumes significantly more energy; descending regenerates energy via regenerative braking. Most existing planners ignore this.

**EvNavi** provides an intelligent, personalized, terrain-aware EV route planner that fills this gap.

---

## Objectives

1. Develop a mobile application for EV trip planning with real-time GPS integration.
2. Implement a **terrain-aware battery depletion model** that accounts for elevation gain, elevation loss, and regenerative braking.
3. Integrate with the **OpenChargeMap API** to retrieve live, operational EV charging station data.
4. Use the **OSRM** routing engine to compute realistic road routes (not straight-line crow-fly distances).
5. Automatically detect where the vehicle's battery runs low and place charging stops at nearby actual stations.
6. Re-route the overall trip through the recommended charging stops.
7. Provide a live **navigation mode** with real-time GPS position tracking and speedometer.
8. Allow users to input their **current battery percentage** and **vehicle range** for personalized planning.
9. Display an **interactive map** with station markers, charge stop cards, and route overlay.
10. Make the app production-ready with country-aware search, geocoding, and location permissions.

---

## Scope of the Project

### In-Scope:
- Android and iOS cross-platform mobile application.
- Real-time GPS location detection and map centering.
- Place search with autocomplete (powered by Nominatim).
- Multi-stop EV route planning up to 15 charging stops.
- Elevation-aware energy consumption calculation using Open Elevation API.
- Charging station discovery using OpenChargeMap (real-world data).
- Route recalculation via selected charging stops using OSRM.
- Live navigation mode with GPS stream and speed display.
- Interactive map with zoom-dependent marker rendering.
- Station information sheets (name, address, connector types, power output).
- Location picker from map interface.
- User-configurable vehicle range and battery percentage sliders.
- Bottom navigation between Home Map and Trip Planner.

### Out-of-Scope (Future Work):
- Turn-by-turn voice navigation.
- Real-time charger occupancy and pricing data.
- User account management / saved routes.
- Integration with specific EV manufacturer APIs (Tesla, etc.).
- Traffic data integration.
- Offline map support.

---

## Comparative Analysis of Existing Systems

| Feature / System | **EvNavi** | Google Maps | ABRP (A Better Route Planner) | PlugShare | Zap-Map |
|---|---|---|---|---|---|
| **EV-specific route planning** | ✅ Yes | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Elevation-aware battery model** | ✅ Yes | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Regenerative braking model** | ✅ Yes | ❌ No | ✅ Partial | ❌ No | ❌ No |
| **User sets current battery %** | ✅ Yes | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **User sets vehicle range** | ✅ Yes | ❌ No | ✅ Yes (with vehicle profile) | ❌ No | ❌ No |
| **Open-source & free APIs** | ✅ Yes | ❌ Paid | ❌ Paid subscription | ❌ Partial | ❌ No |
| **Live navigation mode** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Charging stop cards on map** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cross-platform (Android+iOS)** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **No account/login required** | ✅ Yes | ❌ Required | ❌ Required | ❌ Required | ❌ Required |
| **OpenChargeMap integration** | ✅ Yes | ❌ No | ❌ No | ✅ Yes | ❌ No |
| **Country-aware place search** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Map picker for location input** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |

---

## Limitations of Existing Systems

### Google Maps
- Does not support EV-specific route planning.
- Does not calculate charging stops automatically.
- No battery % or vehicle range inputs.
- Ignores energy consumption differences due to terrain.

### ABRP (A Better Route Planner)
- Requires a paid subscription for full features and vehicle profiles.
- Does not show OpenChargeMap data by default.
- No live GPS navigation mode in the app itself.
- Requires user account registration.

### PlugShare
- Only a charging station finder, not a route planner.
- Does not calculate how far you can go on your current charge.
- Does not place stops along a route automatically.

### Zap-Map
- UK-focused, limited global station data.
- No in-app navigation.
- No battery-level-aware route planning.

---

## Proposed System Overview

EvNavi is a **serverless-first** EV trip planning application. Its key innovation is that the battery planning algorithm runs entirely in the Flutter/Dart client code (in `BackendService.getBatteryPlan()`), consuming public free APIs without any proprietary backend.

### System Flow:
```
User Input (Origin, Destination, Battery%, Range)
        ↓
Geocode addresses → Nominatim API (OSM)
        ↓
Get Road Route → OSRM API (driving route with GeoJSON points)
        ↓
Fetch Elevation Data → Open Elevation API (batched, sampled)
        ↓
Battery Planning Algorithm (Dart, on-device):
  - Compute cumulative effective distance with elevation penalty
  - Identify where battery depletes
  - Scan for real chargers at 3 candidate distances
  - Return ChargeStop list
        ↓
Fetch Stations at Each Stop → OpenChargeMap API
        ↓
Recalculate Final Route via All Waypoints → OSRM API
        ↓
Render Route + Stops + Stations on Interactive Map (flutter_map)
        ↓
Live Navigation → GPS Stream (geolocator)
```

---

## Software Requirements Specification (SRS)

### Purpose

This Software Requirements Specification (SRS) document describes the functional and non-functional requirements for the **EvNavi** mobile application — an EV Trip Planner and Navigator for Electric Vehicles. It is intended for use by the development team, evaluators, and academic reviewers.

### Overall Description

#### Product Perspective

EvNavi is a standalone mobile application that integrates with four external web APIs:
1. **Nominatim** (OpenStreetMap geocoding service) — for converting place names to coordinates.
2. **OSRM** (Open Source Routing Machine) — for computing driving road routes between coordinates.
3. **Open Elevation API** — for obtaining altitude data along the route.
4. **OpenChargeMap API** — for discovering real-world EV charging stations.

The app does **not** require its own server for production use — all logic is handled in the Flutter client by calling these public APIs directly.

#### Product Functions

1. Detect user's current GPS location.
2. Accept place-name input for origin and destination with autocomplete suggestions.
3. Allow manual location selection via interactive map picker.
4. Accept vehicle range (km) and current battery (%) as inputs.
5. Compute an elevation-aware EV route plan with charging stops.
6. Display the route on an interactive map with station markers.
7. Show charging stop information cards (station name, distance, connector types).
8. Support live navigation mode with real-time GPS and speedometer.
9. Country-aware search (bias results to user's country).
10. Toggle layers for charging stations and charge stops on map.

#### User Classes

| User Class | Description |
|---|---|
| **EV Driver (Primary)** | A person driving an electric vehicle who wants to plan a long-distance trip. |
| **EV Traveller** | A tourist or commuter using an EV in an unfamiliar area wanting to locate charging stations. |
| **Developer / Evaluator** | A technical person evaluating the application architecture and source code. |

#### Operating Environment

- **Platform**: Android 5.0+ (API 21+), iOS 13.0+
- **Framework**: Flutter 3.x (Dart 3.5+)
- **Map Library**: flutter_map 7.x with OpenStreetMap tiles
- **Backend Runtime** (optional): Python 3.9+ with FastAPI
- **Connectivity**: Internet required for API calls
- **Permissions**: Location (foreground), Internet

---

### Functional Requirements

#### FR1 — GPS Location Detection
- The app shall request location permissions from the device OS on first launch.
- It shall first retrieve the last known position for immediate map display.
- Then it shall fetch the current high-accuracy GPS position.
- The map shall auto-center to the user's location once obtained.

#### FR2 — Nearby Charging Station Discovery (Home Screen)
- Upon GPS location fix, the app shall automatically query OpenChargeMap for EV stations within a 50 km radius.
- Stations shall be displayed as interactive markers on the map.
- Tapping a marker shall display a bottom sheet with station name, address, connection types, power output, and operational status.

#### FR3 — Place Search with Autocomplete (Trip Planner)
- The user shall be able to type an origin or destination place name.
- After a 600ms debounce, the app shall query the Nominatim API.
- Up to 3 results shall be shown in a dropdown below the input field.
- Results shall be filtered to the user's current country if detectable.

#### FR4 — Map Location Picker
- A dedicated map picker page shall allow the user to tap any point on the map to select a location.
- The "Confirm" button shall be disabled until a location is tapped.
- The app shall confirm the selection and return the coordinates to the trip planner.

#### FR5 — Battery & Range Configuration
- The trip planner shall present two sliders: Vehicle Range (50–900 km) and Current Battery % (5–100%).
- Default values shall be 300 km range and 80% battery.
- The planning algorithm shall use these values to compute effective initial range.

#### FR6 — Route Planning
- The app shall call the OSRM API with origin and destination coordinates.
- The returned GeoJSON route shall be decoded into a sequence of LatLng points.
- The route distance (km) and estimated duration (min) shall be computed and stored.

#### FR7 — Elevation Fetching
- The route points shall be sampled (max 120 points) to avoid overloading the elevation API.
- A POST request shall be sent to the Open Elevation API with the sampled coordinates.
- Elevation values for all route points shall be derived via linear interpolation between sampled values.
- If the elevation API fails, the system shall fall back to flat-earth assumption (0 m elevation everywhere).

#### FR8 — Battery Planning Algorithm
- Using the full route geometry, elevation profile, and vehicle parameters, the app shall compute:
  - Cumulative geometric distance at each route point (using Haversine formula).
  - Cumulative effective distance at each route point (geometric + elevation penalty).
  - A list of points where the vehicle would need to charge.
- At each stop point, the app shall search for real charging stations at 3 candidate distances (at limit, 30 km before, 60 km before) and pick the first that returns a result.
- The algorithm shall handle up to 15 charging stops per trip.

#### FR9 — Route Recalculation via Charge Stops
- After charge stops are determined, if any stop has a real station, the app shall recalculate the overall route via all waypoints (start → stop 1 → stop 2 → ... → destination) using OSRM.
- This final route shall be drawn on the map.

#### FR10 — Interactive Map Display (Route View)
- The map shall display the recalculated route as a blue polyline with white border.
- The app shall display origin and destination markers.
- The app shall display charge stop markers (orange/bolt style) for planned stops.
- The user shall be able to toggle visibility of general nearby stations and charge stops.

#### FR11 — Charge Stop Cards
- A horizontal scroll list at the bottom of the map shall display charge stop cards.
- Each card shall show: stop number, distance from start, station name, number of nearby stations.
- Tapping a card shall move the map camera to that stop's location and open the station bottom sheet.

#### FR12 — Live Navigation Mode
- The user can start navigation, which streams GPS position updates in real time.
- The map shall track the user's current position during navigation.
- A speedometer widget shall display the current speed in km/h.
- The user can stop navigation to return to the route overview.

#### FR13 — Routing Summary Chip
- The map top bar shall display a route summary chip showing total distance and estimated duration.
- The chip shall also show the number of planned charge stops with a lightning bolt icon.

---

### Non-Functional Requirements

#### Performance
- **NFR-P1**: The geocoding (place search) response shall be debounced at 600ms to avoid excessive API calls.
- **NFR-P2**: All API calls shall have a timeout of 20 seconds (elevation API: 10 seconds) to prevent the UI from hanging.
- **NFR-P3**: The elevation API payload shall be limited to a maximum of 120 sample points per request.
- **NFR-P4**: The map shall render smoothly at 60 FPS during pan and zoom operations.
- **NFR-P5**: Markers shall show compact styling at zoom levels below 12 and full styling above.

#### Scalability
- **NFR-S1**: The battery plan algorithm's binary search lookup (`_findIndexForDistance`, `_findIndexForEffectiveDistance`) operates in O(log n) time, enabling efficient handling of routes with thousands of points.
- **NFR-S2**: The architecture is stateless — horizontal scaling requires no session management.

#### Security
- **NFR-SEC1**: The OpenChargeMap API key is embedded in the client for the student project context; in production it should be proxied through a secure backend.
- **NFR-SEC2**: No user personal data is stored locally or transmitted to any proprietary server.
- **NFR-SEC3**: All external API calls use HTTPS.

#### Reliability
- **NFR-R1**: If the elevation API fails, the planner shall fall back to flat-terrain calculation and still produce a route plan.
- **NFR-R2**: If no charging station is found near a required stop, a virtual stop (at the computed depletion point on the route) shall be inserted so the trip plan is still complete.
- **NFR-R3**: All API calls are wrapped in try-catch blocks; errors result in user-facing SnackBar messages, not app crashes.

#### Usability
- **NFR-U1**: The application shall follow a minimal, premium black-and-white design language.
- **NFR-U2**: Micro-animations (Flutter Animate library: fade-ins, slide-ins) shall be used throughout the trip planner for a polished feel.
- **NFR-U3**: Loading states shall be communicated via CircularProgressIndicator in the relevant UI element (not full-screen blocked states).
- **NFR-U4**: All interactive elements shall have sufficient hit targets (minimum 48×48 px per Material guidelines).

#### Maintainability
- **NFR-M1**: The codebase shall be organized into `pages/`, `services/`, `models/`, and `widgets/` packages.
- **NFR-M2**: The `BackendService` class provides a single interface to all external APIs, making API provider changes require edits only in that file.
- **NFR-M3**: The optional Python FastAPI backend mirrors the same API contract as the Dart service layer, enabling future backend delegation without changes to the UI.

#### Constraints
- The app requires active internet connectivity (Wi-Fi or mobile data) for all route planning and geocoding operations.
- The OSRM public server is rate-limited for heavy traffic; for production, a self-hosted OSRM instance is recommended.
- The Nominatim public API enforces a maximum of 1 request/second — the 600ms debounce partially mitigates this.
- OpenChargeMap has a daily request quota on free API keys.

#### Assumptions & Dependencies

| Assumption / Dependency | Detail |
|---|---|
| Flutter SDK | 3.x with Dart 3.5+ |
| flutter_map | ^7.0.2 — Interactive vector map rendering |
| latlong2 | ^0.9.1 — Latitude/Longitude coordinate operations |
| http | ^1.2.2 — HTTP client for REST API calls |
| geolocator | ^13.0.2 — GPS location access and streaming |
| permission_handler | ^11.3.1 — Runtime permission requests (Android/iOS) |
| url_launcher | ^6.3.0 — Opening routes in OpenStreetMap browser |
| flutter_animate | ^4.5.0 — Declarative animations |
| Nominatim Public API | Free, no key required, ≤1 req/sec |
| OSRM Public API | Free, no key required |
| Open Elevation API | Free, no key required |
| OpenChargeMap API | Free tier with API key (configured in environment) |

---

## System Analysis and Design

### Overall System Architecture

EvNavi follows a **3-tier layered architecture**:

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                    │
│  Flutter Widgets: HomePage, TripPlanPage, MapPage,      │
│  MapPickerPage, StationBottomSheet, ChargeStopCard,     │
│  StationMarker, LiquidGlassContainer                    │
└─────────────────────────┬───────────────────────────────┘
                          │ calls
┌─────────────────────────▼───────────────────────────────┐
│                   SERVICE / LOGIC LAYER                 │
│  BackendService (geocoding, routing, stations, battery  │
│  planning, elevation, haversine, binary search)         │
│  LocationService (GPS, permissions, streaming)          │
└─────────────────────────┬───────────────────────────────┘
                          │ HTTP (HTTPS REST)
┌─────────────────────────▼───────────────────────────────┐
│                   EXTERNAL APIs LAYER                   │
│  Nominatim (OSM) | OSRM | Open Elevation | OpenChargeMap│
└─────────────────────────────────────────────────────────┘
```

### Module Description

| Module | File(s) | Responsibility |
|---|---|---|
| **App Entry** | `main.dart` | MaterialApp setup, global theme, routing |
| **Home Page** | `home_page.dart` | Bottom nav, live map with stations, GPS centering |
| **Trip Planner** | `trip_plan_page.dart` | Origin/destination inputs, sliders, planning trigger |
| **Map View** | `map_page.dart` | Route display, charge stops, navigation mode |
| **Map Picker** | `map_picker_page.dart` | Tap-to-select location on map |
| **Backend Service** | `backend_service.dart` | All API calls + battery algorithm |
| **Location Service** | `location_service.dart` | GPS permissions, current position, position stream |
| **Route Model** | `route_model.dart` | RouteResult (points, distanceKm, durationMin) |
| **Station Model** | `station_model.dart` | Station (id, name, lat, lon, address, connectors, powerKw) |
| **Trip Plan Model** | `trip_plan_model.dart` | TripPlan, ChargeStop (stopIndex, lat, lon, distanceFromStart, stations) |
| **Station Marker** | `station_marker.dart` | Zoom-aware station icon on map |
| **Station Bottom Sheet** | `station_bottom_sheet.dart` | Modal with station details |
| **Charge Stop Card** | `charge_stop_card.dart` | Horizontal card for each charging stop |
| **Liquid Glass Container** | `liquid_glass_container.dart` | Glassmorphism backdrop filter container |
| **Python Backend** | `backend/main.py` | Optional FastAPI server mirroring the same endpoints |

---

### Data Flow Diagram

#### Level 0 DFD (Context Diagram)

```
                   ┌────────────┐
                   │            │
    User Input ───►│  EvNavi    ├──► Route Map with Charge Stops
    (Places,       │  System    │
    Battery%)      │            ├──► Station Info (name, power, type)
                   └─────┬──────┘
                         │
              External APIs (Nominatim, OSRM,
              Open Elevation, OpenChargeMap)
```

#### Level 1 DFD

```
User
 │
 ├── [D1] Enter Origin/Destination ──► [P1] Geocode Places ──► Nominatim API
 │                                          │
 │                                          ▼
 ├── [D2] Enter Battery%, Range    ──► [P2] Compute Route ──► OSRM API
 │                                          │
 │                                          ▼
 │                                     [P3] Fetch Elevations ──► Open Elevation API
 │                                          │
 │                                          ▼
 │                                     [P4] Run Battery Planner (on-device)
 │                                          │ identifies stop points
 │                                          ▼
 │                                     [P5] Fetch Stations ──► OpenChargeMap API
 │                                          │ (for each stop)
 │                                          ▼
 │                                     [P6] Re-route via Stops ──► OSRM API
 │                                          │
 │                                          ▼
 └──────────────────────────────────── Map Display (route + stops + markers)
```

---

### Use Case Diagram (Text Description)

**Actors**: EV Driver

| Use Case | Description |
|---|---|
| UC1: View Nearby Stations | Driver opens app; GPS location obtained; stations shown on map |
| UC2: Search Places | Driver types origin or destination; autocomplete suggestions populate |
| UC3: Pick Location on Map | Driver taps map picker and selects a point |
| UC4: Set Vehicle Parameters | Driver adjusts range and battery % sliders |
| UC5: Plan Route | Driver taps "Plan My Route"; algorithm runs; map opens |
| UC6: View Charge Stops | Driver sees stop cards at bottom, can tap to centre map |
| UC7: View Station Details | Driver taps station marker; bottom sheet shows details |
| UC8: Start Navigation | Driver taps "Start Navigation"; GPS stream activated; map follows position |
| UC9: Stop Navigation | Driver taps "Stop Navigation"; returns to route overview |
| UC10: Toggle Layers | Driver toggles Stations or Charge Stops visibility |
| UC11: Open in OSM | Driver taps OSM button; route opens in browser |

---

### Sequence Diagram — Trip Planning Flow

```
User       TripPlanPage     BackendService      Nominatim     OSRM       OpenElev      OCM API
 │                │                 │               │            │             │              │
 │─[tap Plan]────►│                 │               │            │             │              │
 │                │─[searchPlaces]─►│───GET /search─►│             │             │              │
 │                │◄────results─────│◄──[JSON]───────│             │             │              │
 │                │─[getRoute]─────►│─────────────────────GET /route►│             │              │
 │                │◄──RouteResult───│◄────GeoJSON────────────────────│             │              │
 │                │─[getBatteryPlan]►│                │            │             │              │
 │                │                 │──POST /lookup──────────────────────────────►│              │
 │                │                 │◄──elevations────────────────────────────────│              │
 │                │                 │  [run algorithm on device]  │             │              │
 │                │                 │─────────────────────────────────────GET /poi────────────►│
 │                │                 │◄──stations list──────────────────────────────────────────│
 │                │─[getRoute again]►│──────────────GET /route (via stops)───────►│             │
 │                │◄──final route───│◄────────────────────────────────────────────│             │
 │◄──MapPage opens │                │               │            │             │              │
```

---

### ER Diagram (Logical Data Entities)

```
┌─────────────────┐        ┌──────────────────────┐        ┌─────────────────────┐
│   RouteResult   │        │      TripPlan         │        │     ChargeStop       │
├─────────────────┤        ├──────────────────────┤        ├─────────────────────┤
│ points: LatLng[]│◄──────►│ stops: ChargeStop[]  │◄──────►│ stopIndex: int      │
│ distanceKm: f64 │        │ totalDistanceKm: f64 │        │ lat: float          │
│ durationMin: f64│        │ segments: Map[]      │        │ lon: float          │
└─────────────────┘        └──────────────────────┘        │ distanceFromStart   │
                                                            │ stations: Station[] │
                                                            └──────┬──────────────┘
                                                                   │ 1..*
                                                            ┌──────▼──────────────┐
                                                            │      Station        │
                                                            ├─────────────────────┤
                                                            │ id: int             │
                                                            │ name: String        │
                                                            │ lat: float          │
                                                            │ lon: float          │
                                                            │ address: String     │
                                                            │ connectionTypes: [] │
                                                            │ powerKw: float?     │
                                                            │ isOperational: bool │
                                                            └─────────────────────┘
```

---

### Database Design

EvNavi is **client-side only** — it does **not** use a local database. All data is fetched from external APIs at runtime and held in memory as Dart model objects (using `StatefulWidget` state). The data models are defined as Dart classes:

- **`RouteResult`** (`route_model.dart`): Stores the decoded list of LatLng coordinates plus distance and duration metadata from OSRM.
- **`Station`** (`station_model.dart`): Stores charging station data parsed from OpenChargeMap API response (ID, name, location, connection types, power output, operational status).
- **`TripPlan`** (`trip_plan_model.dart`): Stores the battery planner output — a list of `ChargeStop` objects and metadata.
- **`ChargeStop`** (`trip_plan_model.dart`): Stores a single charging stop: its route index, coordinates, distance from trip start, and list of nearby `Station` objects.

---

## APIs Used

### 1. Nominatim — OSM Geocoding API
- **Purpose**: Convert human-readable place names to geographic coordinates (geocoding) and reverse-geocode coordinates to country codes.
- **Base URL**: `https://nominatim.openstreetmap.org`
- **Endpoints Used**:
  - `GET /search?q={query}&format=json&limit=5&addressdetails=1&countrycodes={cc}` — Forward geocoding (place search with country bias).
  - `GET /reverse?lat={lat}&lon={lon}&format=json` — Reverse geocoding to detect the user's country code.
- **Authentication**: None. Uses Nominatim's open public API.
- **Rate Limit**: 1 request/second (mitigated by 600 ms input debounce).
- **Response**: JSON array of results → each with `lat`, `lon`, `display_name`, `address`.

### 2. OSRM — Open Source Routing Machine
- **Purpose**: Compute a real road driving route between two or more points.
- **Base URL**: `https://router.project-osrm.org`
- **Endpoint Used**: `GET /route/v1/driving/{lon1,lat1;lon2,lat2;...}?overview=full&geometries=geojson&steps=false`
- **Authentication**: None (public server).
- **Response**: JSON with `routes[]` → `geometry.coordinates` (GeoJSON array of [lon, lat] pairs), `distance` (meters), `duration` (seconds).
- **Processing**: The app maps coordinates to `LatLng` objects and divides distance by 1000 (to km) and duration by 60 (to minutes).
- **Multi-waypoint**: When charge stops are found, the app constructs a `{start}; {stop1}; {stop2}; ...; {end}` coordinate string to get a through-route.

### 3. Open Elevation API
- **Purpose**: Batch-fetch terrain elevation (metres above sea level) for route points.
- **Base URL**: `https://api.open-elevation.com`
- **Endpoint Used**: `POST /api/v1/lookup` with JSON body: `{"locations": [{"latitude": y, "longitude": x}, ...]}`
- **Authentication**: None (public API).
- **Response**: JSON with `results[]` → each with `elevation` (metres).
- **Sampling Strategy**: The route is sampled to a maximum of 120 evenly-spaced points before calling this API to stay within reasonable request sizes. Missing points between samples are filled via linear interpolation.

### 4. OpenChargeMap API
- **Purpose**: Retrieve real-world EV charging station data near a coordinate.
- **Base URL**: `https://api.openchargemap.io/v3/poi`
- **Endpoint Used**: `GET /v3/poi?latitude={lat}&longitude={lon}&distance={km}&distanceunit=KM&maxresults={n}&compact=true&verbose=false&key={key}`
- **Authentication**: API key (configured in environment). Free tier.
- **Response**: JSON array of POI (Point of Interest) objects → each with `AddressInfo`, `Connections`, `StatusType`.
- **Parsing**: `_parseStations()` extracts name, coordinates, connector type titles (a set to avoid duplicates), maximum power output, and operational status.
- **Usage in App**: Called 3 times during route planning:
  1. Home Page: stations within 50 km of current location.
  2. Battery Planner: stations within 35 km of each candidate stop point (up to 3 candidate distances per required stop).
  3. MapPage toggle: stations within dynamic radius (half the route distance, clamped 10–150 km) near route midpoint.

---

## Algorithms & Calculations

### 1. Haversine Great-Circle Distance Formula

The Haversine formula is used to calculate the shortest distance between two geographic coordinates on the surface of the Earth (a sphere).

**Formula:**
```
a = sin²(Δφ/2) + cos(φ₁) · cos(φ₂) · sin²(Δλ/2)
c = 2 · atan2(√a, √(1−a))
d = R · c
```
Where:
- `φ` = latitude in radians
- `λ` = longitude in radians
- `R` = 6371.0 km (Earth's mean radius)

**Dart Implementation (BackendService._haversine):**
```dart
static double _haversine(LatLng a, LatLng b) {
  const R = 6371.0;
  final phi1 = a.latitude * pi / 180;
  final phi2 = b.latitude * pi / 180;
  final dPhi = (b.latitude - a.latitude) * pi / 180;
  final dLam = (b.longitude - a.longitude) * pi / 180;
  final x = sin(dPhi / 2) * sin(dPhi / 2) +
      cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
  return 2 * R * asin(sqrt(x));
}
```
**Usage**: Called for each consecutive pair of route points to build a cumulative geometric distance array.

---

### 2. Elevation-Aware Effective Distance Calculation

The core innovation. The raw road distance between two points does **not** represent the actual energy cost of the journey for an EV. Climbing hills costs extra energy; descending recovers energy via regenerative braking.

**Energy Model:**
- Climbing **100 m** of altitude gains → adds **1.2 km** of equivalent consumption load.
- Descending **100 m** → recovers **0.6 km** of range (regenerative braking, approximately 50% efficiency).

**Dart Implementation:**
```dart
double stepConsumption = geometricDist;  // base cost = road distance
if (dAlt > 0) {
  // Uphill: add 1.2km per 100m climbed
  stepConsumption += (dAlt / 100.0) * 1.2;
} else if (dAlt < 0) {
  // Downhill: recover 0.6km per 100m descended (negative consumption)
  stepConsumption += (dAlt / 100.0) * 0.6;
}
// Cap regeneration at 1.5x the segment distance to stay realistic
cumEffective.add(cumEffective.last + max(stepConsumption, -geometricDist * 0.5));
```

---

### 3. Battery Depletion Planning Algorithm

This is the heart of EvNavi's intelligence. It determines **where** the EV needs to stop for charging.

**Inputs:**
- `route.points` — list of LatLng (decoded from OSRM)
- `rangeKm` — user's vehicle maximum range on full charge
- `batteryPct` — user's current battery percentage (0–100)
- Elevation data per point

**Algorithm Steps:**
1. **Build cumulative effective distance array** (`cumEffective[]`) — one value per route point.
2. **Build cumulative geometric distance array** (`cumGeometric[]`) — for geographic placement of stops.
3. **Set reserves:**
   - `minTripReserveKm = rangeKm × 10%` — safety buffer; never let battery below this on any leg.
   - `minDestReserveKm = rangeKm × 45%` — arrive at destination with at least 45% range remaining.
4. **Loop** while `currentActualRange − (totalEffectiveKm − currentEffectiveDist) < minDestReserveKm`:
   - Compute `limitJump` = how far we can go before hitting the trip reserve: `currentActualRange − minTripReserveKm`
   - Map this to a geographic route point using **binary search** on `cumEffective`.
   - **Scan 3 candidate distances** for real charging stations (at limit point, 30 km before, 60 km before).
   - Select the earliest candidate that has a real OpenChargeMap station.
   - If no station found, insert a virtual stop at the computed depletion point.
   - After each stop, set `currentActualRange = rangeKm` (assume full charge at the stop).
   - Repeat until the remaining effective distance is within `minDestReserveKm`.
5. **Return** a `TripPlan` with stops and segment metadata.

**Time Complexity**: O(S × N × log N) where S = number of stops (≤15), N = number of route points, and log N binary search for index lookup.

---

### 4. Binary Search for Route Index Lookup

Two binary search functions (`_findIndexForEffectiveDistance` and `_findIndexForDistance`) are used to efficiently locate the route point index corresponding to a given cumulative distance value. This is O(log N) compared to a naive O(N) linear scan, which is important when routes have thousands of GPS points.

```dart
static int _findIndexForDistance(List<double> cumDist, double target) {
  int low = 0, high = cumDist.length - 1;
  while (low < high) {
    int mid = (low + high) ~/ 2;
    if (cumDist[mid] < target) low = mid + 1;
    else high = mid;
  }
  return low;
}
```

---

### 5. Elevation Data Linear Interpolation

Since the Open Elevation API is called with a sampled subset of route points (up to 120), interpolation is needed to estimate elevations at all original points between samples.

**Formula**: Given sampled point at index `startIdx` with elevation `eStart` and the next sample at `endIdx` with `eEnd`, any intermediate point `j` has:
```
t = (j - startIdx) / (endIdx - startIdx)
elevation[j] = eStart + (eEnd - eStart) × t
```
This is linear interpolation, equivalent to assuming a constant gradient between sampled points.

---

## Module-wise Implementation

### Module 1: main.dart — Application Entry Point

Initialises the Flutter application `EvNaviApp`. Defines the global `ThemeData`:
- **Color scheme**: Light mode. Primary colour `#222222` (soft black), surface `#FFFFFF`.
- **BottomNavigationBarThemeData**: Selected item in black, unselected in grey.
- **CardThemeData**: White cards with 16 px border radius.
- **ElevatedButtonThemeData**: Black background, white text, rounded corners.
- **Font**: System SF Pro (iOS) / default (Android) for native feel.

---

### Module 2: home_page.dart — Home Screen

**State Variables:**
- `_currentIndex`: 0 = Home Map, 1 = Trip Plan (IndexedStack control).
- `_currentLocation`: null until GPS is acquired.
- `_stations`: list of nearby charging stations.
- `_isLoadingLocation`, `_isLoadingStations`: flags for loading indicators.
- `_isMapReady`: true after MapOptions.onMapReady fires.

**Key Methods:**
- `_getCurrentLocation()`: 2-phase GPS fetch (last known → high accuracy). Auto-triggers `_findNearStations()` once map and position are both ready.
- `_findNearStations()`: Queries OpenChargeMap at the current map centre within 50 km.

**UI Structure:**
- `IndexedStack` with 2 children: home map widget and `TripPlanPage`.
- Custom liquid glass bottom navigation bar (using `BackdropFilter` for blur effect).
- Home map contains: `FlutterMap` → `TileLayer` (OSM) + `MarkerLayer` (GPS dot + station markers) + gradient overlay + FABs.

---

### Module 3: trip_plan_page.dart — Trip Planner

**State Variables:**
- `_fromController`, `_toController`: TextEditingControllers for origin/destination.
- `_fromLat`, `_fromLon`, `_toLat`, `_toLon`: Coordinate storage for selected places.
- `_rangeKm` (default 300), `_batteryPct` (default 80): Vehicle parameters.
- `_fromSuggestions`, `_toSuggestions`: autocomplete lists.
- `_isPlanning`: flag to show planning spinner on button.
- `_debounce`: Timer for 600ms input debounce.

**Key Methods:**
- `_detectCountry()`: On init, gets GPS position then calls `BackendService.getCountryCode()` to bias search results.
- `_onFromChanged(val)` / `_onToChanged(val)`: Debounced search triggers with 600ms delay.
- `_selectFrom(place)` / `_selectTo(place)`: Parses lat/lon from suggestion, updates controller text.
- `_planRoute()`: Full trip planning pipeline — geocodes if needed, calls `BackendService`, navigates to `MapPage`.

**UI Components:**
- `_buildHeader()`: Logo + app name + subtitle.
- `_buildCard()`: White card with two search fields (from/to) + sliders.
- `_buildSearchField()`: Input field with location icon, map picker button, autocomplete dropdown.
- `_buildPlanButton()`: Full-width "PLAN MY ROUTE" button.
- `_buildFeatureChips()`: ⚡ CHARGING, 🗺️ LIVE MAP, 🔋 BATTERY chips.

---

### Module 4: map_page.dart — Route Map and Navigation

**State Variables:**
- `_state`: `MapState` enum (loading | ready | navigating | error).
- `_route`: `RouteResult` — full decoded polyline.
- `_tripPlan`: `TripPlan` — battery plan with stops.
- `_stations`: nearby general stations for display.
- `_navigationMode`: true during live navigation.
- `_currentLocation`: updates during live navigation.
- `_currentSpeed`: updated from GPS speed (m/s → km/h).
- `_showStations`, `_showChargeStops`: toggle flags for map layers.

**Key Methods:**
- `_loadData()`: Calls the full pipeline: route → battery plan → midpoint stations → reroute via stops. Sets state to ready.
- `_fitRoute()`: Uses `MapController.fitCamera(CameraFit.bounds(...))` to zoom/pan to show the full route.
- `_startNavigation()`: Gets GPS position, sets navigation mode, starts geolocator position stream.
- `_stopNavigation()`: Cancels stream, clears navigation state, calls `_fitRoute()`.
- `_findNearStations()`: Discover stations near the current map centre.

**UI Components:**
- `_buildMap()`: FlutterMap with TileLayer, PolylineLayer (blue with white border), conditional MarkerLayers (general stations, charge stops, origin/destination markers, GPS dot).
- `_buildTopBar()`: Translucent white gradient bar. Back button. Route labels. RouteSummaryChip (LiquidGlassContainer).
- `_buildControls()`: Toggle buttons (Stations, Charge Stops, OSM), Start/Stop Navigation primary button.
- `_buildSpeedometer()`: Positioned top-right box showing current speed in km/h.
- `_buildChargeStopsList()`: Horizontal `ListView.builder` of `ChargeStopCard` widgets.
- `_buildFloatingActionButtons()`: Mini FABs for station refresh and GPS re-centre.

---

### Module 5: map_picker_page.dart — Location Picker

A full-screen map where the user taps to set a location. Displays a crosshair at the tapped point. The confirm button in the bottom-right corner is disabled (grey) until a point is selected. On confirm, pops with the `LatLng` result.

---

### Module 6: backend_service.dart — Service Layer

Single `BackendService` static class. All methods are `static Future<...>`. Provides:
- `searchPlaces(query, {countryCode})` → `List<Map>` — Nominatim forward geocode.
- `geocode(query)` → `LatLng?` — Single coordinate lookup.
- `getRoute(waypoints)` → `RouteResult?` — OSRM routing.
- `getStations(center, {radiusKm, maxResults})` → `List<Station>` — OpenChargeMap query.
- `getBatteryPlan({route, rangeKm, batteryPct})` → `TripPlan?` — Full elevation + battery algorithm.
- `getCountryCode(lat, lon)` → `String?` — Nominatim reverse geocode.
- `_getElevations(points)` → `List<double>` — Open Elevation API with sampling + interpolation.
- `_haversine(a, b)` → `double` — Great-circle distance.
- `_findIndexForEffectiveDistance(cumEffective, target)` → `int` — Binary search.
- `_findIndexForDistance(cumDist, target)` → `int` — Binary search.
- `_parseStations(data)` → `List<Station>` — OpenChargeMap JSON parser.

---

### Module 7: location_service.dart — GPS Service

Wraps the `geolocator` package:
- `getCurrentPosition()` → `Position?`: Requests permission if not granted. Returns current high-accuracy position or null on failure.
- `getLastKnownPosition()` → `Position?`: Returns cached last position immediately for UI pre-display.
- `getPositionStream()` → `Stream<Position>`: Returns a continuous GPS stream used during live navigation (updates every meter / 2 seconds).

---

### Module 8: Python FastAPI Backend (backend/main.py)

An optional REST API server with 4 endpoints:
- `GET /` — Health check.
- `GET /geocode?q={query}` — Nominatim geocoding proxy.
- `GET /route?start_lat=&start_lon=&end_lat=&end_lon=` — OSRM routing with Google-encoded polyline decode.
- `GET /stations?lat=&lon=&radius_km=&max_results=` — OpenChargeMap stations proxy.
- `POST /battery_plan` — Battery stop planning (simplified version: 85% safety threshold, no elevation).

The backend is built with **FastAPI** and **httpx** for async HTTP calls. It uses **pydantic** models for request/response validation and **CORSMiddleware** for development cross-origin access.

> **Note**: In the current production version of EvNavi, the Flutter app calls external APIs directly without routing through this backend. The Python backend serves as the original prototype and can be deployed on any server to act as a proxy/gateway.

---

## Development Environment

| Component | Detail |
|---|---|
| **IDE** | Visual Studio Code with Flutter & Dart extensions |
| **Flutter SDK** | 3.x (Dart SDK ^3.5.0) |
| **Language** | Dart (frontend), Python 3.9+ (optional backend) |
| **Android SDK** | API Level 21 (Android 5.0) minimum |
| **Target Platform** | Android (primary), iOS |
| **Version Control** | Git |
| **API Testing** | Postman / browser for API endpoint testing |
| **Python Backend** | FastAPI + Uvicorn + httpx |
| **Map Tiles** | OpenStreetMap (tile.openstreetmap.org) |
| **Build Tool** | Flutter build / Gradle (Android) |
| **App Icon Tool** | flutter_launcher_icons ^0.13.1 |

### Key Flutter Dependencies

```yaml
dependencies:
  flutter_map: ^7.0.2            # Interactive vector map
  latlong2: ^0.9.1               # LatLng coordinate type
  http: ^1.2.2                   # HTTP REST client
  geolocator: ^13.0.2            # GPS location access
  permission_handler: ^11.3.1    # Runtime permissions
  url_launcher: ^6.3.0           # External URL/map opening
  flutter_animate: ^4.5.0        # Declarative animations

dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # App icon generation
```

### Python Backend Dependencies (requirements.txt)

```
fastapi
uvicorn[standard]
httpx
pydantic
```

---

## Conclusion

EvNavi is a fully functional, production-quality EV trip planning application that solves the real-world problem of range anxiety through intelligent, terrain-aware battery planning. The application:

1. **Uses only free, open APIs** — making it accessible and deployable at zero cost.
2. **Implements a novel elevation-aware battery model** — going beyond flat-distance estimation to account for real terrain energy consumption and regenerative braking.
3. **Integrates real-world charging station data** through OpenChargeMap — placing stops at actual, operational chargers.
4. **Recalculates routes through charging stops** — ensuring the displayed route is driveable and accurate.
5. **Provides live GPS navigation** — completing the user journey from planning to arrival.
6. **Is structured with clean architecture** — layered services/models/widgets pattern makes it maintainable and extensible.

The application demonstrates a comprehensive integration of mobile development (Flutter/Dart), geospatial algorithms (Haversine, binary search, linear interpolation), energy physics (elevation-consumption model, regenerative braking), and REST API integration (Nominatim, OSRM, Open Elevation, OpenChargeMap).

---

*EvNavi — Drive Electric. Navigate Smart.*
