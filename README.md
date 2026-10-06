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

4. Zbuduj i uruchom NOMAD. Pierwsze uruchomienie buduje obrazy (kilka minut), a potem w tle instaluje usługi i pobiera treści z `content/`:

   ```bash
   make
   ```

5. Pozwól przeglądarce ufać lokalnemu certyfikatowi. Mac poprosi o hasło:

   ```bash
   make trust
   ```

6. Otwórz w przeglądarce **https://nomad.localhost**. Postęp pobierania pokaże `make logs`.

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

4. Wykonaj kroki od 3 do 6 z instrukcji dla Maca w oknie Ubuntu. `make trust` poprosi w okienku Windows o zgodę administratora.

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

4. Wykonaj kroki od 3 do 6 z instrukcji dla Maca. Budowa na Pi może potrwać znacznie dłużej.

Zamiast budować na Pi, możesz zbudować obraz na Macu i przenieść go plikiem: `make build export` na Macu, skopiuj projekt razem z `dist/nomad-box.tar.gz` na Pi i uruchom tam `make import` oraz `make`. Na komputerze z procesorem Intel lub AMD buduj poleceniem `PLATFORM=linux/arm64 make build export`.

Z innego urządzenia w tej samej sieci otwórz `http://ADRES-PI:8080`. Adres Pi pokaże polecenie `hostname -I`.

## Treści

Lista treści jest częścią repozytorium. Przy każdym starcie NOMAD instaluje to, czego jeszcze nie ma, a pobrane rzeczy pomija:

| Plik | Co zawiera |
|---|---|
| `content/sources.txt` | usługi, pliki ZIM (Wikipedia, poradniki), mapy krajów, model do embeddingów i lista ZIM-ów indeksowanych dla AI |
| `content/knowledge/` | Twoje dokumenty (PDF, DOCX, EPUB, TXT, MD, obrazy), które trafiają do bazy wiedzy asystenta AI |

Domyślnie to około 20 GB: polska Wikipedia bez obrazków (8 GB), kolekcje NOMAD *Medicine – Comprehensive* (7 GB), *DIY – Standard* (2,3 GB) i *Agriculture – Essential* oraz mapa Polski (3 GB). Pliki ZIM wyszukasz w [katalogu Kiwix](https://library.kiwix.org); adres bez daty, np. `https://download.kiwix.org/zim/wikipedia/wikipedia_pl_all_nopic`, oznacza zawsze najnowszą wersję. Po zmianie listy uruchom `make preload` albo `make restart`.

Pobrane treści są w `data/` i nie trafiają do repozytorium. Aby przenieść NOMAD razem z treściami bez ponownego pobierania, skopiuj cały katalog `data/` albo trzymaj go na dysku zewnętrznym, ustawiając `NOMAD_DATA_DIR` w `.env`. Pliki ZIM wrzucone ręcznie do `data/storage/zim/` są dodawane do biblioteki przy następnym starcie.

Pobieranie trwa w tle; przed odłączeniem internetu sprawdź w panelu, czy się zakończyło.

## Asystent AI

Do czatu NOMAD korzysta z Ollamy uruchomionej na tym samym komputerze pod adresem z `NOMAD_OLLAMA_URL` w `.env` (domyślnie `http://localhost:11434`). Zainstaluj ją z [ollama.com](https://ollama.com), pobierz model do czatu, np. `ollama pull gemma3:1b` (ok. 1,5 GB RAM, wystarczy komputer z 4 GB RAM) albo większy `llama3.2:3b`, i uruchom ją przed `make`. Na Macu Ollama poza kontenerem korzysta z GPU, więc odpowiada kilka razy szybciej. Gdy pod tym adresem nic nie odpowiada, NOMAD sam instaluje Ollamę w kontenerze; model do czatu pobierzesz wtedy w panelu: Settings → AI Assistant.

Ollama na innym komputerze: ustaw jego adres, np. `NOMAD_OLLAMA_URL=http://192.168.1.20:11434`, a na tamtym komputerze uruchom Ollamę z `OLLAMA_HOST=0.0.0.0`. Na Linuksie i Raspberry Pi `OLLAMA_HOST=0.0.0.0` jest potrzebne także dla Ollamy na tym samym komputerze.

### Baza wiedzy

Asystent odpowiada na podstawie plików zindeksowanych modelem `nomic-embed-text`, który pobiera się automatycznie. Indeksowane są tylko dokumenty z `content/knowledge/` oraz pliki ZIM z liniami `embed` w `content/sources.txt`; domyślnie to kilka małych zbiorów medycznych. NOMAD sam zindeksowałby każdy pobrany ZIM, ale na procesorze bez GPU liczy około 3 fragmentów na sekundę, więc polska Wikipedia zajęłaby kilka dni. Dlatego `make` wyłącza indeksowanie automatyczne. Pliki z listy `embed`, które jeszcze się pobierają, zostaną zindeksowane po pobraniu. Postęp widać w czacie pod przyciskiem Knowledge Base, gdzie możesz też ręcznie zindeksować dowolny plik.

## Dane i sieć

Dane aplikacji są w `data/`, a obrazy wewnętrznego Dockera w wolumenie `nomad-engine`. `make down` zatrzymuje usługi i zachowuje dane. `make clean` usuwa wolumen silnika; przy następnym starcie obrazy zostaną ponownie wczytane.

Aby działać bez HTTPS (tylko `http://localhost:8080`), usuń z `.env` linie `COMPOSE_PROFILES` i `NOMAD_DOMAIN`. Pozostałe ustawienia i ich wartości domyślne są opisane w `.env.example`.

Domyślna konfiguracja udostępnia port 8080, porty aplikacji oraz zakres 8400–8500 wszystkim urządzeniom w sieci. Używaj jej w zaufanej sieci; przed udostępnieniem komputera w innej sieci ogranicz porty w `compose.yaml`.

## Adresy

| Adres | Co tam jest |
|---|---|
| https://nomad.localhost | panel główny |
| https://nomad.localhost/chat | asystent AI |
| https://wiki.nomad.localhost | Wikipedia i poradniki |
| https://notes.nomad.localhost | notatki |

Telefon lub inny komputer w tej samej sieci: `http://ADRES-KOMPUTERA:8080`.

Chrome i Firefox same rozpoznają adresy `*.nomad.localhost`. W Safari i na innych urządzeniach dopisz do `/etc/hosts` linię wypisaną przez `make hosts` (dla innych urządzeń: `make hosts IP=ADRES-KOMPUTERA`) i zaufaj certyfikatowi z `make ca`.

## Aktualizacja

Przycisk **Start Update** w panelu nie działa w NOMAD Box, bo obrazy są budowane ze źródeł. Aby zaktualizować, zmień `NOMAD_REF` w `docker-bake.hcl` na nową wersję z [listy wydań](https://github.com/Crosstalk-Solutions/project-nomad/releases) i uruchom `make build restart`. Dane zostają.
