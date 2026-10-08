# NOMAD Box

[Project NOMAD](https://www.projectnomad.us) in a single Docker container for Windows, macOS, Raspberry Pi and Linux.

| System | CPU | RAM | Requires |
|---|---|---|---|
| Windows 10 or 11 | Intel, AMD, ARM | 16 GB | Docker Desktop, WSL2 |
| macOS 14 or later | Apple M1 to M4 | 16 GB | Docker Desktop |
| Raspberry Pi OS 64-bit | Raspberry Pi 5 | 8 GB | SSD |
| Ubuntu or Debian | Intel, AMD, ARM | 4 GB | — |

You need about 35 GB of free disk space and an internet connection for the first start. AI chat uses an LLM server you run yourself, such as [Ollama](https://ollama.com), LM Studio or llama.cpp; NOMAD itself only computes the search index, so it fits in 4 GB of RAM.

## Install

Before the first install:

- **macOS:** install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/), then run `xcode-select --install`.
- **Windows:** in PowerShell as administrator run `wsl --install -d Ubuntu` and restart. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and turn on **Settings > Resources > WSL integration > Ubuntu**. Run the command below in the **Ubuntu** app.
- **Raspberry Pi, Ubuntu, Debian:** nothing; Docker and the tools are installed for you.

Get the project folder (`git clone https://github.com/przemek890/NOMAD.git`, or copy it from another computer) and run in it:

```bash
bash install.sh
```

Once the repository is public, one command also downloads it to `~/nomad` on macOS or `/opt/nomad` elsewhere, and updates it when run again:

```bash
curl -fsSL https://raw.githubusercontent.com/przemek890/NOMAD/main/install.sh | bash
```

NOMAD starts again after a reboot. When the installer finishes, open **https://nomad.localhost** on macOS and Windows, or `http://DEVICE-ADDRESS:8080` from another device.

Chat uses an LLM server on the same machine at `http://localhost:11434`. For another one, run e.g. `NOMAD_LLM_URL=http://192.168.1.20:1234 bash install.sh`.

## Mini PC wired to a Mac

NOMAD runs on the mini PC, connected to the Mac with an Ethernet cable; the LLM server runs on the Mac.

1. On the Mac, turn on **System Settings > General > Sharing > Internet Sharing** from Wi-Fi to Ethernet. The mini PC gets internet through the Mac, and the Mac is always `192.168.2.1` for it.

2. Start the LLM server on the Mac so it accepts connections from the network (for Ollama: `OLLAMA_HOST=0.0.0.0`).

3. Copy the project folder to the mini PC (`data/` can come along to skip downloading the content again) and run in it:

   ```bash
   NOMAD_LLM_URL=http://192.168.2.1:11434 bash install.sh
   ```

4. On the Mac, open the address the installer prints at the end.

## Commands

Run them in the NOMAD folder:

| Command | What it does |
|---|---|
| `make` | builds if needed and starts everything |
| `make logs` | download and indexing progress |
| `make down` | stops NOMAD (data stays in `data/`) |
| `make preload` | installs content after you change `content/` |
| `make help` | all other commands |

Edit `content/sources.txt` to choose what gets downloaded, and put your own documents for the AI assistant in `content/knowledge/`.
