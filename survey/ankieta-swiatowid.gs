/**
 * Ankieta do projektu „Światowid — wiedza kryzysowa” (nr 6/MMS_SFOK/2026).
 *
 * Jak użyć:
 * 1. Wejdź na https://script.google.com i kliknij „Nowy projekt”.
 * 2. Usuń przykładowy kod, wklej cały ten plik i zapisz (Ctrl/Cmd + S).
 * 3. U góry wybierz funkcję „utworzAnkiete” i kliknij „Uruchom”. Zatwierdź uprawnienia.
 * 4. W „Dzienniku wykonywania” pojawią się linki: do wypełniania (dla uczestników),
 *    do edycji (dla Ciebie) i do arkusza z odpowiedziami.
 *
 * Wszystkie pytania są jednokrotnego wyboru. Ankieta jest anonimowa: nie zbiera imion ani
 * adresów e-mail. Quiz ma zaznaczone poprawne odpowiedzi; w zakładce „Odpowiedzi” widać,
 * ile osób odpowiedziało poprawnie na każde pytanie.
 */

const TAK_NIE_4 = ['Zdecydowanie tak', 'Raczej tak', 'Raczej nie', 'Zdecydowanie nie'];

// Metryczka, 30 pytań wiedzowych w kolejności prelekcji i na końcu pytanie o rezultaty z wniosku
function utworzAnkiete() {
  const form = FormApp.create('Projekt Światowid — wiedza kryzysowa')
    .setIsQuiz(true)
    .setCollectEmail(false)
    .setAllowResponseEdits(false)
    .setProgressBar(true)
    .setConfirmationMessage('Dziękujemy! Twoja odpowiedź została zapisana.');

  metryczka(form);
  quiz(form);

  // Rezultaty z wniosku (s. 7–8): 80% uczestników deklaruje wzrost wiedzy, min. 30 osób deklaruje wzrost świadomości
  form.addSectionHeaderItem().setTitle('Na koniec');
  jednokrotny(form, 'Czy prelekcja zwiększyła Twoją wiedzę i świadomość o tym, jak zachować dostęp do ważnych informacji w sytuacjach kryzysowych?',
    TAK_NIE_4);

  // Odpowiedzi trafiają do arkusza Google, z którego zrobisz zestawienie wyników do sprawozdania
  const sheet = SpreadsheetApp.create(form.getTitle() + ' (odpowiedzi)');
  form.setDestination(FormApp.DestinationType.SPREADSHEET, sheet.getId());

  Logger.log('Dla uczestników: %s\nEdycja: %s\nWyniki: %s', form.getPublishedUrl(), form.getEditUrl(), sheet.getUrl());
}

