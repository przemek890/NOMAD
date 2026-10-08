# Benchmarks

Jak sprawdzić, że NOMAD działa i jak szybko. Ta notatka leży w repozytorium (`content/notes/Benchmarks.md`)
i NOMAD sam wgrywa ją do Notes. Zmiany rób w repozytorium.

## Automatycznie

| Polecenie (na komputerze z modelem) | Co sprawdza | Czas |
|---|---|---|
| `./nomad test` | czy wszystko działa: panel, internet, CPU i RAM, dysk, Wikipedia, mapy, notatki, wyszukiwanie bez AI, AI | ~1 min |
| `./nomad report` | benchmarki systemu i AI, zapisuje wyniki na dole tej notatki i listę pobranych materiałów | ~10 min |

Test bez internetu: wyłącz Wi‑Fi na komputerze i wpisz `./nomad test`. Wszystko poza internetem ma być „ok”.

## Ręcznie: co wyklikać

Otwórz http://nomad.local:8080 i sprawdź po kolei:

| # | Kliknij | Ma się stać |
|---|---|---|
| 1 | strona główna | kafelki: Information Library, Maps, Notes, AI Assistant, Knowledge Search |
| 2 | **Information Library** → Wikipedia, wyszukaj `Warszawa` | lista artykułów, artykuł się otwiera |
| 3 | **Maps**, wpisz `52.2297, 21.0122`, przybliż | Warszawa z ulicami i dzielnicami |
| 4 | **Notes** | notatki „Jak to działa”, „Benchmarks” i „Downloaded content” |
| 5 | **Knowledge Search**, wpisz `snake bite first aid` | fragmenty z poradników, dopasowanie powyżej 60% |
| 6 | **AI Assistant**, model `local-qwen`, Knowledge Base włączone, zapytaj o pytanie z tabeli niżej | odpowiedź w 10–60 s (z wyszukiwaniem), zgodna z tabelą, ze źródłem |
| 7 | **Settings → Benchmark → Run Full Benchmark** | wynik po ~8 min: system i AI na Twoim modelu z komputera (NOMAD niczego nie pobiera) |
| 8 | **Settings → System** | obciążenie CPU, zajęty RAM i dysk |
| 9 | wyłącz Wi‑Fi na komputerze, powtórz 2–6 | działa tak samo |
| 10 | wyłącz komputer z modelem, powtórz 2–5 | działa; czat AI nie odpowiada (to normalne) |

## Ocena odpowiedzi AI

Pytania i oczekiwane odpowiedzi są w tabeli „AI: poprawność odpowiedzi” niżej. Odpowiedź jest dobra, gdy:
zgadza się z poradnikiem (NHS, CDC, Military Medicine), nie wymyśla dawek ani leków, a po polsku odpowiada po polsku.
Szybkość: czas do pierwszego tokenu i tokeny na sekundę z tabeli „AI: szybkość modelu”.

## Na prezentację: pytania do AI

W **AI Assistant**: model `local-qwen`, **Knowledge Base** włączone, **Thinking** wyłączone. Zacznij od pytania 1,
żeby model załadował się do pamięci (pierwsza odpowiedź jest wolniejsza).

| # | Zapytaj | Co pokazuje | Dobra odpowiedź |
|---|---|---|---|
| 1 | Jaka jest stolica Polski i jaka rzeka przez nią płynie? | model działa na komputerze, szybko (~6 s) | Warszawa, Wisła |
| 2 | According to the NHS, what should I do if I miss a dose of warfarin? | odpowiedź z bazy wiedzy (NHS) | weź, gdy sobie przypomnisz; jeśli dopiero następnego dnia – pomiń; nigdy podwójnej dawki |
| 3 | Co zrobić, gdy pominę dawkę warfaryny? Odpowiedz po polsku. | angielskie źródła, odpowiedź po polsku | to samo co w 2, po polsku |
| 4 | What is the first aid for a snake bite in the field? | poradniki medyczne (CDC, Military Medicine) | unieruchom, spokój, szybko do szpitala; nie nacinaj, nie wysysaj |
| 5 | How do you recognise and treat heat stroke? | j.w. | wysoka temperatura, splątanie; natychmiast chłodzić, cień, woda, pomoc medyczna |
| 6 | Kto jest dyrektorem 1 LO w Tarnowie? Odpowiedz jednym zdaniem. | model **sam** szuka w Wikipedii (narzędzia), poprawia hasło i podaje źródło | Małgorzata Dulęba-Szpala, artykuł „I Liceum Ogólnokształcące im. Kazimierza Brodzińskiego w Tarnowie” |
| 7 | Jakie materiały są pobrane w NOMAD? | model sam czyta notatkę *Downloaded content* | lista: Wikipedia PL, poradniki medyczne, mapa Polski… |

