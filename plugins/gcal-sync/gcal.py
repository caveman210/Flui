#!/usr/bin/env python3
import sys
import os
import json
import time
import urllib.request
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import webbrowser
from datetime import datetime, timezone, timedelta

# Standard XDG cache directory: ~/.cache/quickshell/gcal/
CACHE_DIR = os.path.expanduser("~/.cache/quickshell/gcal")
os.makedirs(CACHE_DIR, exist_ok=True)

TOKEN_FILE = os.path.join(CACHE_DIR, "tokens.json")
CACHE_FILE = os.path.join(CACHE_DIR, "events.json")
CREDS_FILE = os.path.join(CACHE_DIR, "credentials.json")

AUTH_URI = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URI = "https://oauth2.googleapis.com/token"
CALENDAR_API = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]

def get_client_credentials():
    if os.path.exists(CREDS_FILE):
        try:
            with open(CREDS_FILE, "r") as f:
                data = json.load(f)
                if "installed" in data:
                    return data["installed"]
                return data
        except Exception:
            pass
    return None

def load_token():
    if not os.path.exists(TOKEN_FILE):
        return None
    try:
        with open(TOKEN_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return None

def save_token(token_data):
    with open(TOKEN_FILE, "w") as f:
        json.dump(token_data, f, indent=2)

def refresh_access_token(creds, refresh_token):
    if not creds:
        return None
    data = urllib.parse.urlencode({
        "client_id": creds.get("client_id"),
        "client_secret": creds.get("client_secret", ""),
        "refresh_token": refresh_token,
        "grant_type": "refresh_token"
    }).encode("utf-8")
    
    req = urllib.request.Request(TOKEN_URI, data=data, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            new_tokens = json.loads(resp.read().decode("utf-8"))
            tokens = load_token() or {}
            tokens.update(new_tokens)
            tokens["expires_at"] = time.time() + new_tokens.get("expires_in", 3600) - 60
            save_token(tokens)
            return tokens.get("access_token")
    except Exception:
        return None

class OAuthHandler(BaseHTTPRequestHandler):
    auth_code = None
    captured_creds = None

    def do_GET(self):
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        
        # Scenario 1: Setup portal with redirect
        if "code" in params:
            OAuthHandler.auth_code = params["code"][0]
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<html><body style='font-family:sans-serif;background:#09090b;color:#4ade80;display:flex;align-items:center;justify-content:center;height:100vh;flex-direction:column;'><h2>Authentication Successful!</h2><p style='color:#a1a1aa;'>Google Calendar is now linked. You can close this tab and return to Flui.</p></body></html>")
        else:
            # Setup portal page allowing 1-click credential & auth initialization
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            html = """<!DOCTYPE html>
<html>
<head>
    <title>Flui Google Calendar Setup</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #09090b; color: #f4f4f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .card { background: #141416; border: 1px solid #27272a; border-radius: 14px; padding: 28px; width: 440px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
        h2 { margin-top: 0; font-size: 20px; color: #fff; }
        p { color: #a1a1aa; font-size: 13px; line-height: 1.5; }
        input { width: 100%; box-sizing: border-box; background: #1e1e22; border: 1px solid #27272a; border-radius: 8px; padding: 10px 12px; color: #f4f4f5; font-size: 13px; margin-bottom: 12px; }
        button { width: 100%; background: #e4e4e7; color: #09090b; border: none; border-radius: 8px; padding: 12px; font-weight: 600; cursor: pointer; font-size: 14px; margin-top: 8px; }
        button:hover { background: #ffffff; }
        .hint { font-size: 11px; color: #71717a; margin-top: 14px; }
        a { color: #4ade80; text-decoration: none; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Connect Google Calendar</h2>
        <p>Google requires an OAuth Client to identify desktop applications. Paste your Google Cloud Desktop Client credentials below:</p>
        <form method="POST" action="/save">
            <input type="text" name="client_id" placeholder="Your Client ID (.apps.googleusercontent.com)" required />
            <input type="password" name="client_secret" placeholder="Your Client Secret" required />
            <button type="submit">Continue to Google Login &rarr;</button>
        </form>
        <p class="hint">Need credentials? Create a free Desktop OAuth Client in <a href="https://console.cloud.google.com/apis/credentials" target="_blank">Google Cloud Console</a>.</p>
    </div>
</body>
</html>"""
            self.wfile.write(html.encode("utf-8"))

    def do_POST(self):
        if self.path == "/save":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            params = urllib.parse.parse_qs(body)
            cid = params.get("client_id", [""])[0].strip()
            csec = params.get("client_secret", [""])[0].strip()
            if cid:
                with open(CREDS_FILE, "w") as f:
                    json.dump({"client_id": cid, "client_secret": csec}, f, indent=2)
                # Redirect user directly to Google OAuth consent
                redirect_uri = "http://127.0.0.1:8765"
                auth_params = {
                    "client_id": cid,
                    "redirect_uri": redirect_uri,
                    "response_type": "code",
                    "scope": " ".join(SCOPES),
                    "access_type": "offline",
                    "prompt": "consent"
                }
                google_url = AUTH_URI + "?" + urllib.parse.urlencode(auth_params)
                self.send_response(302)
                self.send_header("Location", google_url)
                self.end_headers()
                return
        self.send_response(400)
        self.end_headers()

    def log_message(self, format, *args):
        pass

def perform_auth():
    creds = get_client_credentials()
    redirect_uri = "http://127.0.0.1:8765"

    server = HTTPServer(("127.0.0.1", 8765), OAuthHandler)

    if not creds:
        # Open local setup portal in browser
        webbrowser.open("http://127.0.0.1:8765")
        # Handle the setup POST request, which then redirects to Google
        server.handle_request()
    else:
        # Already have credentials, go straight to Google OAuth consent
        auth_params = {
            "client_id": creds["client_id"],
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(SCOPES),
            "access_type": "offline",
            "prompt": "consent"
        }
        url = AUTH_URI + "?" + urllib.parse.urlencode(auth_params)
        webbrowser.open(url)

    # Wait for the Google callback with code
    server.handle_request()

    if OAuthHandler.auth_code:
        active_creds = get_client_credentials()
        if not active_creds:
            print(json.dumps({"status": "failed", "message": "Credentials missing after callback."}))
            return

        token_data = urllib.parse.urlencode({
            "code": OAuthHandler.auth_code,
            "client_id": active_creds["client_id"],
            "client_secret": active_creds.get("client_secret", ""),
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code"
        }).encode("utf-8")

        req = urllib.request.Request(TOKEN_URI, data=token_data, method="POST")
        try:
            with urllib.request.urlopen(req) as resp:
                res = json.loads(resp.read().decode("utf-8"))
                res["expires_at"] = time.time() + res.get("expires_in", 3600) - 60
                save_token(res)
                print(json.dumps({"status": "authenticated"}))
        except Exception as e:
            print(json.dumps({"status": "error", "message": str(e)}))
    else:
        print(json.dumps({"status": "failed", "message": "No authorization code received."}))

def get_events():
    creds = get_client_credentials()
    tokens = load_token()

    if not tokens:
        print(json.dumps({"status": "unauthenticated", "events": []}))
        return

    access_token = tokens.get("access_token")
    if time.time() >= tokens.get("expires_at", 0):
        refresh_token = tokens.get("refresh_token")
        if refresh_token:
            access_token = refresh_access_token(creds, refresh_token)
        else:
            access_token = None

    if not access_token:
        print(json.dumps({"status": "unauthenticated", "events": []}))
        return

    now = datetime.now(timezone.utc)
    time_min = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
    time_max = (now + timedelta(days=7)).replace(hour=23, minute=59, second=59).isoformat()

    params = {
        "timeMin": time_min,
        "timeMax": time_max,
        "singleEvents": "true",
        "orderBy": "startTime",
        "maxResults": 20
    }

    url = CALENDAR_API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {access_token}"})

    try:
        with urllib.request.urlopen(req) as resp:
            raw = json.loads(resp.read().decode("utf-8"))
            items = raw.get("items", [])
            parsed_events = []
            for item in items:
                start = item.get("start", {})
                start_dt = start.get("dateTime", start.get("date", ""))
                
                time_str = "All Day"
                if "T" in start_dt:
                    try:
                        clean_dt = start_dt.split("+")[0].split("Z")[0]
                        dt_obj = datetime.fromisoformat(clean_dt)
                        time_str = dt_obj.strftime("%I:%M %p")
                    except Exception:
                        time_str = start_dt

                parsed_events.append({
                    "id": item.get("id", ""),
                    "summary": item.get("summary", "(No Title)"),
                    "start": start_dt,
                    "time": time_str,
                    "location": item.get("location", ""),
                    "htmlLink": item.get("htmlLink", "")
                })

            result = {
                "status": "ok",
                "last_sync": datetime.now().strftime("%I:%M %p"),
                "events": parsed_events
            }
            with open(CACHE_FILE, "w") as f:
                json.dump(result, f, indent=2)
            print(json.dumps(result))
    except Exception as e:
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r") as f:
                    cache_data = json.load(f)
                    cache_data["status"] = "cached"
                    print(json.dumps(cache_data))
                    return
            except Exception:
                pass
        print(json.dumps({"status": "error", "message": str(e), "events": []}))

def main():
    if len(sys.argv) < 2:
        get_events()
        return

    cmd = sys.argv[1]
    if cmd == "auth":
        perform_auth()
    elif cmd == "events":
        get_events()
    elif cmd == "status":
        tokens = load_token()
        authenticated = bool(tokens and (tokens.get("access_token") or tokens.get("refresh_token")))
        print(json.dumps({
            "authenticated": authenticated
        }))
    elif cmd == "logout":
        if os.path.exists(TOKEN_FILE):
            os.remove(TOKEN_FILE)
        if os.path.exists(CACHE_FILE):
            os.remove(CACHE_FILE)
        print(json.dumps({"status": "logged_out"}))
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)

if __name__ == "__main__":
    main()