// Quiz w kolejności prelekcji (tytuły części to tytuły slajdów), a potem pokazu NOMAD.
// Pytania ABCD o podobnej długości odpowiedzi; poprawne są zaznaczone w trybie testu.
function quiz(form) {
  sekcja(form, 'Danych przybywa na świecie', 3);

  pytanieQuizowe(form, 'Ile razy według prognozy wzrośnie ilość danych w cyfrowym obiegu między 2024 a 2028 rokiem?', [
    '1,6 raza',
    ['2,6 raza', true],
    '4 razy',
    '6,2 raza',
  ]);

  pytanieQuizowe(form, 'Który czynnik według źródeł przytoczonych na prelekcji szczególnie przyspiesza przyrost danych?', [
    'Streaming wideo w coraz wyższej rozdzielczości',
    'Internet rzeczy, czyli miliardy podłączonych czujników',
    ['Rozwój generatywnej sztucznej inteligencji', true],
    'Rozbudowa sieci komórkowych 5G',
  ]);

  pytanieQuizowe(form, 'Ile gigabajtów (GB) ma 1 zettabajt (ZB)?', [
    '1 000 000 GB',
    '1 000 000 000 GB',
    ['1 000 000 000 000 GB', true],
    '1 000 000 000 000 000 GB',
  ]);

  sekcja(form, 'W każdej chwili możemy stracić do nich dostęp', 5);

  pytanieQuizowe(form, 'W listopadzie i grudniu 2024 r. na dnie Bałtyku uszkodzono kilka podmorskich kabli internetowych, m.in. między Finlandią a Niemcami. Większość użytkowników nie zauważyła przerwy. Dlaczego?', [
    'Bo ruch automatycznie przejęły satelity na niskiej orbicie, takie jak Starlink',
    ['Bo ruch przekierowano innymi kablami; region z jednym połączeniem straciłby łączność', true],
    'Bo uszkodzone kable przesyłały wyłącznie energię elektryczną, a nie dane internetowe',
    'Bo podwodne roboty operatorów naprawiły uszkodzone kable w ciągu kilku minut',
  ]);

  pytanieQuizowe(form, 'Którędy przepływa zdecydowana większość danych internetowych między kontynentami?', [
    'Przez satelity na niskiej orbicie, np. Starlink',
    ['Przez podmorskie kable światłowodowe', true],
    'Przez lądowe światłowody biegnące przez Azję',
    'Przez radiolinie łączące sieci komórkowe',
  ]);

  pytanieQuizowe(form, 'W grudniu 2023 r. hakerzy zaatakowali systemy komputerowe Kyivstar, największego operatora sieci komórkowej na Ukrainie. Kable i maszty były sprawne, a mimo to miliony klientów na kilka dni straciły telefon i internet. Dlaczego?', [
    'Bo hakerzy zdalnie odcięli zasilanie wszystkich masztów w całym kraju naraz',
    'Bo hakerzy zainfekowali wirusem telefony wszystkich klientów operatora',
    ['Bo maszty obsługują telefony tylko dzięki centralnym systemom operatora, które przestały działać', true],
    'Bo atak przeciążył satelity, przez które maszty łączą się z resztą sieci',
  ]);

  pytanieQuizowe(form, '28 kwietnia 2025 r. Hiszpania i Portugalia straciły prąd. Dlaczego po kilku godzinach przestał działać także internet w telefonach?', [
    'Bo operatorzy wyłączyli sieć, żeby oszczędzać energię dla szpitali',
    'Bo telefony same wyłączyły transmisję danych, żeby oszczędzać baterię',
    ['Bo stacje bazowe sieci komórkowej mają zasilanie awaryjne tylko na kilka godzin', true],
    'Bo awaria prądu uszkodziła podmorskie kable światłowodowe',
  ]);

  pytanieQuizowe(form, 'Czym jest DNS i co się dzieje podczas jego awarii?', [
    'To system zasilania serwerowni; podczas awarii serwery stron wyłączają się i przestają odpowiadać',
    ['To system zamiany nazw stron na adresy IP; podczas awarii strony działają, ale nie da się ich znaleźć po nazwie', true],
    'To system szyfrowania połączeń; podczas awarii dane płyną przez internet zupełnie bez szyfrowania',
    'To system wyznaczania tras między sieciami; podczas awarii ruch trafia w niewłaściwe miejsce',
  ]);

  sekcja(form, 'W kryzysie informacja jest cenna', 4);

  pytanieQuizowe(form, 'Czym jest Project NOMAD?', [
    'Aplikacją na telefon, która zapisuje odwiedzane strony internetowe do czytania offline',
    ['Otwartym oprogramowaniem, które zmienia komputer w lokalny serwer wiedzy działający bez internetu', true],
    'Siecią serwerów w różnych krajach, która zastępuje zwykły internet podczas awarii',
    'Przeglądarką internetową z wbudowaną kopią najpopularniejszych stron świata',
  ]);

  pytanieQuizowe(form, 'Zaczyna się powódź i znika internet. Ktoś po raz pierwszy uruchamia NOMAD, żeby znaleźć instrukcję pierwszej pomocy. Co się stanie?', [
    'NOMAD pobierze instrukcję przez sieć komórkową, bo potrzebuje mało danych',
    'NOMAD pobierze treści z innych serwerów NOMAD w okolicy',
    'Asystent AI napisze rzetelną instrukcję bez żadnych pobranych treści',
    ['Nic nie znajdzie, bo treści trzeba było pobrać wcześniej, gdy działał internet', true],
  ]);

  pytanieQuizowe(form, 'Której funkcji NIE ma w NOMAD?', [
    'Map offline do orientacji w terenie',
    'Narzędzi do kodowania i przetwarzania danych',
    'Kursów i materiałów edukacyjnych do nauki',
    ['Łączenia z internetem przez satelitę', true],
  ]);

  pytanieQuizowe(form, 'Ile urządzeń może jednocześnie korzystać z jednego serwera NOMAD?', [
    'Tylko jeden komputer, podłączony do serwera kablem',
    'Tylko telefony z zainstalowaną aplikacją NOMAD',
    ['Każde urządzenie w tej samej sieci lokalnej, przez przeglądarkę', true],
    'Każde urządzenie, ale tylko wtedy, gdy działa internet',
  ]);

  sekcja(form, 'Wyszukiwanie semantyczne', 6);

  pytanieQuizowe(form, 'W jakiej kolejności NOMAD przygotowuje materiały do wyszukiwania semantycznego?', [
    'Wybór materiałów → obliczenie embeddingów → podział tekstu na fragmenty',
    ['Wybór materiałów → wydobycie tekstu i podział na fragmenty → obliczenie embeddingów', true],
    'Wydobycie tekstu → obliczenie embeddingów całych dokumentów → podział na fragmenty',
    'Podział tekstu na fragmenty → wybór materiałów → obliczenie embeddingów',
  ]);

  pytanieQuizowe(form, 'Dlaczego NOMAD dzieli długie poradniki na krótkie fragmenty, zanim obliczy embeddingi?', [
    'Żeby baza wiedzy zajmowała mniej miejsca na dysku',
    'Żeby każdy fragment mógł trafić na inny komputer w sieci',
    ['Bo wektor całego poradnika mieszałby wiele tematów, a krótki fragment ma jedno znaczenie', true],
    'Bo model embeddingowy nie potrafi czytać tekstów dłuższych niż jedno zdanie',
  ]);

  pytanieQuizowe(form, 'Czym jest embedding, który tworzy model embeddingowy?', [
    'Listą słów kluczowych wybranych z tekstu',
    'Streszczeniem tekstu przygotowanym przez AI',
    'Skompresowaną kopią tekstu',
    ['Wektorem liczb, który zapisuje znaczenie tekstu', true],
  ]);

  pytanieQuizowe(form, 'Kiedy NOMAD oblicza embedding pytania zadanego przez ucznia?', [
    'Nigdy, bo pytanie porównuje bezpośrednio z tekstem poradników',
    ['W chwili zadania pytania; embeddingi poradników są policzone wcześniej', true],
    'Raz dziennie, razem z embeddingami wszystkich poradników',
    'Dopiero po tym, jak model językowy napisze odpowiedź',
  ]);

  pytanieQuizowe(form, 'Na czym polega wyszukiwanie semantyczne?', [
    'Na szukaniu dokładnie tych samych słów, które wpisał użytkownik',
    ['Na szukaniu fragmentów o podobnym znaczeniu, nawet zapisanych innymi słowami', true],
    'Na szukaniu fragmentów o podobnej budowie zdań i długości',
    'Na szukaniu fragmentów najczęściej czytanych przez innych użytkowników',
  ]);

  pytanieQuizowe(form, 'Uczeń pyta: „co robić, gdy ktoś mocno krwawi?”, a w poradniku jest fragment „tamowanie krwotoku”. Dlaczego NOMAD go znajdzie?', [
    'Bo wektory pytania i fragmentu są prostopadłe, więc ich podobieństwo kosinusowe wynosi 1',
    'Bo wektory pytania i fragmentu mają taką samą długość',
    ['Bo wektory pytania i fragmentu tworzą mały kąt, więc ich podobieństwo kosinusowe jest bliskie 1', true],
    'Bo pytanie i fragment mają tyle samo słów',
  ]);

  sekcja(form, 'Lokalny model AI', 8);

  pytanieQuizowe(form, 'Czym jest duży model językowy (LLM) i jak tworzy odpowiedź?', [
    'To baza gotowych odpowiedzi, z której wybiera najlepiej pasującą',
    'To wyszukiwarka, która przepisuje odpowiedź z najlepszej strony',
    ['To sieć neuronowa, która przewiduje po kolei najbardziej prawdopodobne tokeny', true],
    'To program z regułami gramatyki, który układa zdania według zasad języka',
  ]);

  pytanieQuizowe(form, 'Model dzieli słowo „krwotokiem” na tokeny, czyli fragmenty, np. „krwo”, „tok”, „iem”. Dlaczego pomaga to przy polskiej odmianie wyrazów?', [
    'Bo model usuwa końcówki i zamienia każde słowo na mianownik',
    ['Bo różne formy wyrazu mają wspólne tokeny, więc model je ze sobą wiąże', true],
    'Bo każdy token jest osobnym hasłem ze słownika języka polskiego',
    'Bo model tłumaczy polskie słowa na angielski, który nie ma odmiany',
  ]);

  pytanieQuizowe(form, 'Czym lokalny model językowy różni się od dużego modelu w chmurze, np. najnowszego ChatGPT?', [
    'Jest dokładniejszy, bo ma mniej parametrów i rzadziej się rozprasza',
    'Działa bez internetu, ale dłuższe odpowiedzi pobiera z chmury',
    ['Działa bez internetu i prywatnie, ale ma mniej parametrów, więc częściej się myli', true],
    'Ma tyle samo parametrów, ale działa wolniej, bo nie korzysta z chmury',
  ]);

  pytanieQuizowe(form, 'Jak w NOMAD współpracują model embeddingowy i model językowy (LLM)?', [
    'Model embeddingowy pisze odpowiedź, a LLM wyszukuje pasujące fragmenty',
    ['Model embeddingowy znajduje pasujące fragmenty, a LLM pisze na ich podstawie odpowiedź', true],
    'Oba wyszukują fragmenty, a odpowiedzią jest najlepiej dopasowany fragment',
    'LLM zamienia pytanie na wektor, a model embeddingowy sprawdza fakty w odpowiedzi',
  ]);

  pytanieQuizowe(form, 'NOMAD przekazuje modelowi AI tylko kilka najlepiej dopasowanych fragmentów (domyślnie 5), a nie całą bazę wiedzy. Dlaczego?', [
    'Bo przesłanie całej bazy przez sieć lokalną trwałoby kilka godzin',
    ['Bo model mieści naraz ograniczoną liczbę tokenów, czyli tzw. okno kontekstu', true],
    'Bo pozostałe fragmenty są zaszyfrowane i model nie może ich odczytać',
    'Bo model sam dopyta o resztę fragmentów, jeśli będzie ich potrzebował',
  ]);

  pytanieQuizowe(form, 'Uczeń pyta asystenta AI w NOMAD o swoje objawy chorobowe. Co dzieje się z tym pytaniem?', [
    'Trafia do firmy, która stworzyła model, żeby ulepszyć kolejne wersje',
    'Jest zapisywane w chmurze szkoły',
    ['Zostaje w sieci lokalnej i nie trafia do żadnej firmy w internecie', true],
    'Jest wysyłane anonimowo do twórców Project NOMAD',
  ]);

  pytanieQuizowe(form, 'Zapytany o książkę, która nie istnieje, model podaje jej autora i streszczenie. Jak nazywa się to zjawisko i skąd się bierze?', [
    'Halucynacja: model celowo wprowadza w błąd, żeby wyglądać na kompetentnego',
    ['Halucynacja: model układa najbardziej prawdopodobny tekst, zamiast sprawdzać fakty', true],
    'Przeuczenie: model zapamiętał fałszywą recenzję tej książki',
    'Indeksowanie: model trafił na błędny fragment w bazie wiedzy',
  ]);

  pytanieQuizowe(form, 'Jak NOMAD zmniejsza ryzyko halucynacji asystenta AI?', [
    'Douczy model na szkolnych dokumentach przy każdym pytaniu',
    'Sprawdza każdą odpowiedź drugim, większym modelem',
    ['Daje modelowi pasujące fragmenty z bazy wiedzy jako podstawę odpowiedzi', true],
    'Skraca odpowiedzi, bo krótsze rzadziej zawierają błędy',
  ]);

  sekcja(form, 'Zestaw demonstracyjny i pokaz NOMAD', 4);

  pytanieQuizowe(form, 'Na laptopie działa program Ollama z modelem Qwen3 8B. Co jest prawdą?', [
    'Ollama to model firmy Meta, a „8B” oznacza 8 bilionów parametrów',
    'Ollama pobiera odpowiedzi z chmury, a „8B” oznacza 8 GB pamięci',
    ['Ollama uruchamia model na laptopie, a „8B” oznacza 8 miliardów parametrów', true],
    'Ollama to model embeddingowy, a „8B” oznacza 8 miliardów słów w danych uczących',
  ]);

  pytanieQuizowe(form, 'Podczas pokazu odłączamy internet od przygotowanego wcześniej NOMAD. Co przestanie działać?', [
    'Wikipedia i poradniki',
    'Asystent AI z lokalnym modelem',
    'Mapy offline',
    ['Pobieranie nowych treści i aktualizacji', true],
  ]);

  pytanieQuizowe(form, 'Czy NOMAD zadziała podczas awarii prądu?', [
    'Tak, bo wszystkie treści są zapisane na dysku',
    'Tak, przez kilka godzin, dzięki wbudowanej baterii',
    ['Tylko z zasilaniem awaryjnym, np. z UPS-a lub powerbanku', true],
    'Tylko mapy, bo nie wymagają obliczeń',
  ]);

  pytanieQuizowe(form, 'Co oznacza, że NOMAD jest otwartym oprogramowaniem (open source)?', [
    'Każdy może zmieniać treści na cudzym serwerze NOMAD',
    ['Kod jest publiczny; każdy może go bezpłatnie pobrać, sprawdzić i używać', true],
    'Program jest darmowy, ale jego kod pozostaje tajny',
    'Kod jest publiczny, ale używać go mogą tylko szkoły i urzędy',
  ]);
}

