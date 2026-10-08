# NOMAD Box

Offline encyclopedia, maps and AI assistant ([Project NOMAD](https://www.projectnomad.us)) that runs on your own computer.

**You need:** macOS, Windows or Linux (also a mini PC or Raspberry Pi 5), 4 GB RAM, 40 GB of free disk space and internet for the first start.

## Install

1. **macOS or Windows:** install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   On Windows, also run `wsl --install -d Ubuntu` in PowerShell and do the next steps in the **Ubuntu** app.

2. Download this project (**Code > Download ZIP**, then unzip) and open a terminal in its folder.

3. Run:

   ```bash
   bash install.sh
   ```

4. Open the address shown at the end, e.g. **http://localhost:8080**.

## AI chat on a Mac, NOMAD on a mini PC

1. Connect the mini PC to the Mac with an Ethernet cable.
2. On the Mac, turn on **System Settings > General > Sharing > Internet Sharing** (from Wi-Fi to Ethernet).
3. On the Mac, start [Ollama](https://ollama.com) so the mini PC can reach it:

   ```bash
   OLLAMA_HOST=0.0.0.0 ollama serve
   ```

4. Copy the project folder to the mini PC and run in it:

   ```bash
   NOMAD_LLM_URL=http://192.168.2.1:11434 bash install.sh
   ```

5. On the Mac, open the address shown at the end.

## Everyday use

| Command | What it does |
|---|---|
| `make` | starts NOMAD |
| `make down` | stops NOMAD |
| `make logs` | shows what is happening |

What gets downloaded is listed in `content/sources.txt`. Put your own documents for the AI assistant in `content/knowledge/`.
