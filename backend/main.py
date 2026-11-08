"""
EV Route Optimizer — Python FastAPI Backend
Endpoints:
  GET /geocode      — Nominatim geocoding
  GET /route        — OSRM routing
  GET /stations     — OpenChargeMap charging stations
  POST /battery_plan — Smart charging stop planner
"""

import math
from typing import List, Optional
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import httpx
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="EV Route Optimizer API", version="1.0.0")

# Allow all origins for development (Flutter app on any device/emulator)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Configuration ────────────────────────────────────────────────────────────
OSRM_BASE      = os.getenv("OSRM_BASE", "http://router.project-osrm.org/route/v1/driving")
NOMINATIM_BASE = os.getenv("NOMINATIM_BASE", "https://nominatim.openstreetmap.org/search")
OCM_BASE       = os.getenv("OCM_BASE", "https://api.openchargemap.io/v3/poi")
OCM_API_KEY    = os.getenv("OCM_API_KEY", "")
HEADERS        = {"User-Agent": "EVNaviApp/1.0 (student project)"}

# ─── Pydantic models ──────────────────────────────────────────────────────────

class LatLon(BaseModel):
    lat: float
    lon: float
    display_name: Optional[str] = None

class RoutePoint(BaseModel):
    lat: float
    lon: float

class RouteResult(BaseModel):
    points: List[RoutePoint]       # decoded polyline points
    distance_km: float
    duration_min: float

class Station(BaseModel):
    id: int
    name: str
    lat: float
    lon: float
    address: str
    connection_types: List[str]
    power_kw: Optional[float]
    is_operational: bool

class BatteryPlanRequest(BaseModel):
    points: List[RoutePoint]
    distance_km: float
    range_km: float                # max range on full charge
    battery_pct: float             # current battery percentage 0-100

class ChargeStop(BaseModel):
    stop_index: int                # index in the route points list
    lat: float
    lon: float
    distance_from_start_km: float
    stations: List[Station]

class BatteryPlanResponse(BaseModel):
    stops: List[ChargeStop]
    total_distance_km: float
    segments: List[dict]           # each segment {from, to_km, battery_pct_used}