Potem pokaż, że działa bez internetu i bez AI:

| # | Zrób | Co pokazuje |
|---|---|---|
| 8 | wyłącz Wi‑Fi na komputerze, zadaj pytanie 2 i 6 jeszcze raz | AI, baza wiedzy i Wikipedia działają offline |
| 9 | **Knowledge Search**: `snake bite first aid`, potem `Rysy` | fragmenty z poradników i z Wikipedii bez modelu AI, w ułamku sekundy |
| 10 | zamknij Ollamę na komputerze, powtórz 9, otwórz **Information Library** i **Maps** | Wikipedia, mapy i wyszukiwarka działają bez komputera z modelem |

<!-- results: written by ./nomad report, do not edit below -->

## Ostatnie wyniki

Zmierzone 2026-10-08 23:45 na `nomad.local`, internet: jest. Polecenie: `./nomad report`.

Sprzęt: Embedded G-Series GX-420GI Radeon R7E, 4 rdzenie, RAM 3.5 GB (zajęte 2.3 GB), obciążenie CPU 20%.

### System (benchmark NOMAD)

| NOMAD score | CPU 1 wątek | CPU wszystkie wątki | RAM | Dysk odczyt | Dysk zapis |
|---|---|---|---|---|---|
| 20.85 | 356.87 zdarzeń/s | 1099.4 zdarzeń/s | 1.8 mln op/s | 223.99 MB/s | 123.82 MB/s |

### AI: szybkość modelu

| Model | Tokeny/s | Czas do pierwszego tokenu | Ładowanie modelu |
|---|---|---|---|
| local-qwen:latest | 9.7 | 7127 ms | 6.7 s |

### AI: poprawność odpowiedzi (czat z bazą wiedzy, model `local-qwen:latest`)

| Pytanie | Czas | Poprawna | Odpowiedź |
|---|---|---|---|
| According to the NHS, what should I do if I miss a dose of warfarin? | 20 s | ✅ | If you miss a dose of warfarin, here’s what to do:  - **Take it as soon as you remember.** - **If you don’t remember until the next day**, skip the missed d… |
| What is the first aid for a snake bite in the field? | 62 s | ✅ | I'll look up the field first aid for snakebites in the knowledge base.  # First Aid for a Snake Bite in the Field  Based on the NOMAD knowledge base (CDC Yellow… |
| How do you recognise and treat heat stroke? | 57 s | ✅ | ## Recognising Heat Stroke  Heat stroke is a **medical emergency**. It is typically marked by:  - **Core body temperature of 40°C (104°F) or higher** - **Cent… |
| Co zrobić, gdy pominę dawkę warfaryny? Odpowiedz po polsku. | 85 s | ✅ | ## Co zrobić, gdy pominięta została dawka warfaryny?  Zgodnie z poradnikiem **NHS – „How and when to take warfarin / If you forget to take warfarin"**:  … |
| Jaka jest stolica Polski i jaka rzeka przez nią płynie? | 32 s | ✅ | ## Stolica Polski  - **Stolica:** **Warszawa** — miasto stołeczne, położone na Mazowszu, w centralnej Polsce (wg artykułu Wikipedii *Warszawa*). - **Rzeka… |
| Kto jest dyrektorem 1 LO w Tarnowie? Odpowiedz jednym zdaniem. | 24 s | ✅ | Dyrektorem I Liceum Ogólnokształcącego im. Kazimierza Brodzińskiego w Tarnowie jest **Małgorzata Dulęba-Szpala** (wg artykułu Wikipedii „I Liceum Ogól… |

### Wyszukiwanie w bazie wiedzy bez AI (Knowledge Search)

| Pytanie | Czas | Najlepszy fragment | Dopasowanie |
|---|---|---|---|
| missed dose of warfarin | 0.2 s | Anticoagulant medicines - Dosage  - NHS - Warfarin | 82% |
| snake bite first aid | 0.2 s | Zoonotic Exposures: Bites, Stings, Scratches - Management | 75% |
| heat stroke treatment | 0.3 s | Adventure Travel   CDC Yellow Book 2024 - HEAT STROKE | 73% |
| water purification | 0.2 s | Mass Gatherings   CDC Yellow Book 2024 - Provide Education & Guidance to Travelers | 60% |
