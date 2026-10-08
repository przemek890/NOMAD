# NOMAD Box

Offline encyclopedia, maps and AI assistant ([Project NOMAD](https://www.projectnomad.us)) that runs on your own computer.

**You need:** macOS, Windows or Linux (also a mini PC or Raspberry Pi 5), 4 GB RAM, 30 GB of free disk space and internet for the first start.

## Install

1. **macOS or Windows:** install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   On Windows, also run `wsl --install -d Ubuntu` in PowerShell and do the next steps in the **Ubuntu** app.

2. Download this project (**Code > Download ZIP**, then unzip) and open a terminal in its folder.

3. Run:

   ```bash
   bash install.sh
   ```

4. Open the address shown at the end, e.g. **http://localhost:8080**.

## AI chat on your computer, NOMAD on a mini PC

The model runs on your computer (Ollama on `127.0.0.1:11434`), NOMAD runs on a mini PC connected
to it with an Ethernet cable only. Your computer is `10.77.0.1` on the cable, gives the mini PC
an address (DHCP) and shares its internet connection.

1. Connect the mini PC with an Ethernet cable (the mini PC uses DHCP, the default).
2. Set up the cable network and make Ollama reachable on the cable only:

   | | macOS / Linux (Terminal) | Windows (Command Prompt or PowerShell) |
   |---|---|---|
   | network | `sudo network/link.sh up` | `network\link.cmd up` |
   | model | `network/llm-bridge.sh start` | `network\link.cmd bridge-start` |
   | mini PC address | `network/link.sh status` | `network\link.cmd status` |
   | undo | `network/llm-bridge.sh stop`, `sudo network/link.sh down` | `network\link.cmd bridge-stop`, `network\link.cmd down` |

   On Windows confirm the Administrator prompt; the result shows in the new window. Windows shares
   an existing internet connection (e.g. Wi-Fi), so connect to one first.
   On macOS run both again after every restart. `llm-bridge.sh` needs [Caddy](https://caddyserver.com/docs/install).

3. Copy the project folder to the mini PC and run in it (a Windows mini PC: in the **Ubuntu** app, see Install):

   ```bash
   NOMAD_LLM_URL=http://10.77.0.1:11434 bash install.sh
   ```

4. Open `http://<mini PC address>:8080`.

## Everyday use

| Command | What it does |
|---|---|
| `make` | starts NOMAD |
| `make down` | stops NOMAD |
| `make logs` | shows what is happening |

What gets downloaded is listed in `content/sources.txt`. Put your own documents for the AI assistant in `content/knowledge/`.
