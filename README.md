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

Jak to działa:
- **Mini PC** po włączeniu sam uruchamia NOMAD (ok. 2–3 min), także po zaniku prądu. Nic na nim nie robisz.
- **Komputer** po `./nomad start` dostaje na kablu adres `10.77.0.1`, nadaje adres mini PC, udostępnia mu internet (jeśli jest)
  i swój model AI. To jedyne, co robisz – po każdym włączeniu komputera albo na nowym komputerze.
- **NOMAD** otwierasz w przeglądarce na komputerze pod adresem mini PC: **http://nomad.local:8080** (to nie `localhost`, bo NOMAD działa na mini PC).

### Pierwszy raz

1. **Na komputerze** pobierz projekt (**Code > Download ZIP**, rozpakuj) i połącz komputer z mini PC kablem Ethernet.
2. **Na komputerze** otwórz Terminal (macOS, Linux) albo PowerShell (Windows) w folderze projektu i wpisz:

   ```bash
   ./nomad start
   ```

   To jedno polecenie robi wszystko: instaluje i uruchamia Ollamę, pobiera model czatu (`qwen3:8b`) i model
   wyszukiwania (raz, ok. 5 GB), stawia sieć na kablu i udostępnia model mini PC. Na końcu pokazuje adres mini PC, np. `10.77.0.11`.
   - macOS: potrzebny [Homebrew](https://brew.sh); zapyta o hasło do komputera.
   - Windows: potrzebny internet (np. Wi‑Fi); potwierdź okno administratora. Możesz też kliknąć dwa razy `nomad.cmd`.
   - Inny model czatu: wpisz go w `network/local.env` (wzór: `network/local.env.example`), np. `CHAT_MODEL=qwen3:14b`.
3. **Mini PC** (tylko raz; jeśli NOMAD już na nim jest, pomiń): skopiuj projekt i zainstaluj
   (w folderze, w którym leży folder projektu, np. `NOMAD-main` z ZIP-a; `użytkownik` to login na mini PC, adres z kroku 2):

   ```bash
   scp -r NOMAD-main użytkownik@10.77.0.11:NOMAD
   ssh użytkownik@10.77.0.11
   ```

   ```bash
   cd NOMAD && NOMAD_LLM_URL=http://10.77.0.1:11434 NOMAD_EMBED_URL=http://10.77.0.1:11434 bash install.sh
   ```

4. Otwórz **http://nomad.local:8080** (albo `http://<adres mini PC>:8080`).

**Nowy albo wyczyszczony komputer** (Mac, Windows, Linux): kroki 1, 2 i 4. Mini PC zostaje bez zmian.

### Na co dzień

| Sytuacja | Co zrobić |
|---|---|
| Uruchomiłeś ponownie komputer | `./nomad start` |
| Uruchomiłeś ponownie mini PC | nic, NOMAD wstaje sam po kilku minutach |
| Przepinasz mini PC do innego komputera (np. z Maca do Windowsa) | na nowym komputerze `./nomad start`; mini PC zostaje bez zmian |
| Chcesz używać NOMAD | otwórz http://nomad.local:8080 |
| Chcesz sprawdzić, czy wszystko działa | `./nomad test` |

Do czatu AI komputer musi być włączony i nieuśpiony. Wikipedia, mapy, notatki i wyszukiwarka wiedzy działają bez niego.

### Mały mini PC (np. HP t630, 4 GB RAM)

Zainstaluj Debiana 13 bez pulpitu zamiast Windowsa: zostaje ok. 3 GB wolnego RAM.
`minipc/preseed.cfg` instaluje go automatycznie (**kasuje cały dysk**). Po instalacji wpisz na mini PC `sudo minipc/tune.sh`.

### Polecenie `./nomad`

Działa tak samo na macOS, Linux i Windows (PowerShell):

| Polecenie | Co robi |
|---|---|
| `./nomad start` | przygotowuje komputer (Ollama, modele), stawia sieć na kablu i udostępnia model mini PC |
| `./nomad status` | pokazuje sieć, adres mini PC i model |
| `./nomad test` | sprawdza, czy NOMAD działa (na Windows potrzebny [Git](https://git-scm.com)) |
| `./nomad report` | benchmarki systemu i AI, zapisuje je w `content/notes/Benchmarks.md` (~10 min) |
| `./nomad stop` | wyłącza sieć na kablu i udostępnianie modelu |

Model jest dostępny tylko na kablu. Ustawienia Twojego komputera (np. własna ścieżka do Ollamy lub Caddy) wpisz w `network/local.env`, wzór: `network/local.env.example`.

## Co jest w środku

- **Information Library** – Wikipedia PL i poradniki (medycyna, majsterkowanie, rolnictwo), wyszukiwanie po słowach.
- **Maps** – mapa Polski offline.
- **AI Assistant** – czat odpowiadający na podstawie bazy wiedzy (wymaga modelu na komputerze).
- **Knowledge Search** (kafelek, port 8070) – znajduje w bazie wiedzy fragmenty najbliższe znaczeniem pytaniu, **bez modelu AI**. Źródła są głównie angielskie, więc pytaj po angielsku.
- **Notes** – notatki z repozytorium (`content/notes`): **Benchmarks** (jak sprawdzić, że działa, i wyniki pomiarów)
  oraz **Downloaded content** (lista pobranych materiałów, w NOMAD aktualizuje się sama).

Lista pobieranych materiałów: `content/sources.txt`. Własne dokumenty dla AI wrzuć do `content/knowledge/`.

## Polecenia

| Polecenie | Co robi |
|---|---|
| `make` | uruchamia NOMAD |
| `make down` | zatrzymuje NOMAD |
| `make logs` | pokazuje, co się dzieje |
| `make refresh` | wgrywa zmienione skrypty po `git pull`, bez przebudowy |
| `tests/smoke.sh [adres]` | sprawdza, czy wszystko działa (to samo co `./nomad test`) |
