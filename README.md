# NOMAD Box

[Project NOMAD](https://www.projectnomad.us) w jednym kontenerze Docker dla Windowsa, macOS i Raspberry Pi.

| System | Procesor | RAM | Wymagane |
|---|---|---|---|
| Windows 10 lub 11 | Intel, AMD, ARM | 16 GB | Docker Desktop, WSL2 |
| macOS 14 lub nowszy | Apple M1 do M4 | 16 GB | Docker Desktop |
| Raspberry Pi OS 64-bit | Raspberry Pi 5 | 8 GB | Docker, dysk SSD |

Potrzebne jest około 30 GB wolnego miejsca i internet przy pierwszym uruchomieniu.

## Instalacja na Macu

1. Zainstaluj [Docker Desktop](https://www.docker.com/products/docker-desktop/) i uruchom go.

2. Zainstaluj narzędzia deweloperskie:

   ```bash
   xcode-select --install
   ```

3. Pobierz projekt:

   ```bash
   git clone https://github.com/przemek890/NOMAD.git
   cd NOMAD
   ```

4. Uruchom NOMAD (przy pierwszym uruchomieniu Mac poprosi o hasło, żeby zaufać certyfikatowi HTTPS):

   ```bash
   make
   ```

5. Otwórz **https://nomad.localhost**.

6. Do czatu AI zainstaluj [Ollamę](https://ollama.com) i pobierz model:

   ```bash
   ollama pull gemma3:1b
   ```

## Instalacja na Windowsie

1. W PowerShell jako administrator zainstaluj Ubuntu w WSL2 i uruchom komputer ponownie:

   ```powershell
   wsl --install -d Ubuntu
   ```

2. Zainstaluj [Docker Desktop](https://www.docker.com/products/docker-desktop/). W **Settings > Resources > WSL integration** włącz **Ubuntu**.

3. W aplikacji **Ubuntu** zainstaluj narzędzia:

   ```bash
   sudo apt update && sudo apt install -y git make
   ```

4. Wykonaj kroki 3–6 z instrukcji dla Maca w oknie Ubuntu.

## Instalacja na Raspberry Pi 5

1. Nagraj **Raspberry Pi OS 64-bit** programem [Raspberry Pi Imager](https://www.raspberrypi.com/software/).

2. Zainstaluj Dockera i narzędzia:

   ```bash
   sudo apt update && sudo apt install -y git make
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker "$USER"
   ```

3. Ustaw jądro wymagane przez bazę danych i uruchom Pi ponownie:

   ```bash
   echo "kernel=kernel8.img" | sudo tee -a /boot/firmware/config.txt
   sudo reboot
   ```

4. Wykonaj kroki 3–6 z instrukcji dla Maca.

Z innego urządzenia w sieci: `http://ADRES-PI:8080`.

## Polecenia

| Polecenie | Co robi |
|---|---|
| `make` | buduje (jeśli trzeba) i uruchamia wszystko |
| `make logs` | postęp pobierania i indeksowania |
| `make down` | zatrzymuje (dane zostają w `data/`) |
| `make preload` | instaluje treści po zmianie `content/` |
| `make help` | pozostałe polecenia |

Co ma się pobrać, zmieniasz w `content/sources.txt`, a własne dokumenty dla asystenta AI wrzucasz do `content/knowledge/`.
