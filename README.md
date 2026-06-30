# Bully Online Server

A Dockerized hosting setup for **Bully Online**, a multiplayer mod for Bully: Scholarship Edition (PC) built on [derpy's script server (DSS)](https://www.nexusmods.com/bully/mods/). Created by [Fat Pigeon Development](https://www.nexusmods.com/bully).

> This project is not affiliated with or endorsed by Rockstar Games / Take-Two Interactive.

---

## Prerequisites for Users

- A copy of Bully: Scholarship Edition (PC) with [derpy's script loader (DSL)](https://www.nexusmods.com/bully) installed (for connecting as a player)

---

## Configuration

Edit `dslconfig.ini` before building. The key settings to change:

```ini
server_name: My Server        # Name shown to players
server_info: Description here # Short description
server_players: 16            # Max player count
read_eula: true               # Must be true — see eula.txt
```

For a full breakdown of all options see `manual.pdf`.

---

## Running the Server

**Build and start:**
```powershell
docker compose up --build
```

**Run in the background:**
```powershell
docker compose up --build -d
```

**Stop the server:**
```powershell
docker compose down
```

The server listens on port **17017** (TCP) by default. Make sure this port is open in your firewall. If you're using a VPS, no port forwarding is needed.

---

## Updating Configuration

`dslconfig.ini` is mounted from the host. Edit it and restart — no rebuild needed:

```powershell
# Edit dslconfig.ini, then:
docker compose restart
```

## Updating Scripts

Scripts are baked into the image, so changes require a rebuild:

```powershell
docker compose up --build -d
```

---

## Accessing the Server Console

Attach to the running container to type server commands:
```powershell
docker attach bully-online
```

Detach without stopping the server with **Ctrl+P, Ctrl+Q**.

Useful console commands:
| Command | Description |
|---|---|
| `/help` | List all available commands |
| `/players` | List connected players |
| `/kick <name>` | Kick a player |
| `/account` | Manage player accounts |
| `/quit restart` | Restart the server |

---

## Connecting as a Player

Launch Bully with DSL installed and pass these launch options:

```
--joinServerASAP <your-server-ip> --username YourName
```

**Steam:** Right-click Bully → Properties → Launch Options  
**Rockstar Games Launcher:** Settings → Bully → Launch Arguments  
**CD version:** Pass directly to `Bully.exe`

See `BullyOnlineR4.pdf` for a full illustrated guide.

---

## Enabling Accounts (Optional)

Accounts require an SSL certificate and a domain name pointed at your server. To enable:

1. Obtain an SSL certificate (recommended: [acme.sh](https://github.com/acmesh-official/acme.sh) on Linux)
2. Uncomment and fill in `ssl_key` + `ssl_chain`/`ssl_cert` in `dslconfig.ini`
3. Uncomment `signup_ip` and `signup_port` to enable the registration API
4. Rebuild the image

See `manual.pdf` for the full account setup guide including nginx proxy configuration.

---

## Project Structure

```
.
├── Dockerfile
├── docker-compose.yaml
├── dslconfig.ini          # Server configuration
├── eula.txt               # DSS end user license agreement
├── credits.html           # DSL/DSS third-party library credits
├── derpy_script_server    # DSS Linux binary
├── derpy_script_server.exe# DSS Windows binary (not used by Docker)
├── scripts/               # Bully Online mod scripts
├── BullyOnlineR4.pdf      # Player & hosting guide
└── manual.pdf             # DSS manual
```
