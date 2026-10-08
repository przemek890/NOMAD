# NOMAD Box

[Project NOMAD](https://www.projectnomad.us) in a single Docker container for Windows, macOS and Raspberry Pi.

| System | CPU | RAM | Requires |
|---|---|---|---|
| Windows 10 or 11 | Intel, AMD, ARM | 16 GB | Docker Desktop, WSL2 |
| macOS 14 or later | Apple M1 to M4 | 16 GB | Docker Desktop |
| Raspberry Pi OS 64-bit | Raspberry Pi 5 | 8 GB | Docker, SSD |

You need about 30 GB of free disk space and an internet connection for the first start.

## Install on macOS

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and start it.

2. Install the developer tools:

   ```bash
   xcode-select --install
   ```

3. Get the project:

   ```bash
   git clone https://github.com/przemek890/NOMAD.git
   cd NOMAD
   ```

4. Start NOMAD (on the first run macOS asks for your password to trust the HTTPS certificate):

   ```bash
   make
   ```

5. Open **https://nomad.localhost**.

6. For AI chat, install [Ollama](https://ollama.com) and pull a model:

   ```bash
   ollama pull gemma3:1b
   ```

## Install on Windows

1. In PowerShell as administrator, install Ubuntu on WSL2 and restart the computer:

   ```powershell
   wsl --install -d Ubuntu
   ```

2. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/). In **Settings > Resources > WSL integration**, turn on **Ubuntu**.

3. In the **Ubuntu** app, install the tools:

   ```bash
   sudo apt update && sudo apt install -y git make
   ```

4. Follow steps 3–6 of the macOS instructions in the Ubuntu window.

## Install on Raspberry Pi 5

1. Flash **Raspberry Pi OS 64-bit** with [Raspberry Pi Imager](https://www.raspberrypi.com/software/).

2. Install Docker and the tools:

   ```bash
   sudo apt update && sudo apt install -y git make
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker "$USER"
   ```

3. Switch to the kernel the database needs and reboot:

   ```bash
   echo "kernel=kernel8.img" | sudo tee -a /boot/firmware/config.txt
   sudo reboot
   ```

4. Follow steps 3–6 of the macOS instructions.

From another device on the network: `http://PI-ADDRESS:8080`.

## Commands

| Command | What it does |
|---|---|
| `make` | builds if needed and starts everything |
| `make logs` | download and indexing progress |
| `make down` | stops NOMAD (data stays in `data/`) |
| `make preload` | installs content after you change `content/` |
| `make help` | all other commands |

Edit `content/sources.txt` to choose what gets downloaded, and put your own documents for the AI assistant in `content/knowledge/`.