function sekcja(form, tytul, liczba) {
  form.addSectionHeaderItem()
    .setTitle(tytul)
    .setHelpText(liczba + (liczba >= 2 && liczba <= 4 ? ' pytania' : ' pytań') + '. W każdym tylko jedna odpowiedź jest poprawna.');
}

// Metryczka: kim jest uczestnik, płeć, a dla uczniów klasa i profil
function metryczka(form) {
  jednokrotny(form, 'Kim jesteś?',
    ['Uczeń / uczennica', 'Nauczyciel / nauczycielka', 'Inna osoba']);
  jednokrotny(form, 'Płeć', ['Kobieta', 'Mężczyzna', 'Inna', 'Wolę nie podawać']);
  jednokrotny(form, 'Do której klasy chodzisz?',
    ['Pierwsza', 'Druga', 'Trzecia', 'Czwarta', 'Nie dotyczy (nie jestem uczniem)']);
  jednokrotny(form, 'Jaki profil ma Twoja klasa?',
    ['Mat-geo', 'Mat-ang', 'Mat-inf', 'Inny profil', 'Nie dotyczy (nie jestem uczniem)']);
}

function jednokrotny(form, tytul, odpowiedzi) {
  form.addMultipleChoiceItem()
    .setTitle(tytul)
    .setChoiceValues(odpowiedzi)
    .setRequired(true);
}

// Odpowiedź zapisana jako [tekst, true] jest poprawna
function pytanieQuizowe(form, tytul, odpowiedzi) {
  const item = form.addMultipleChoiceItem();
  item.setTitle(tytul)
    .setChoices(odpowiedzi.map((o, i) => {
      const litera = 'ABCD'[i] + ') ';
      return Array.isArray(o) ? item.createChoice(litera + o[0], true) : item.createChoice(litera + o, false);
    }))
    .setPoints(1)
    .setRequired(true);
}
