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

The AI model runs on your computer (macOS, Windows or Linux, [Ollama](https://ollama.com)).
NOMAD runs on a mini PC connected to your computer **only with an Ethernet cable** (no router).
Your computer becomes `10.77.0.1` on the cable, gives the mini PC an address and shares its internet.
You use NOMAD in the browser on your computer: **http://nomad.local:8080**.

### First time

1. Install [Ollama](https://ollama.com) on your computer and download a chat model and the embedding model
   (the mini PC then needs no AI of its own, which saves ~3 GB of disk and RAM):

   ```bash
   ollama pull qwen3:8b
   ollama pull nomic-embed-text:v1.5
   ```

   macOS and Linux also need [Caddy](https://caddyserver.com/docs/install) (`brew install caddy`).
   Settings for your computer go in `network/local.env` (copy `network/local.env.example`), e.g. the
   command that starts Ollama, so `start` can bring it up after a restart.
2. Connect the mini PC to your computer with an Ethernet cable.
3. Start everything on your computer:
   - **macOS / Linux:** in Terminal, in the project folder: `network/start.sh` (asks for your password)
   - **Windows:** double-click `network\start.cmd` and confirm the Administrator prompt.
     Windows shares an existing internet connection, so connect to Wi-Fi first.
4. Install NOMAD on the mini PC: copy the project folder there and run in it
   (a Windows mini PC: in the **Ubuntu** app, see Install):

   ```bash
   NOMAD_LLM_URL=http://10.77.0.1:11434 NOMAD_EMBED_URL=http://10.77.0.1:11434 bash install.sh
   ```

5. Open **http://nomad.local:8080** in the browser on your computer.
   If the name does not work, use the mini PC address shown by `start` (e.g. `http://10.77.0.11:8080`).

### Every day

| What happened | What to do |
|---|---|
| Your computer was restarted | macOS / Linux: `network/start.sh`, Windows: double-click `network\start.cmd` |
| The mini PC was restarted | nothing, NOMAD starts by itself in a few minutes |
| You want to use NOMAD | open http://nomad.local:8080 |

Keep your computer on (not asleep) while you use NOMAD: the mini PC uses its model and internet.
Wikipedia, maps and the other content work without internet.

### Single steps

| | macOS / Linux | Windows |
|---|---|---|
| everything (model, network, bridge) | `network/start.sh` | `network\start.cmd` |
| cable network only | `sudo network/link.sh up` | `network\link.cmd up` |
| model for the mini PC only | `network/llm-bridge.sh start` | `network\link.cmd bridge-start` |
| status, mini PC address | `network/link.sh status` | `network\link.cmd status` |
| undo | `network/llm-bridge.sh stop`, `sudo network/link.sh down` | `network\link.cmd bridge-stop`, `network\link.cmd down` |

The model stays reachable only on the cable. On macOS and Linux the bridge passes only the chat
endpoints (no downloading or deleting models); on Windows it forwards the whole Ollama API.

### A small mini PC (e.g. HP t630, 4 GB RAM)

Use Debian without a desktop instead of Windows: Docker runs natively and ~3 GB of RAM stays free.
`minipc/preseed.cfg` installs Debian 13 unattended (it **erases the whole disk**). After the install run
`sudo minipc/tune.sh` on the mini PC: compressed RAM swap (zram), the name `nomad.local`
and no "ACPI BIOS Error" messages on the screen of HP thin clients.

## Knowledge Search

**http://localhost:8070** (from another device: `http://<NOMAD machine>:8070`, also a tile on the dashboard)
finds the passages of the AI knowledge base closest in meaning to a question. It runs on the NOMAD
machine itself with the same embedding model NOMAD indexes with, so it works when the AI chat model
is off or the computer running it is away. Most indexed sources are English: ask in English.

The note **Downloaded content** in Notes lists what is downloaded and what the AI assistant can search.

## Everyday use

| Command | What it does |
|---|---|
| `make` | starts NOMAD |
| `make down` | stops NOMAD |
| `make logs` | shows what is happening |
| `make refresh` | applies changed `box/` scripts after `git pull` without a full rebuild |

What gets downloaded is listed in `content/sources.txt`. Put your own documents for the AI assistant in `content/knowledge/`.
