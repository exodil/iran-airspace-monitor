# app.py (Cloud Hosting Version)

import requests
import time
import json
import threading
import os
from flask import Flask, jsonify, render_template, request, send_from_directory
from shapely.geometry import Point, Polygon
from pywebpush import webpush, WebPushException

# --- CONFIGURATION ---
CLIENT_ID = "manasalperen-api-client"
CLIENT_SECRET = "lEY6vy6XT8Bj29nulZ5fzRKYciumQFuk"
TOKEN_URL = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"
API_URL = "https://opensky-network.org/api/states/all"
BBOX_COORDS = {"lamin": 25.0, "lamax": 40.0, "lomin": 44.0, "lomax": 63.5}

# VAPID KEYS (PRODUCTION)
VAPID_PRIVATE_KEY = "SIG4rDLGpDq5k8HV6tbFkrMt8ZHnDc2RqnRA00SeEsI"
VAPID_PUBLIC_KEY = "BPPENiv0a5qrc1XrQgvxmndHiwyRsp6_5MtfkM5MvM0c-cLo2L3g6fCpsyg1JFUMmMxRSs81XyWovdcoI6Nvwnk"
VAPID_CLAIMS = {"sub": "mailto:manasalperen@gmail.com"}

IRAN_FIR_COORDS = [
    (46.5, 36.5), (47.2, 36.8), (47.5, 38.2), (48.5, 38.5), (49.0, 38.2), (49.8, 37.8), 
    (50.2, 37.2), (49.8, 36.8), (50.0, 36.2), (49.2, 35.2), (49.8, 34.0), (49.5, 33.2), 
    (48.8, 32.5), (49.0, 32.0), (49.5, 31.2), (51.0, 30.5), (52.0, 29.8), (52.5, 29.0), 
    (53.2, 28.0), (53.8, 27.8), (55.0, 27.2), (57.0, 27.0), (58.0, 27.2), (59.0, 27.8), 
    (59.8, 28.5), (60.5, 29.2), (61.0, 30.0), (60.2, 31.2), (59.8, 34.0), (60.8, 35.5), 
    (59.8, 36.2), (58.8, 36.8), (56.0, 37.2), (54.0, 37.5), (51.8, 38.5), (50.5, 38.8), 
    (47.8, 38.2), (46.5, 36.5)
]
IRAN_FIR_POLYGON = Polygon(IRAN_FIR_COORDS)

app = Flask(__name__)

# --- Global Variables ---
access_token = None
token_expiry = 0
tracked_aircrafts_in_zone = {} 
push_subscriptions = []  # Store notification subscriptions here
data_lock = threading.Lock()

def get_access_token():
    global access_token, token_expiry
    data = {"grant_type": "client_credentials", "client_id": CLIENT_ID, "client_secret": CLIENT_SECRET}
    try:
        response = requests.post(TOKEN_URL, data=data)
        response.raise_for_status()
        token_data = response.json()
        access_token = token_data["access_token"]
        token_expiry = time.time() + token_data.get("expires_in", 1800) - 300
        print("INFO: New access token obtained.")
    except Exception as e:
        print(f"FATAL: Could not get access token. Error: {e}")
        access_token = None

def ensure_token():
    if not access_token or time.time() > token_expiry:
        get_access_token()

def send_notification(subscription, payload):
    """Send notification to a specific subscription."""
    try:
        webpush(
            subscription_info=subscription,
            data=json.dumps(payload),
            vapid_private_key=VAPID_PRIVATE_KEY,
            vapid_claims=VAPID_CLAIMS
        )
    except WebPushException as ex:
        # If subscription is invalid (e.g. user revoked permission), remove from list
        if ex.response and ex.response.status_code == 410:
            with data_lock:
                if subscription in push_subscriptions:
                    push_subscriptions.remove(subscription)
                    print("INFO: Stale subscription removed.")
        else:
            print(f"ERROR: WebPushException: {ex}")
    except Exception as e:
        print(f"ERROR: Failed to send notification: {e}")

def background_tracker():
    """Main function that runs in background and sends notifications."""
    seen_aircraft_icao = set()
    global tracked_aircrafts_in_zone
    
    while True:
        ensure_token()
        if not access_token:
            print("ERROR: No access token, waiting 60s to retry...")
            time.sleep(60)
            continue

        try:
            headers = {"Authorization": f"Bearer {access_token}"}
            response = requests.get(API_URL, headers=headers, params=BBOX_COORDS, timeout=20)
            response.raise_for_status()
            all_states_in_bbox = response.json().get('states', [])
            
            current_aircraft_icao = set()
            current_aircraft_details = {}
            for state in all_states_in_bbox:
                icao_id, callsign, origin, _, _, lon, lat, _, on_ground = state[:9]
                if lon and lat and not on_ground and IRAN_FIR_POLYGON.contains(Point(lon, lat)):
                    icao_id = icao_id.strip()
                    current_aircraft_icao.add(icao_id)
                    current_aircraft_details[icao_id] = {
                        "icao": icao_id, 
                        "callsign": callsign.strip() if callsign else "N/A",
                        "origin": origin,
                        "lat": lat, 
                        "lon": lon, 
                        "altitude": state[7] if state[7] else 0
                    }

            # --- NOTIFICATION SENDING LOGIC ---
            newly_entered_aircraft = current_aircraft_icao - seen_aircraft_icao
            if newly_entered_aircraft:
                print(f"\n!!! {len(newly_entered_aircraft)} NEW AIRCRAFT DETECTED. SENDING NOTIFICATIONS. !!!")
                for icao in newly_entered_aircraft:
                    details = current_aircraft_details[icao]
                    notification_payload = {
                        "title": "Iran Airspace Alert",
                        "body": f"Aircraft {details['callsign']} ({details['icao']}) has entered the FIR."
                    }
                    with data_lock:
                        for sub in push_subscriptions:
                            send_notification(sub, notification_payload)
            # ------------------------------------

            seen_aircraft_icao = current_aircraft_icao
            with data_lock:
                tracked_aircrafts_in_zone = current_aircraft_details
            
            print(f"INFO: Tracking {len(tracked_aircrafts_in_zone)} aircrafts. {len(push_subscriptions)} subscribers.")

        except Exception as e:
            print(f"ERROR in background thread: {e}")

        time.sleep(60)

# --- WEB ROUTES ---
@app.route('/')
def index():
    return render_template('index.html', vapid_public_key=VAPID_PUBLIC_KEY)

@app.route('/api/aircrafts')
def get_aircrafts():
    with data_lock:
        return jsonify(list(tracked_aircrafts_in_zone.values()))

@app.route('/api/subscribe', methods=['POST'])
def subscribe():
    """Receive and store user subscription."""
    subscription = request.json
    with data_lock:
        if subscription not in push_subscriptions:
            push_subscriptions.append(subscription)
            print("INFO: New subscriber added.")
    return jsonify({"status": "success"}), 201

@app.route('/sw.js')
def service_worker():
    """Serve service worker file."""
    return send_from_directory('.', 'sw.js')

# Cloud hosting compatible configuration
if __name__ == "__main__":
    # Start background tracker thread
    tracker_thread = threading.Thread(target=background_tracker, daemon=True)
    tracker_thread.start()
    
    # Use PORT environment variable for cloud hosting (Railway, Render, etc.)
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port) 