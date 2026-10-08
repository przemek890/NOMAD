# Jak to działa

Pełny opis zestawu NOMAD: z czego się składa, jak płyną dane, co potrafi, dlaczego tak go zbudowano
i jak go sprawdzić. Plik leży w repozytorium (`content/notes/Jak to działa.md`); NOMAD wgrywa go do Notes.

## 1. Cel

Encyklopedia, mapy, poradniki i asystent AI, które działają **bez internetu**. Ciężką pracę AI robi
laptop z dobrą kartą graficzną, a wszystko inne mały, cichy mini PC, który może działać cały czas.

## 2. Elementy

| Element | Co to jest | Rola |
|---|---|---|
| **Komputer z modelem** | laptop: macOS, Windows albo Linux | uruchamia model AI (Ollama), tworzy sieć na kablu |
| **Mini PC** | HP t630: 4 rdzenie AMD GX-420GI, 4 GB RAM, dysk 30 GB, Debian 13 bez pulpitu | NOMAD: Wikipedia, mapy, notatki, baza wiedzy, wyszukiwarka |
| **Kabel Ethernet** | bezpośrednio, bez routera | jedyne połączenie między nimi |
| **Repozytorium** | github.com/przemek890/NOMAD | cały kod i konfiguracja; z niego zestaw stawia się sam |

## 3. Jak płyną dane

```
 Przeglądarka na laptopie
        │  http://nomad.local:8080
        ▼
 Mini PC ── NOMAD (panel) ──┬── Information Library (Kiwix: Wikipedia PL, poradniki)
   10.77.0.11               ├── Maps (mapa Polski, PMTiles)
                            ├── Notes (Flatnotes)
                            ├── baza wiedzy (Qdrant: wektory fragmentów poradników)
                            └── AI Assistant ──► router (nomad-llm)
                                                   │ czat
                                                   ▼
                                    serwis narzędzi (search) ──► Wikipedia / baza wiedzy / notatki
                                                   │
                                     kabel         ▼
 Laptop 10.77.0.1 ── mostek :11434 ──► Ollama: model czatu (np. local-qwen) + nomic-embed-text
```

1. Otwierasz NOMAD w przeglądarce laptopa pod adresem mini PC: `http://nomad.local:8080`.
2. Pytanie w czacie idzie z panelu NOMAD do **routera** w NOMAD Box, a z niego do **serwisu narzędzi**.
3. Serwis narzędzi podaje modelowi listę narzędzi i krótki opis, co jest w NOMAD. **Model sam decyduje**,
   czy szukać: w Wikipedii, w bazie wiedzy albo w notatkach. Serwis wykonuje wyszukiwanie i oddaje wyniki modelowi.
4. Model na laptopie pisze odpowiedź ze źródłem; odpowiedź płynie słowo po słowie z powrotem do przeglądarki.
5. Wszystko poza samym modelem działa na mini PC, także bez laptopa i bez internetu.

## 4. Sieć na kablu

| Co | Wartość |
|---|---|
| Sieć | `10.77.0.0/24` |
| Laptop | `10.77.0.1` (ten sam na Macu, Windowsie i Linuksie, więc mini PC działa z każdym) |
| Mini PC | adres z puli `10.77.0.10–50`, nadawany przez laptopa (DHCP), np. `10.77.0.11` |
| Nazwa mini PC | `nomad.local` (mDNS, Avahi) |
| Internet dla mini PC | laptop udostępnia swój (NAT); bez niego NOMAD działa dalej |
| Model dla mini PC | mostek `10.77.0.1:11434` → Ollama `127.0.0.1:11434`, tylko na kablu |

Porty na mini PC: `8080` panel NOMAD, `8070` Knowledge Search, `8090` Information Library (Kiwix),
`8200` Notes, `9999` logi. Mostek przepuszcza tylko czat, embeddingi i listę modeli: **pobieranie,
usuwanie i tworzenie modeli jest zablokowane** (na Macu i Linuksie w mostku, a na mini PC w routerze).

## 5. Funkcje

| Funkcja | Co robi | Działa bez laptopa | Działa bez internetu |
|---|---|---|---|
| **Information Library** | Wikipedia PL (8 GB) i poradniki; czytanie i wyszukiwanie po słowach | tak | tak |
| **Maps** | mapa Polski do poziomu ulic | tak | tak |
| **Notes** | notatki, m.in. *Downloaded content*, *Benchmarks*, ta notatka | tak | tak |
| **Knowledge Search** | fragmenty z bazy wiedzy (po znaczeniu) i z Wikipedii (po słowach), bez AI | tak | tak |
| **AI Assistant** | czat z modelem, który sam przeszukuje Wikipedię, bazę wiedzy i notatki | nie | tak |
| **Benchmark** | pomiar CPU, RAM, dysku i AI (Settings → Benchmark) | system: tak, AI: nie | tak |

