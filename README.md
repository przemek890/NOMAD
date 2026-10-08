# NOMAD Box

[Project NOMAD](https://www.projectnomad.us) in a single Docker container for Windows, macOS, Raspberry Pi and Linux.

| System | CPU | RAM | Requires |
|---|---|---|---|
| Windows 10 or 11 | Intel, AMD, ARM | 16 GB | Docker Desktop, WSL2 |
| macOS 14 or later | Apple M1 to M4 | 16 GB | Docker Desktop |
| Raspberry Pi OS 64-bit | Raspberry Pi 5 | 8 GB | Docker, SSD |
| Linux mini PC | Intel, AMD, ARM | 4 GB | Docker, Ollama on a Mac in the same network |

You need about 35 GB of free disk space and an internet connection for the first start. AI chat runs in [Ollama](https://ollama.com) on the Mac; NOMAD itself only computes the search index, so it fits in 4 GB of RAM.

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

6. For AI chat, install and start [Ollama](https://ollama.com) (before `make`, or run `make preload` afterwards). NOMAD downloads the `gemma3:4b` model into it and makes it the default.

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

## Install on a Linux mini PC with Ollama on a Mac

1. On the Mac, install and start [Ollama](https://ollama.com), and let it accept connections from the network:

   ```bash
   launchctl setenv OLLAMA_HOST 0.0.0.0
   ```

   Quit and reopen Ollama. Note the Mac's IP address on the Ethernet link (**System Settings > Network > Ethernet**).

2. On the mini PC (Ubuntu or Debian, Intel/AMD or ARM), install Docker and the tools, then log out and back in:

   ```bash
   sudo apt update && sudo apt install -y git make
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker "$USER"
   ```

3. Get the project and point NOMAD at the Mac's Ollama (plain HTTP, no certificate needed):

   ```bash
   git clone https://github.com/przemek890/NOMAD.git
   cd NOMAD
   echo "NOMAD_OLLAMA_URL=http://MAC-ADDRESS:11434" > .env
   ```

4. Start NOMAD. The first run builds the image on the mini PC, which takes a while:

   ```bash
   make
   ```

5. On the Mac, open `http://MINI-PC-ADDRESS:8080`.
