# NOMAD Box

Encyklopedia, mapy i asystent AI działające bez internetu ([Project NOMAD](https://www.projectnomad.us)), na Twoim komputerze.

**Potrzebujesz:** macOS, Windows lub Linux (także mini PC albo Raspberry Pi 5), 4 GB RAM, 30 GB wolnego miejsca, internet przy pierwszym uruchomieniu.

## Instalacja na jednym komputerze

1. **macOS lub Windows:** zainstaluj i uruchom [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   Na Windows dodatkowo wpisz w PowerShell `wsl --install -d Ubuntu`, a dalsze kroki rób w aplikacji **Ubuntu**.
2. Pobierz projekt (**Code > Download ZIP**, rozpakuj) i otwórz terminal w jego folderze.
3. Wpisz:

   ```bash
   bash install.sh
   ```

4. Otwórz adres podany na końcu, np. **http://localhost:8080**.

## Model AI na komputerze, NOMAD na mini PC

Model AI działa na Twoim komputerze (macOS, Windows lub Linux), a NOMAD na mini PC połączonym z nim **tylko kablem Ethernet** (bez routera).
Komputer dostaje na kablu adres `10.77.0.1`, nadaje adres mini PC i udostępnia mu internet.
NOMAD otwierasz w przeglądarce na komputerze: **http://nomad.local:8080**.

### Pierwszy raz

1. **Na komputerze** zainstaluj [Ollama](https://ollama.com) i pobierz model do czatu oraz model do wyszukiwania:

   ```bash
   ollama pull qwen3:8b
   ollama pull nomic-embed-text:v1.5
   ```

   macOS: zainstaluj też Caddy: `brew install caddy` ([Homebrew](https://brew.sh)). Linux: `sudo apt install caddy`.
2. Połącz mini PC z komputerem kablem Ethernet.
3. **Na komputerze** uruchom sieć i udostępnij model:
   - **macOS / Linux:** w Terminalu, w folderze projektu: `network/start.sh` (zapyta o hasło do komputera)
   - **Windows:** połącz się z Wi‑Fi, kliknij dwa razy `network\start.cmd` i potwierdź okno administratora

   Na końcu zobaczysz adres mini PC, np. `10.77.0.11`.
4. **Na mini PC** (Linux, np. Debian) wpisz:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/przemek890/NOMAD/main/install.sh | NOMAD_LLM_URL=http://10.77.0.1:11434 NOMAD_EMBED_URL=http://10.77.0.1:11434 bash
   ```

5. **Na komputerze** otwórz **http://nomad.local:8080** (albo `http://<adres mini PC>:8080`).

### Na co dzień

| Sytuacja | Co zrobić |
|---|---|
| Uruchomiłeś ponownie komputer | macOS / Linux: `network/start.sh`, Windows: dwuklik w `network\start.cmd` |
| Uruchomiłeś ponownie mini PC | nic, NOMAD wstaje sam po kilku minutach |
| Chcesz używać NOMAD | otwórz http://nomad.local:8080 |
| Chcesz sprawdzić, czy wszystko działa | `tests/smoke.sh nomad.local` |

Do czatu AI komputer musi być włączony i nieuśpiony. Wikipedia, mapy, notatki i wyszukiwarka wiedzy działają bez niego.

### Mały mini PC (np. HP t630, 4 GB RAM)

Zainstaluj Debiana 13 bez pulpitu zamiast Windowsa: zostaje ok. 3 GB wolnego RAM.
`minipc/preseed.cfg` instaluje go automatycznie (**kasuje cały dysk**). Po instalacji wpisz na mini PC `sudo minipc/tune.sh`.

### Pojedyncze kroki (dla zaawansowanych)

| | macOS / Linux | Windows |
|---|---|---|
| wszystko naraz | `network/start.sh` | `network\start.cmd` |
| tylko sieć na kablu | `sudo network/link.sh up` | `network\link.cmd up` |
| tylko model dla mini PC | `network/llm-bridge.sh start` | `network\link.cmd bridge-start` |
| stan i adres mini PC | `network/link.sh status` | `network\link.cmd status` |
| cofnięcie zmian | `network/llm-bridge.sh stop`, `sudo network/link.sh down` | `network\link.cmd bridge-stop`, `network\link.cmd down` |

Model jest dostępny tylko na kablu. Ustawienia Twojego komputera (np. własna ścieżka do Ollamy lub Caddy) wpisz w `network/local.env`, wzór: `network/local.env.example`.

## Co jest w środku

- **Information Library** – Wikipedia PL i poradniki (medycyna, majsterkowanie, rolnictwo), wyszukiwanie po słowach.
- **Maps** – mapa Polski offline.
- **AI Assistant** – czat odpowiadający na podstawie bazy wiedzy (wymaga modelu na komputerze).
- **Knowledge Search** (kafelek, port 8070) – znajduje w bazie wiedzy fragmenty najbliższe znaczeniem pytaniu, **bez modelu AI**. Źródła są głównie angielskie, więc pytaj po angielsku.
- **Notes** – notatka **Downloaded content** z listą pobranych materiałów, aktualizuje się sama.

Lista pobieranych materiałów: `content/sources.txt`. Własne dokumenty dla AI wrzuć do `content/knowledge/`.

## Polecenia

| Polecenie | Co robi |
|---|---|
| `make` | uruchamia NOMAD |
| `make down` | zatrzymuje NOMAD |
| `make logs` | pokazuje, co się dzieje |
| `make refresh` | wgrywa zmienione skrypty po `git pull`, bez przebudowy |
| `tests/smoke.sh [adres]` | sprawdza, czy wszystko działa |
