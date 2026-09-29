# NOMAD Box

## Czym jest

[Project NOMAD](https://www.projectnomad.us) to serwer wiedzy, który może działać bez internetu po pobraniu wybranych usług, modeli i treści. Ten projekt pakuje go do kontenera Docker i dodaje skrypty instalacyjne dla Windowsa, macOS i Raspberry Pi.

| System | Procesor | RAM | Wymagane |
|---|---|---|---|
| Windows 10 lub 11 | Intel, AMD, ARM | 16 GB | Docker Desktop, WSL2 |
| macOS 14 lub nowszy | Apple M1 do M4 | 16 GB | Docker Desktop |
| Raspberry Pi OS 64-bit | Raspberry Pi 5 | 8 GB | Docker, dysk SSD |

Przygotuj około 30 GB wolnego miejsca i połączenie z internetem na czas budowy oraz pobierania treści. Rzeczywiste zużycie dysku i pamięci zależy od wybranych modeli i materiałów. Na Raspberry Pi z 8 GB uruchamiaj tylko usługi, których potrzebujesz.

## Instalacja na Macu

1. Zainstaluj [Docker Desktop](https://www.docker.com/products/docker-desktop/) i uruchom go. W **Settings > Resources** ustaw **Memory** na 10 GB.

2. Otwórz Terminal i zainstaluj narzędzia deweloperskie:

   ```bash
   xcode-select --install
   ```

3. Pobierz projekt:

   ```bash
   git clone https://github.com/przemek890/NOMAD.git
   cd NOMAD
   ```

4. Zbuduj NOMAD:

   ```bash
   make build
   ```

5. Uruchom:

   ```bash
   make up
   ```

6. Pozwól przeglądarce ufać lokalnemu certyfikatowi. Mac poprosi o hasło:

   ```bash
   make trust
   ```

7. Otwórz w przeglądarce **https://nomad.localhost**.

## Instalacja na Windowsie

1. W PowerShell uruchomionym jako administrator zainstaluj Ubuntu w WSL2 i uruchom komputer ponownie:

   ```powershell
   wsl --install -d Ubuntu
   ```

2. Zainstaluj [Docker Desktop](https://www.docker.com/products/docker-desktop/). W **Settings > Resources > WSL integration** włącz **Ubuntu**.

3. Otwórz aplikację **Ubuntu** i zainstaluj narzędzia:

   ```bash
   sudo apt update && sudo apt install -y git make
   ```

4. Wykonaj kroki od 3 do 7 z instrukcji dla Maca w oknie Ubuntu. `make trust` poprosi w okienku Windows o zgodę administratora.

## Instalacja na Raspberry Pi 5

1. Nagraj **Raspberry Pi OS 64-bit** programem [Raspberry Pi Imager](https://www.raspberrypi.com/software/) i uruchom Pi.

2. Zainstaluj Dockera i narzędzia:

   ```bash
   sudo apt update && sudo apt install -y git make
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker "$USER"
   ```

3. Przełącz ustawienie pamięci wymagane przez bazę danych i uruchom Pi ponownie:

   ```bash
   echo "kernel=kernel8.img" | sudo tee -a /boot/firmware/config.txt
   sudo reboot
   ```

4. Wykonaj kroki od 3 do 7 z instrukcji dla Maca. Budowa na Pi może potrwać znacznie dłużej.

Z innego urządzenia w tej samej sieci otwórz `http://ADRES-PI:8080`. Adres Pi pokaże polecenie `hostname -I`.

## Przygotowanie treści

Z włączonym internetem zainstaluj zestaw startowy: serwer Kiwix, asystenta AI z modelami, notatki i CyberChef:

```bash
make preload
```

`make preload` nie pobiera domyślnie Wikipedii ani innych plików ZIM. Dodaj je w panelu przez **Easy Setup** lub ustaw `NOMAD_PRELOAD_ZIMS` w `.env` przed uruchomieniem polecenia. Pobieranie ZIM odbywa się w tle; sprawdź jego zakończenie w panelu, zanim odłączysz internet. Podobnie pobierz potrzebne mapy i poradniki.

## Dane i sieć

Dane aplikacji są w `data/`, a obrazy wewnętrznego Dockera w wolumenie `nomad-engine`. `make down` zatrzymuje usługi i zachowuje dane. `make clean` usuwa wolumen silnika; przy następnym starcie obrazy zostaną ponownie wczytane.

Domyślna konfiguracja udostępnia port 8080, porty aplikacji oraz zakres 8400–8500 wszystkim urządzeniom w sieci. Używaj jej w zaufanej sieci; przed udostępnieniem komputera w innej sieci ogranicz porty w `compose.yaml`.

## Adresy

| Adres | Co tam jest |
|---|---|
| https://nomad.localhost | panel główny |
| https://nomad.localhost/chat | asystent AI |
| https://wiki.nomad.localhost | Wikipedia i poradniki |
| https://notes.nomad.localhost | notatki |

Telefon lub inny komputer w tej samej sieci: `http://ADRES-KOMPUTERA:8080`.