# ─── Helpers ──────────────────────────────────────────────────────────────────

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance in km between two points."""
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2)**2
    return 2 * R * math.asin(math.sqrt(a))


def decode_polyline(encoded: str) -> List[RoutePoint]:
    """Decode Google Encoded Polyline format used by OSRM."""
    points = []
    index = 0
    lat = 0
    lon = 0
    while index < len(encoded):
        b, shift, result = 0, 0, 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        dlat = ~(result >> 1) if result & 1 else result >> 1
        lat += dlat

        b, shift, result = 0, 0, 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        dlon = ~(result >> 1) if result & 1 else result >> 1
        lon += dlon
        points.append(RoutePoint(lat=lat / 1e5, lon=lon / 1e5))
    return points


def parse_stations(data: list) -> List[Station]:
    """Parse OpenChargeMap POI response into Station objects."""
    stations = []
    for item in data:
        try:
            addr_info = item.get("AddressInfo", {})
            connections = item.get("Connections", [])
            conn_types = []
            max_kw = None
            for c in connections:
                ct = c.get("ConnectionType", {})
                title = ct.get("Title", "")
                if title:
                    conn_types.append(title)
                if c.get("PowerKW"):
                    max_kw = max(max_kw or 0, c["PowerKW"])

            status_type = item.get("StatusType") or {}
            is_operational = status_type.get("IsOperational", True) if isinstance(status_type, dict) else True

            stations.append(Station(
                id=item.get("ID", 0),
                name=addr_info.get("Title", "Charging Station"),
                lat=addr_info.get("Latitude", 0.0),
                lon=addr_info.get("Longitude", 0.0),
                address=addr_info.get("AddressLine1", "") or addr_info.get("Town", ""),
                connection_types=list(set(conn_types)),
                power_kw=max_kw,
                is_operational=is_operational,
            ))
        except Exception:
            continue
    return stations


# ─── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {"status": "EV Route Optimizer API is running", "version": "1.0.0"}


@app.get("/geocode", response_model=List[LatLon])
async def geocode(q: str = Query(..., description="Place name to geocode")):
    """Geocode a location name using Nominatim (OpenStreetMap)."""
    params = {"q": q, "format": "json", "limit": 5, "addressdetails": 1}
    async with httpx.AsyncClient(headers=HEADERS, timeout=10) as client:
        resp = await client.get(NOMINATIM_BASE, params=params)
        resp.raise_for_status()
        results = resp.json()
    if not results:
        raise HTTPException(status_code=404, detail=f"Location '{q}' not found")
    return [
        LatLon(
            lat=float(r["lat"]),
            lon=float(r["lon"]),
            display_name=r.get("display_name", ""),
        )
        for r in results
    ]


@app.get("/route", response_model=RouteResult)
async def get_route(
    start_lat: float = Query(...),
    start_lon: float = Query(...),
    end_lat: float = Query(...),
    end_lon: float = Query(...),
):
    """Get driving route between two coordinates using OSRM."""
    url = f"{OSRM_BASE}/{start_lon},{start_lat};{end_lon},{end_lat}"
    params = {"overview": "full", "geometries": "polyline", "steps": "false"}
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, params=params)
        resp.raise_for_status()
        data = resp.json()

    if data.get("code") != "Ok" or not data.get("routes"):
        raise HTTPException(status_code=500, detail="OSRM routing failed")

    route = data["routes"][0]
    encoded = route["geometry"]
    points = decode_polyline(encoded)
    distance_km = route["distance"] / 1000
    duration_min = route["duration"] / 60

    return RouteResult(points=points, distance_km=distance_km, duration_min=duration_min)


@app.get("/stations", response_model=List[Station])
async def get_stations(
    lat: float = Query(...),
    lon: float = Query(...),
    radius_km: float = Query(50, ge=1, le=500),
    max_results: int = Query(50, ge=1, le=200),
):
    """Fetch charging stations near a coordinate using OpenChargeMap."""
    params = {
        "output": "json",
        "latitude": lat,
        "longitude": lon,
        "distance": radius_km,
        "distanceunit": "KM",
        "maxresults": max_results,
        "compact": True,
        "verbose": False,
        "key": OCM_API_KEY,
    }
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.get(OCM_BASE, params=params)
        resp.raise_for_status()
        data = resp.json()

    return parse_stations(data)


@app.post("/battery_plan", response_model=BatteryPlanResponse)
async def battery_plan(req: BatteryPlanRequest):
    """
    Calculate where the EV needs to stop for charging along the route.
    
    Algorithm:
    1. Compute cumulative distance at each route point.
    2. Find points where battery would be depleted (using 85% safety threshold).
    3. For each stop point, look up nearby charging stations.
    4. Return the list of stop points with station suggestions.
    """
    if not req.points or len(req.points) < 2:
        raise HTTPException(status_code=400, detail="Route must have at least 2 points")

    # Build cumulative distances along the route
    cum_dist = [0.0]
    for i in range(1, len(req.points)):
        p0, p1 = req.points[i - 1], req.points[i]
        d = haversine_km(p0.lat, p0.lon, p1.lat, p1.lon)
        cum_dist.append(cum_dist[-1] + d)

    total_km = cum_dist[-1]
    usable_range = req.range_km * (req.battery_pct / 100.0)
    # Use 85% of usable range as safety buffer
    safety_range = usable_range * 0.85

    stops: List[ChargeStop] = []
    segments = []
    current_charge_km = 0.0   # km traveled since last charge
    last_charge_dist = 0.0    # cumulative distance at last charge point

    # Collect stop distances (where we need to charge)
    stop_distances = []
    charged_range = safety_range  # on first leg, we have initial battery

    while last_charge_dist + charged_range < total_km:
        stop_at = last_charge_dist + charged_range
        stop_distances.append(stop_at)
        segments.append({
            "from_km": round(last_charge_dist, 2),
            "to_km": round(stop_at, 2),
            "range_used_km": round(charged_range, 2),
        })
        last_charge_dist = stop_at
        charged_range = req.range_km * 0.85   # assume full charge at stop

    # Final segment
    segments.append({
        "from_km": round(last_charge_dist, 2),
        "to_km": round(total_km, 2),
        "range_used_km": round(total_km - last_charge_dist, 2),
    })

    # For each stop distance, find the nearest route point and fetch stations
    async with httpx.AsyncClient(timeout=20) as client:
        for stop_dist in stop_distances:
            # Find closest route point index to this distance
            best_i = min(
                range(len(cum_dist)),
                key=lambda i: abs(cum_dist[i] - stop_dist)
            )
            stop_pt = req.points[best_i]

            # Fetch charging stations within 30 km of this stop
            params = {
                "output": "json",
                "latitude": stop_pt.lat,
                "longitude": stop_pt.lon,
                "distance": 30,
                "distanceunit": "KM",
                "maxresults": 10,
                "compact": True,
                "verbose": False,
                "key": OCM_API_KEY,
            }
            try:
                resp = await client.get(OCM_BASE, params=params)
                resp.raise_for_status()
                station_data = resp.json()
                nearby_stations = parse_stations(station_data)
            except Exception:
                nearby_stations = []

            stops.append(ChargeStop(
                stop_index=best_i,
                lat=stop_pt.lat,
                lon=stop_pt.lon,
                distance_from_start_km=round(stop_dist, 2),
                stations=nearby_stations[:5],
            ))

    return BatteryPlanResponse(
        stops=stops,
        total_distance_km=round(total_km, 2),
        segments=segments,
    )
