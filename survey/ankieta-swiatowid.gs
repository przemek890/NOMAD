const TAK_NIE_4 = ['Zdecydowanie tak', 'Raczej tak', 'Raczej nie', 'Zdecydowanie nie'];

function utworzAnkiete() {
  const form = FormApp.create('Projekt Światowid — wiedza kryzysowa')
    .setIsQuiz(true)
    .setCollectEmail(false)
    .setAllowResponseEdits(false)
    .setProgressBar(true)
    .setConfirmationMessage('Dziękujemy! Twoja odpowiedź została zapisana.');

  metryczka(form);
  quiz(form);

  jednokrotny(form, 'Czy prelekcja zwiększyła Twoją wiedzę i świadomość o tym, jak zachować dostęp do ważnych informacji w sytuacjach kryzysowych?',
    TAK_NIE_4);

  const sheet = SpreadsheetApp.create(form.getTitle() + ' (odpowiedzi)');
  form.setDestination(FormApp.DestinationType.SPREADSHEET, sheet.getId());

  Logger.log('Dla uczestników: %s\nEdycja: %s\nWyniki: %s', form.getPublishedUrl(), form.getEditUrl(), sheet.getUrl());
}

function quiz(form) {
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

  pytanieQuizowe(form, 'W listopadzie i grudniu 2024 r. na dnie Bałtyku uszkodzono kilka podmorskich kabli internetowych, m.in. między Finlandią a Niemcami. Większość użytkowników nie zauważyła przerwy. Dlaczego?', [
    'Bo ruch automatycznie przejęły satelity na niskiej orbicie, takie jak Starlink',
    ['Bo ruch przekierowano innymi kablami; region z jednym połączeniem straciłby łączność', true],
    'Bo na czas naprawy operatorzy przełączyli klientów na sieci komórkowe 5G',
    'Bo uszkodzone były tylko kable zapasowe, które na co dzień nie przesyłały ruchu',
  ]);

  pytanieQuizowe(form, 'Ile zwykle trwa naprawa uszkodzonego kabla podmorskiego?', [
    'Kilka minut, bo sieć sama przełącza się na zapasową żyłę w kablu',
    'Kilka godzin, bo kabel naprawiają nurkowie',
    ['Od kilku dni do kilku tygodni, bo potrzebny jest specjalny statek kablowy', true],
    'Kilka lat, bo trzeba położyć zupełnie nowy kabel',
  ]);

  pytanieQuizowe(form, 'W grudniu 2023 r. hakerzy zaatakowali systemy komputerowe Kyivstar, największego operatora sieci komórkowej na Ukrainie. Kable i maszty były sprawne, a mimo to miliony klientów na kilka dni straciły telefon i internet. Dlaczego?', [
    'Bo hakerzy zdalnie odcięli zasilanie wszystkich masztów w całym kraju naraz',
    'Bo hakerzy zainfekowali wirusem telefony wszystkich klientów operatora',
    ['Bo maszty obsługują telefony tylko dzięki centralnym systemom operatora, które przestały działać', true],
    'Bo operator sam wyłączył sieć, żeby hakerzy nie dostali się do telefonów klientów',
  ]);

  pytanieQuizowe(form, '28 kwietnia 2025 r. Hiszpania i Portugalia straciły prąd. Dlaczego po kilku godzinach przestał działać także internet w telefonach?', [
    'Bo operatorzy wyłączyli sieć, żeby oszczędzać energię dla szpitali',
    'Bo telefony same wyłączyły transmisję danych, żeby oszczędzać baterię',
    ['Bo stacje bazowe sieci komórkowej mają zasilanie awaryjne tylko na kilka godzin', true],
    'Bo bez prądu przestały działać satelity GPS, z których korzystają sieci komórkowe',
  ]);

  pytanieQuizowe(form, 'Czym jest DNS i co się dzieje podczas jego awarii?', [
    'To serwer, na którym zapisane są wszystkie strony; podczas awarii strony znikają z internetu',
    ['To system zamiany nazw stron na adresy IP; podczas awarii strony działają, ale nie da się ich znaleźć po nazwie', true],
    'To system szyfrowania połączeń; podczas awarii dane płyną przez internet zupełnie bez szyfrowania',
    'To system wyznaczania tras między sieciami; podczas awarii ruch trafia w niewłaściwe miejsce',
  ]);

  pytanieQuizowe(form, 'Czym jest Project NOMAD?', [
    'Otwartą aplikacją na telefon, która zapisuje odwiedzane strony do czytania offline',
    ['Otwartym oprogramowaniem, które zmienia komputer w lokalny serwer wiedzy działający bez internetu', true],
    'Otwartą siecią serwerów w różnych krajach, która zastępuje internet podczas awarii',
    'Otwartą przeglądarką z kopią najpopularniejszych stron, działającą bez internetu',
  ]);

  pytanieQuizowe(form, 'Zaczyna się powódź i znika internet. Ktoś po raz pierwszy uruchamia NOMAD, żeby znaleźć instrukcję pierwszej pomocy. Co się stanie?', [
    'NOMAD pobierze instrukcję przez sieć komórkową, bo potrzebuje mało danych',
    'NOMAD pobierze treści z innych serwerów NOMAD w okolicy',
    'Asystent AI napisze rzetelną instrukcję bez żadnych pobranych treści',
    ['Nic nie znajdzie, bo treści trzeba było pobrać wcześniej, gdy działał internet', true],
  ]);

  pytanieQuizowe(form, 'Której funkcji NIE ma w NOMAD?', [
    'Map offline do orientacji w terenie',
    'Notatek',
    'Kursów i materiałów edukacyjnych do nauki',
    ['Łączenia z internetem przez satelitę', true],
  ]);

  pytanieQuizowe(form, 'Ile urządzeń może jednocześnie korzystać z jednego serwera NOMAD?', [
    'Tylko jeden komputer, podłączony do serwera kablem',
    'Tylko telefony z zainstalowaną aplikacją NOMAD',
    ['Każde urządzenie w tej samej sieci lokalnej, przez przeglądarkę', true],
    'Każde urządzenie, ale tylko wtedy, gdy działa internet',
  ]);

  pytanieQuizowe(form, 'Czym jest embedding, który tworzy model embeddingowy?', [
    'Wektorem liczb opisującym długość tekstu i liczbę słów',
    'Wektorem liczb z numerami stron, na których występuje tekst',
    ['Wektorem liczb opisującym znaczenie tekstu', true],
    'Listą słów kluczowych wybranych z tekstu',
  ]);

  pytanieQuizowe(form, 'Na czym polega wyszukiwanie semantyczne?', [
    'Na szukaniu dokładnie tych samych słów, które wpisał użytkownik',
    ['Na szukaniu fragmentów o podobnym znaczeniu, nawet zapisanych innymi słowami', true],
    'Na szukaniu fragmentów o podobnej budowie zdań i długości',
    'Na szukaniu fragmentów najczęściej czytanych przez innych użytkowników',
  ]);

  pytanieQuizowe(form, 'W jakiej kolejności NOMAD przygotowuje materiały do wyszukiwania semantycznego?', [
    'Wybór materiałów → obliczenie embeddingów → podział tekstu na fragmenty',
    ['Wybór materiałów → wydobycie tekstu i podział na fragmenty → obliczenie embeddingów', true],
    'Wydobycie tekstu → obliczenie embeddingów całych dokumentów → podział na fragmenty',
    'Podział tekstu na fragmenty → wybór materiałów → obliczenie embeddingów',
  ]);

  pytanieQuizowe(form, 'Dlaczego NOMAD dzieli długie poradniki na krótkie fragmenty?', [
    'Żeby baza wiedzy zajmowała mniej miejsca na dysku',
    'Bo krótkie fragmenty szybciej wyświetlają się w przeglądarce',
    ['Bo długi poradnik porusza wiele tematów, a krótki fragment łatwiej dopasować do jednego pytania', true],
    'Bo model embeddingowy nie potrafi czytać tekstów dłuższych niż jedno zdanie',
  ]);

  pytanieQuizowe(form, 'Kiedy NOMAD oblicza embedding pytania zadanego przez ucznia?', [
    'Nigdy, bo pytanie porównuje bezpośrednio z tekstem poradników',
    ['W chwili zadania pytania; embeddingi poradników są policzone wcześniej', true],
    'Raz dziennie, razem z embeddingami wszystkich poradników',
    'Dopiero po tym, jak model językowy napisze odpowiedź',
  ]);

  pytanieQuizowe(form, 'Uczeń pyta, jak zatamować krwotok. Jak NOMAD wybiera fragment poradnika, który najlepiej pasuje do pytania?', [
    'Wybiera fragment, którego wektor jest prostopadły do wektora pytania, bo wtedy podobieństwo kosinusowe wynosi 1',
    'Wybiera fragment, którego wektor ma największą długość',
    ['Wybiera fragment, którego wektor tworzy z wektorem pytania najmniejszy kąt, bo wtedy podobieństwo kosinusowe jest najbliższe 1', true],
    'Wybiera fragment, w którym najczęściej powtarza się słowo „krwotok”',
  ]);

  pytanieQuizowe(form, 'Czym jest duży model językowy (LLM) i jak tworzy odpowiedź?', [
    'To baza gotowych odpowiedzi, którą przeszukuje po tokenach',
    'To wyszukiwarka, która składa odpowiedź z tokenów najlepszej strony',
    ['To sieć neuronowa, która przewiduje po kolei najbardziej prawdopodobne tokeny', true],
    'To program z regułami gramatyki, który łączy tokeny według zasad języka',
  ]);

  pytanieQuizowe(form, 'Model dzieli słowo „krwotokiem” na tokeny, czyli fragmenty, np. „krwo”, „tok”, „iem”. Dlaczego pomaga to przy polskiej odmianie wyrazów?', [
    'Bo model usuwa końcówki i zamienia każde słowo na mianownik',
    ['Bo różne formy wyrazu mają wspólne tokeny, więc model je ze sobą wiąże', true],
    'Bo każdy token jest osobnym hasłem ze słownika języka polskiego',
    'Bo model tłumaczy polskie słowa na angielski, który nie ma odmiany',
  ]);

  pytanieQuizowe(form, 'Czym lokalny model językowy różni się od dużego modelu w chmurze, np. najnowszego ChatGPT?', [
    'Jest dokładniejszy, bo ma mniej parametrów i rzadziej się rozprasza',
    'Działa bez internetu, ale odpowiada tylko po angielsku',
    ['Działa bez internetu, ale ma mniej parametrów, więc częściej się myli', true],
    'Ma tyle samo parametrów, ale działa wolniej, bo nie korzysta z chmury',
  ]);

  pytanieQuizowe(form, 'Jak w NOMAD współpracują model embeddingowy i model językowy (LLM)?', [
    'Model embeddingowy pisze odpowiedź, a LLM wyszukuje pasujące fragmenty',
    ['Model embeddingowy znajduje pasujące fragmenty, a LLM pisze na ich podstawie odpowiedź', true],
    'Oba wyszukują fragmenty, a odpowiedzią jest najlepiej dopasowany fragment',
    'LLM zamienia pytanie na wektor, a model embeddingowy sprawdza fakty w odpowiedzi',
  ]);

  pytanieQuizowe(form, 'Dlaczego model AI w NOMAD nie może przeczytać naraz całej bazy wiedzy?', [
    'Bo przesłanie całej bazy przez sieć lokalną trwałoby kilka godzin',
    ['Bo model mieści naraz ograniczoną liczbę tokenów, czyli tzw. okno kontekstu', true],
    'Bo model czyta tylko teksty napisane po angielsku',
    'Bo baza wiedzy jest zapisana w formacie, którego model nie otwiera',
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

  pytanieQuizowe(form, 'Asystent AI w NOMAD podał dawkowanie leku. Co warto zrobić?', [
    'Zaufać mu, bo odpowiedź oparta na bazie wiedzy jest zawsze poprawna',
    'Zapytać drugi raz, bo jeśli odpowiedź się powtórzy, to jest prawdziwa',
    ['Sprawdzić ją w źródle, do którego odsyła asystent', true],
    'Zignorować ją, bo lokalne modele zawsze podają błędne dawki',
  ]);

  pytanieQuizowe(form, 'Na laptopie działa program Ollama z modelem Qwen3 8B. Co jest prawdą?', [
    'Ollama to model firmy Meta, a „8B” oznacza 8 bilionów parametrów',
    'Ollama pobiera odpowiedzi z chmury, a „8B” oznacza 8 GB pamięci',
    ['Ollama uruchamia model na laptopie, a „8B” oznacza 8 miliardów parametrów', true],
    'Ollama to model embeddingowy, a „8B” oznacza 8 miliardów słów w danych uczących',
  ]);

  pytanieQuizowe(form, 'Ile miejsca na dysku zajmuje polska Wikipedia bez obrazków pobrana do NOMAD?', [
    'Około 80 MB',
    'Około 800 MB',
    ['Około 8 GB', true],
    'Około 80 GB',
  ]);

  pytanieQuizowe(form, 'Czy NOMAD zadziała podczas awarii prądu?', [
    'Tak, bo wszystkie treści są zapisane na dysku',
    'Tak, przez kilka godzin, dzięki wbudowanej baterii',
    ['Tylko z zasilaniem awaryjnym, np. z UPS-a lub powerbanku', true],
    'Tak, ale tylko na telefonach, bo mają własną baterię',
  ]);

  pytanieQuizowe(form, 'Co oznacza, że oprogramowanie jest open source?', [
    'Każdy może zmieniać treści na cudzym serwerze z tym programem',
    ['Kod jest publiczny; każdy może go bezpłatnie pobrać, sprawdzić i używać', true],
    'Program jest darmowy, ale jego kod pozostaje tajny',
    'Kod jest publiczny, ale używać go mogą tylko szkoły i urzędy',
  ]);
}

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
