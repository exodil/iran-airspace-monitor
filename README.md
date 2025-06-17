# 🛩️ Iran Airspace Monitor

**Real-time aircraft tracking system for Iranian FIR (Flight Information Region)**

Live at: [iranairspacemonitor.xyz](https://iranairspacemonitor.xyz)

## ✨ Features

- 🌍 **Real-time tracking** of aircraft in Iran FIR zone
- 🔔 **Push notifications** for new aircraft entries
- 📱 **Mobile responsive** design
- 🗺️ **Interactive map** with live aircraft positions
- 📊 **Aircraft details** including ICAO, callsign, altitude
- 🔐 **OAuth2 authentication** with OpenSky Network

## 🚀 Deployment on GoDaddy

### Prerequisites

1. **Domain**: Purchase `iranairspacemonitor.xyz` from GoDaddy
2. **Hosting**: Get GoDaddy shared hosting with Python support
3. **SSL Certificate**: Enable SSL/HTTPS (recommended)

### Step-by-Step Deployment

#### 1. Enable SSH Access
- Go to cPanel → Settings → Server → SSH Access → Enable
- Wait 24-48 hours for activation

#### 2. Upload Files
Upload all project files to your hosting directory:
```
/home/username/iranairspacemonitor/
├── app.py
├── passenger_wsgi.py
├── requirements.txt
├── .htaccess
├── sw.js
├── templates/
│   └── index.html
└── static/
    ├── style.css
    └── main.js
```

#### 3. Setup Python App in cPanel
- Go to cPanel → Software → Setup Python App
- Click "Create Application"
- Configure:
  - **Python Version**: 3.8+ (latest available)
  - **Application Root**: `/home/username/iranairspacemonitor`
  - **Application URL**: `iranairspacemonitor.xyz`
  - **Application Startup File**: `app.py`
  - **Application Entry Point**: `app`
  - **Passenger Log File**: `/home/username/logs/iranairspace.log`

#### 4. Install Dependencies
- Add `requirements.txt` to Configuration Files
- Click "Run Pip Install"

#### 5. Virtual Environment Setup
Activate your virtual environment:
```bash
source /home/username/virtualenv/iranairspacemonitor/3.8/bin/activate
cd /home/username/iranairspacemonitor
```

#### 6. Update Dependencies (if needed)
```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

#### 7. Restart Application
To restart without cPanel (preserves custom files):
```bash
touch tmp/restart.txt
```

### 🔧 Configuration

#### Environment Variables
Update these in `app.py` for your setup:
- `CLIENT_ID`: Your OpenSky Network client ID
- `CLIENT_SECRET`: Your OpenSky Network client secret
- `VAPID_KEYS`: Generate new VAPID keys for notifications

#### Domain Configuration
Update domain references in:
- `sw.js` (line 71, 78)
- Any absolute URLs in templates

### 📱 Features Configuration

#### Push Notifications
The app uses Web Push API with VAPID authentication. Users can:
1. Click "Enable Notifications" button
2. Grant browser permission
3. Receive real-time alerts for new aircraft

#### Aircraft Tracking
- Updates every 60 seconds
- Covers Iran FIR coordinates
- Filters airborne aircraft only
- Stores last seen aircraft to detect new entries

### 🛠️ Development

#### Local Development
```bash
pip install -r requirements.txt
python app.py
```
Visit: `http://localhost:5001`

#### Production Considerations
- SSL/HTTPS required for push notifications
- Background thread runs continuously
- Thread-safe data handling with locks
- Error handling for API failures

### 📊 API Endpoints

- `GET /` - Main web interface
- `GET /api/aircrafts` - JSON list of current aircraft
- `POST /api/subscribe` - Subscribe to push notifications
- `GET /sw.js` - Service worker for notifications

### 🔒 Security

- OpenSky Network OAuth2 authentication
- HTTPS enforcement via .htaccess
- Input validation and sanitization
- Rate limiting considerations

### 📈 Monitoring

Check application logs:
```bash
tail -f /home/username/logs/iranairspace.log
```

### 🆘 Troubleshooting

#### Common Issues
1. **SSH Access**: Wait 24-48 hours after enabling
2. **Python Version**: Ensure compatible version (3.8+)
3. **Dependencies**: Check virtual environment activation
4. **Permissions**: Verify file permissions (644 for files, 755 for directories)
5. **Restart**: Use `touch tmp/restart.txt` instead of cPanel restart

#### Log Files
- Application logs: `/home/username/logs/iranairspace.log`
- Error logs: Check cPanel error logs
- Access logs: Monitor via cPanel

### 📝 License

This project is open source and available under the MIT License.

### 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### 📞 Support

For issues related to:
- **OpenSky API**: Contact OpenSky Network support
- **GoDaddy Hosting**: Contact GoDaddy technical support
- **Application Issues**: Create an issue in this repository

---

**Made with ❤️ for aviation enthusiasts worldwide** 