## 6. AI

- **Model czatu** działa na laptopie w Ollamie, np. `local-qwen` (Qwen 27B) albo domyślnie `qwen3:8b`.
  Mini PC jest za słaby na taki model (4 GB RAM, brak karty graficznej).
- **Model embeddingów** `nomic-embed-text:v1.5` zamienia tekst na wektory (768 liczb). Ten sam model jest
  na laptopie (do indeksowania) i na mini PC (do wyszukiwania bez laptopa), więc wektory się zgadzają.
- **Baza wiedzy (RAG)**: NOMAD tnie poradniki medyczne (NHS, CDC, Military Medicine, Medical Library) na
  fragmenty, zapisuje ich wektory w Qdrant (ok. 26 tys.) i przy pytaniu dokleja najbliższe fragmenty.
- **Wikipedia nie jest w bazie wektorowej**: 8 GB tekstu to miliony fragmentów i kilkanaście GB wektorów
  na dysku 30 GB. Zamiast tego model ma **narzędzia** (tool calling) i sam szuka w Wikipedii jej własną
  wyszukiwarką (tytuły i pełny tekst, ok. 0,1–0,7 s).
- **Narzędzia modelu**: `search_wikipedia`, `read_article`, `search_knowledge_base`, `search_notes`.
  Model dostaje jeden krótki opis tego, co ma NOMAD; nic nie jest dopisywane do rozmowy za jego plecami.
- **Gdy nie znajdzie**: ma powiedzieć, że nie wie, zamiast zgadywać (np. nazwisk, dat, liczb).
- **Ograniczenia**: poradniki są po angielsku (w Knowledge Search najlepiej pytać po angielsku); czat
  odpowiada w języku pytania; odpowiedź z wyszukiwaniem trwa ok. 20–60 s.

## 7. Uruchamianie

| Kto | Co | Kiedy |
|---|---|---|
| **Laptop** | `./nomad start` (Terminal na macOS/Linux, PowerShell na Windows albo dwuklik `nomad.cmd`) | po każdym włączeniu albo na nowym laptopie |
| **Mini PC** | nic: NOMAD wstaje sam ok. 2,5 min po włączeniu (także po zaniku prądu) | – |
| **Mini PC, pierwszy raz** | skopiować projekt (`scp`) i `bash install.sh` z adresem modelu | raz |

`./nomad start` na nowym laptopie sam: instaluje Ollamę (Homebrew / skrypt / winget), pobiera raz model
czatu i model embeddingów, instaluje Caddy, stawia sieć i mostek. `./nomad` to **fasada**: to samo
polecenie na każdym systemie, a różnice są schowane w `network/*.sh` (macOS, Linux) i `network/link.ps1` (Windows).

Inne polecenia: `./nomad status` (sieć i adres mini PC), `./nomad test` (czy wszystko działa),
`./nomad report` (benchmarki do notatki *Benchmarks*), `./nomad stop` (cofnięcie sieci).

## 8. Jak zbudowany jest NOMAD Box (mini PC)

- **Docker na Debianie**, kontenery z automatycznym wstawaniem (`restart: unless-stopped`).
- `nomad-box`: jeden kontener z własnym Dockerem w środku (Docker-in-Docker), a w nim usługi NOMAD:
  panel (`nomad_admin`), MySQL, Redis, Qdrant, Kiwix, Flatnotes, CyberChef, Dozzle.
- `nomad-embed`: llama.cpp z `nomic-embed-text` (własny odchudzony obraz: 195 MB zamiast 1,2 GB).
- `nomad-search`: Knowledge Search i narzędzia czatu (Python, tylko biblioteka standardowa).
- **Router** `nomad-llm` (Caddy) w `nomad-box`: czat → serwis narzędzi (gdy nie działa, prosto do modelu),
  embeddingi → laptop, lista modeli → scalona, zarządzanie modelami → zablokowane.
- **Treści** z `content/sources.txt` pobierają się same; notatki z `content/notes` trafiają do Notes.

## 9. Decyzje i dlaczego

