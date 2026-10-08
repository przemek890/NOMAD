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
| 4 | **Notes** | notatki „Downloaded content” i „Benchmarks” |
| 5 | **Knowledge Search**, wpisz `snake bite first aid` | fragmenty z poradników, dopasowanie powyżej 60% |
| 6 | **AI Assistant**, model `local-qwen`, Knowledge Base włączone, zapytaj o pytanie z tabeli niżej | odpowiedź w kilkanaście sekund, zgodna z tabelą |
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

Potem pokaż, że działa bez internetu i bez AI:

| # | Zrób | Co pokazuje |
|---|---|---|
| 6 | wyłącz Wi‑Fi na komputerze, zadaj pytanie 2 jeszcze raz | AI i baza wiedzy działają offline |
| 7 | **Knowledge Search**: `snake bite first aid` | wyszukiwanie po znaczeniu bez modelu AI, w ułamku sekundy |
| 8 | zamknij Ollamę na komputerze, powtórz 7, otwórz **Information Library** i **Maps** | Wikipedia, mapy i wyszukiwarka działają bez komputera z modelem |

<!-- results: written by ./nomad report, do not edit below -->

## Ostatnie wyniki

Zmierzone 2026-10-08 22:02 na `nomad.local`, internet: brak. Polecenie: `./nomad report`.

Sprzęt: Embedded G-Series GX-420GI Radeon R7E, 4 rdzenie, RAM 3.5 GB (zajęte 2.3 GB), obciążenie CPU 8%.

### System (benchmark NOMAD)

| NOMAD score | CPU 1 wątek | CPU wszystkie wątki | RAM | Dysk odczyt | Dysk zapis |
|---|---|---|---|---|---|
| 20.95 | 355.91 zdarzeń/s | 1112.02 zdarzeń/s | 1.8 mln op/s | 233.02 MB/s | 123.58 MB/s |

### AI: szybkość modelu

| Model | Tokeny/s | Czas do pierwszego tokenu | Ładowanie modelu |
|---|---|---|---|
| local-qwen:latest | 9.7 | 136 ms | 0 s |

### AI: poprawność odpowiedzi (czat z bazą wiedzy, model `local-qwen:latest`)

| Pytanie | Czas | Poprawna | Odpowiedź |
|---|---|---|---|
| According to the NHS, what should I do if I miss a dose of warfarin? | 29 s | ✅ | If you miss a dose of warfarin, you should follow these steps:  1.  **Take it as soon as you remember**: If you remember on the same day, take the missed dose i… |
| What is the first aid for a snake bite in the field? | 59 s | ✅ | Based on general medical guidelines and standard first aid protocols, here is the procedure for treating a snake bite in the field:  ### **Immediate Actions** 1… |
| How do you recognise and treat heat stroke? | 46 s | ✅ | # Recognizing and Treating Heat Stroke  ## **Recognition** Heat stroke is a medical emergency characterized by the following key signs: *   **High Body Temperat… |
| Co zrobić, gdy pominę dawkę warfaryny? Odpowiedz po polsku. | 85 s | ✅ | ## Co zrobić, gdy zapomnisz przyjąć warfarynę?  Pominięcie dawki leku przeciwkrzepliwego, jakim jest warfaryna, wymaga spokoju i stosowania się do konkret… |
| Jaka jest stolica Polski i jaka rzeka przez nią płynie? | 19 s | ✅ | Stolicą Polski jest **Warszawa**.  Przez tę miasto płynie rzeka **Wisła**.  ### Dodatkowe informacje: - **Wisła** jest najdłuższą rzeką w Polsce (1047 … |

### Wyszukiwanie w bazie wiedzy bez AI (Knowledge Search)

| Pytanie | Czas | Najlepszy fragment | Dopasowanie |
|---|---|---|---|
| missed dose of warfarin | 0.2 s | Anticoagulant medicines - Dosage  - NHS - Warfarin | 82% |
| snake bite first aid | 0.2 s | Zoonotic Exposures: Bites, Stings, Scratches - Management | 75% |
| heat stroke treatment | 0.2 s | Adventure Travel   CDC Yellow Book 2024 - HEAT STROKE | 73% |
| water purification | 0.1 s | Mass Gatherings   CDC Yellow Book 2024 - Provide Education & Guidance to Travelers | 60% |
