// static/main.js (Global Version)

// Check if browser supports Service Worker and Push API
if ('serviceWorker' in navigator && 'PushManager' in window) {
    console.log('Service Worker and Push is supported');
    navigator.serviceWorker.register('/sw.js')
        .then(function(swReg) {
            console.log('Service Worker is registered', swReg);
            window.swRegistration = swReg;
            initializeUI();
        })
        .catch(function(error) {
            console.error('Service Worker Error', error);
        });
} else {
    console.warn('Push messaging is not supported');
    const btn = document.getElementById('enable-notifications-btn');
    if (btn) {
        btn.textContent = 'Push Not Supported';
    }
}

function initializeUI() {
    const notificationButton = document.getElementById('enable-notifications-btn');
    if (notificationButton) {
        notificationButton.addEventListener('click', function() {
            // Start subscription process when button is clicked
            subscribeUser();
        });
        
        // Check current subscription status
        window.swRegistration.pushManager.getSubscription()
            .then(function(subscription) {
                const isSubscribed = !(subscription === null);
                if (isSubscribed) {
                    console.log('User IS subscribed.');
                } else {
                    console.log('User is NOT subscribed.');
                }
                updateBtn(isSubscribed);
            });
    }
}

function updateBtn(isSubscribed) {
    const notificationButton = document.getElementById('enable-notifications-btn');
    if (!notificationButton) return;
    
    if (Notification.permission === 'denied') {
        notificationButton.textContent = 'Notifications Blocked';
        notificationButton.disabled = true;
        return;
    }

    if (isSubscribed) {
        notificationButton.textContent = 'Notifications Enabled';
        notificationButton.disabled = true;
    } else {
        notificationButton.textContent = 'Enable Notifications';
        notificationButton.disabled = false;
    }
}

function subscribeUser() {
    console.log('VAPID_PUBLIC_KEY:', VAPID_PUBLIC_KEY);
    console.log('Starting subscription process...');
    
    // Check notification permission
    if (Notification.permission === 'denied') {
        console.log('Notifications are denied');
        alert('Notifications are blocked! Please enable them in your browser settings.');
        return;
    }
    
    // Request notification permission first
    console.log('Current permission:', Notification.permission);
    
    if (Notification.permission === 'default') {
        console.log('Requesting notification permission...');
        Notification.requestPermission().then(function(permission) {
            console.log('Permission result:', permission);
            if (permission === 'granted') {
                console.log('Permission granted, proceeding with subscription');
                proceedWithSubscription();
            } else {
                console.log('Permission denied');
                alert('Notification permission is required!');
                updateBtn(false);
            }
        });
    } else if (Notification.permission === 'granted') {
        console.log('Permission already granted');
        proceedWithSubscription();
    }
}

function proceedWithSubscription() {
    // Convert Vapid key to URL-safe base64
    const applicationServerKey = urlB64ToUint8Array(VAPID_PUBLIC_KEY);
    console.log('Converted key length:', applicationServerKey.length);
    
    console.log('Requesting subscription...');
    window.swRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: applicationServerKey
    })
    .then(function(subscription) {
        console.log('User is subscribed:', subscription);
        // Send subscription to backend
        return fetch('/api/subscribe', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(subscription)
        });
    })
    .then(function(response) {
        if (response.ok) {
            console.log('Subscription sent to server successfully.');
            updateBtn(true);
        } else {
            console.log('Server response not ok:', response.status);
        }
    })
    .catch(function(err) {
        console.error('DETAILED ERROR:', err);
        console.error('Error name:', err.name);
        console.error('Error message:', err.message);
        
        if (err.name === 'NotAllowedError') {
            alert('Notification permission denied! Please enable notifications in your browser settings.');
        } else if (err.name === 'NotSupportedError') {
            alert('This browser does not support push notifications!');
        } else {
            alert('Error setting up notifications: ' + err.message);
        }
        
        updateBtn(false);
    });
}

// Helper function to convert VAPID key to correct format
function urlB64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding).replace(/\-/g, '+').replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
}

// ---- Existing Map and List Update Code ----
document.addEventListener('DOMContentLoaded', function() {
    // Initialize map centered on Iran (adjusted for reduced area)
    const map = L.map('map').setView([32.5, 54.0], 6);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    // Iran FIR coordinates (even more reduced version)
    const iranFirCoords = [
        [36.5, 46.5], [36.8, 47.2], [38.2, 47.5], [38.5, 48.5], [38.2, 49.0], [37.8, 49.8], 
        [37.2, 50.2], [36.8, 49.8], [36.2, 50.0], [35.2, 49.2], [34.0, 49.8], [33.2, 49.5], 
        [32.5, 48.8], [32.0, 49.0], [31.2, 49.5], [30.5, 51.0], [29.8, 52.0], [29.0, 52.5], 
        [28.0, 53.2], [27.8, 53.8], [27.2, 55.0], [27.0, 57.0], [27.2, 58.0], [27.8, 59.0], 
        [28.5, 59.8], [29.2, 60.5], [30.0, 61.0], [31.2, 60.2], [34.0, 59.8], [35.5, 60.8], 
        [36.2, 59.8], [36.8, 58.8], [37.2, 56.0], [37.5, 54.0], [38.5, 51.8], [38.8, 50.5], 
        [38.2, 47.8], [36.5, 46.5]
    ];

    // Add Iran FIR zone to map in red
    const iranFirPolygon = L.polygon(iranFirCoords, {
        color: '#ff0000',        // Border color (red)
        fillColor: '#ff0000',    // Fill color (red) 
        fillOpacity: 0.2,        // Transparency (20%)
        weight: 2                // Border thickness
    }).addTo(map);

    // Add popup
    iranFirPolygon.bindPopup('<b>Iran FIR (Reduced)</b><br>Notifications will be sent for aircraft entering this zone.');

    let aircraftMarkers = {}; // Store aircraft icons

    async function fetchAndUpdateAircraft() {
        try {
            const response = await fetch('/api/aircrafts');
            const aircrafts = await response.json();

            document.getElementById('aircraft-count').textContent = aircrafts.length;
            const listElement = document.getElementById('aircraft-list');
            listElement.innerHTML = ''; // Clear list

            const currentIcaos = new Set();

            aircrafts.forEach(ac => {
                currentIcaos.add(ac.icao);
                
                // Update list
                const listItem = document.createElement('li');
                listItem.textContent = `ICAO: ${ac.icao}, Callsign: ${ac.callsign}, Alt: ${ac.altitude ? Math.round(ac.altitude * 3.28084) : 'N/A'} ft`;
                listElement.appendChild(listItem);

                // Update map
                if (aircraftMarkers[ac.icao]) {
                    // Move existing marker
                    aircraftMarkers[ac.icao].setLatLng([ac.lat, ac.lon]);
                } else {
                    // Create new marker
                    aircraftMarkers[ac.icao] = L.marker([ac.lat, ac.lon])
                        .addTo(map)
                        .bindPopup(`<b>${ac.callsign}</b><br>ICAO: ${ac.icao}`);
                }
            });

            // Remove old markers from map (no longer in list)
            Object.keys(aircraftMarkers).forEach(icao => {
                if (!currentIcaos.has(icao)) {
                    map.removeLayer(aircraftMarkers[icao]);
                    delete aircraftMarkers[icao];
                }
            });

        } catch (error) {
            console.error("Error fetching aircraft data:", error);
        }
    }

    // Update data on page load and every 15 seconds
    fetchAndUpdateAircraft();
    setInterval(fetchAndUpdateAircraft, 15000);
}); 