| Decyzja | Dlaczego |
|---|---|
| Debian zamiast Windowsa na mini PC | Windows LTSC 2019 nie uruchomi Docker Desktop (brak WSL2), a sam zajmował ok. 3 GB z 4 GB RAM |
| Instalacja Debiana bez pendrive'a | instalator wgrany z Windowsa na partycję EFI, konfiguracja automatyczna (`minipc/preseed.cfg`) |
| Model na laptopie, NOMAD na mini PC | mini PC bez karty graficznej liczyłby odpowiedź kilka minut |
| Embeddingi na laptopie | lokalna Ollama dla kart AMD zajmowała 3,2 GB, a indeksowanie na mini PC trwałoby dni |
| Mały model embeddingów też na mini PC | wyszukiwanie w bazie wiedzy działa bez laptopa |
| Wikipedia przez narzędzia, nie wektory | za duża na dysk i na czas indeksowania |
| Limity logów 30 MB, MySQL bez binlogu, bez danych FDA | dysk 30 GB zapełnił się raz do zera |
| Benchmark AI na modelu czatu | NOMAD ma na sztywno `llama3.1:8b` i chce go pobrać; podmieniamy na model, który już działa |
| Blokada pobierania modeli | NOMAD korzysta tylko z modeli laptopa przez API |
| Jedno polecenie `./nomad` | to samo na macOS, Windows i Linux (wzorzec fasady) |
| Ustawienia laptopa w `network/local.env` | ścieżki jednego komputera nie trafiają do kodu (plik poza gitem) |

## 10. Testy i benchmarki

- `./nomad test`: panel, internet, CPU i RAM, dysk, Wikipedia, mapy, notatki, Knowledge Search, AI z bazy
  wiedzy i AI z Wikipedii (narzędzia). Brak internetu to informacja, nie błąd.
- `./nomad report`: benchmark systemu NOMAD, szybkość modelu, poprawność odpowiedzi na stały zestaw pytań,
  czasy Knowledge Search; wyniki trafiają do notatki *Benchmarks*.
- **Settings → Benchmark → Run Full Benchmark**: wynik NOMAD z AI na modelu z laptopa.
- Ręczny scenariusz i pytania na prezentację: notatka *Benchmarks*.

Zmierzone na HP t630 z Qwen 27B na MacBooku: NOMAD Score 20,95 (sam system) i 27,49 (z AI), model
ok. 9,7 tokena/s, Knowledge Search ok. 0,2 s, NOMAD po restarcie mini PC po ok. 134 s, wszystkie testy
przechodzą także bez internetu.

## 11. Bezpieczeństwo

- Model jest dostępny **tylko na kablu** (`10.77.0.1`), nie w Wi‑Fi; na laptopie Ollama słucha tylko na `127.0.0.1`.
- NOMAD nie może pobierać, usuwać ani tworzyć modeli.
- Logowanie na mini PC przez SSH **tylko kluczem**; hasła wyłączone.
- Bez internetu nic nie wychodzi na zewnątrz; z internetem NOMAD sprawdza tylko aktualizacje i pobiera treści z listy.

## 12. Gdy coś nie działa

| Objaw | Co zrobić |
|---|---|
| `nomad.local` się nie otwiera | `./nomad status` pokaże adres mini PC; wpisz `http://10.77.0.x:8080` |
| Czat AI nie odpowiada | laptop włączony? `./nomad start`; sprawdź `./nomad test` |
| AI zmyśla | zapytaj o źródło; sprawdź w Information Library; najlepiej podać nazwę (szkoły, miasta) |
| Po restarcie mini PC strona nie działa | poczekaj 3 minuty |
| Brak miejsca na dysku | `./nomad test` pokaże wolne miejsce; mniej treści w `content/sources.txt` |

## 13. Słowniczek

- **Ollama** – program uruchamiający modele AI na komputerze, z API na porcie 11434.
- **Model czatu (LLM)** – sieć neuronowa pisząca odpowiedzi, np. Qwen.
- **Embedding** – zamiana tekstu na wektor liczb; teksty o podobnym znaczeniu mają podobne wektory.
- **RAG** – odpowiadanie na podstawie fragmentów znalezionych w bazie wiedzy i doklejonych do pytania.
- **Tool calling (narzędzia)** – model sam prosi o wykonanie funkcji (np. wyszukania) i dostaje wynik.
- **Qdrant** – baza wektorów, w której NOMAD trzyma fragmenty bazy wiedzy.
- **Kiwix / ZIM** – czytnik i format plików z offline'owymi stronami (Wikipedia, poradniki).
- **PMTiles** – plik z mapą offline.
- **Docker / kontener** – izolowane środowisko uruchamiające jedną usługę.
- **Docker-in-Docker** – Docker uruchomiony w kontenerze; tak NOMAD Box zamyka cały NOMAD w jednym kontenerze.
- **DHCP** – automatyczne nadawanie adresów IP; tu robi to laptop.
- **NAT** – udostępnianie internetu jednego komputera innym.
- **mDNS** – nazwy `.local` w sieci bez serwera DNS (`nomad.local`).
- **Fasada** – wzorzec projektowy: jedno proste wejście (`./nomad`) ukrywa różne implementacje.
