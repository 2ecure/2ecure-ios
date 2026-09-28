"""Download the 2ecure App Store provisioning profiles via the App Store Connect API and install them.
Env: ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID. Profiles are created/renewed by the orchestrator (not by CI)."""
import json, time, base64, subprocess, urllib.request, urllib.parse, os, plistlib, pathlib
NAMES = ["2ecure App Store", "2ecure NSE App Store", "2ecure Share App Store"]
key, kid, iss = os.environ["ASC_KEY_PATH"], os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"]
b64 = lambda b: base64.urlsafe_b64encode(b).rstrip(b"=").decode()
h = b64(json.dumps({"alg": "ES256", "kid": kid, "typ": "JWT"}).encode())
p = b64(json.dumps({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 600, "aud": "appstoreconnect-v1"}).encode())
der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key], input=(h + "." + p).encode(), capture_output=True, check=True).stdout
i = 2 + (1 if der[1] & 0x80 else 0); rl = der[i + 1]; r = der[i + 2:i + 2 + rl]; i += 2 + rl; sl = der[i + 1]; s = der[i + 2:i + 2 + sl]
tok = h + "." + p + "." + b64(r.lstrip(b"\0").rjust(32, b"\0") + s.lstrip(b"\0").rjust(32, b"\0"))
dirs = [pathlib.Path.home() / "Library/MobileDevice/Provisioning Profiles",
        pathlib.Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"]
for d in dirs: d.mkdir(parents=True, exist_ok=True)
for name in NAMES:
    url = "https://api.appstoreconnect.apple.com/v1/profiles?" + urllib.parse.urlencode({"filter[name]": name, "limit": 5})
    data = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"Authorization": "Bearer " + tok}), timeout=30))["data"]
    active = [x for x in data if x["attributes"]["name"] == name and x["attributes"]["profileState"] == "ACTIVE"]
    if not active: raise SystemExit("no ACTIVE profile named %r" % name)
    a = active[0]["attributes"]; content = base64.b64decode(a["profileContent"])
    for d in dirs: (d / (a["uuid"] + ".mobileprovision")).write_bytes(content)
    print("installed %-24s uuid %s expires %s" % (name, a["uuid"], a["expirationDate"][:10]))
