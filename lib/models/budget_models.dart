import 'package:flutter/material.dart';

enum MainCategory {
  //główne kategorie wydatków
  expense,
  investment,
}

enum SubCategory {
  //najlepsze wydatki
  stocks('Zakup akcji', MainCategory.investment, Color(0xFF30D158)),
  etf('Wpłata na IKE', MainCategory.investment, Color(0xFF059669)),
  saveAccount(
    'Konto oszczędnościowe',
    MainCategory.investment,
    Color(0xFF14B8A6),
  ),
  education('Kursy/Edukacja', MainCategory.investment, Color(0xFF00C7BE)),

  //dobre wydatki
  bills('Rachunki i opłaty', MainCategory.expense, Color(0xFF0A84FF)),
  rent('Czynsz/Kredyt', MainCategory.expense, Color(0xFF4F46E5)),
  groceries('Zakupy spożywcze', MainCategory.expense, Color(0xFF6366F1)),
  electronisc('Elektronika', MainCategory.expense, Color(0xFF60A5FA)),
  homeStuff('Zakupy do domu', MainCategory.expense, Color(0xFF8B5CF6)),
  pharmacy('Leki i apteka', MainCategory.expense, Color(0xFFD946EF)),
  cosmetics('Kosmetyki', MainCategory.expense, Color(0xFF818CF8)),

  //średnie wydatki
  publicTransport(
    'Transport publiczny',
    MainCategory.expense,
    Color(0xFFFF9F0A),
  ),
  clothes('Ubrania i buty', MainCategory.expense, Color(0xFFEA580C)),
  subscriptions('Subskrypcje', MainCategory.expense, Color(0xFFF59E0B)),
  fuel('Paliwo', MainCategory.expense, Color(0xFFFBBF24)),
  love('Partner/Partnerka', MainCategory.expense, Color(0xFFFFD60A)),
  presnt('Prezenty',MainCategory.expense, Color(0xFFC2410C)),
  hobby('Hobby', MainCategory.expense, Color(0xFFC2410C)),

  //słabe wydatki
  appTransport('Uber', MainCategory.expense, Color(0xFFEF4444)),
  fines('Mandaty i kary', MainCategory.expense, Color(0xFF9F1239)),
  eatingOut('Jedzenie na mieście', MainCategory.expense, Color(0xFFB91C1C)),
  stimulants('Używki', MainCategory.expense, Color(0xFFBE123C)),
  games('Gry', MainCategory.expense, Color(0xFFE11D48)),
  hazard('Hazard', MainCategory.expense, Color(0xFFFF2D55));

  //wlasciwosci kazdej podkategorii
  final String label;
  final MainCategory mainCategory;
  final Color color;

  //konstruktor podkategorii
  const SubCategory(this.label, this.mainCategory, this.color);
}

class BudgetTransaction {
  //cechy pojedynczej transakcji
  final String id; //przydatne np przy usuwaniu
  final String title;
  final double price;
  final SubCategory subCategory;
  final DateTime date;

  //Konstruktor (każda transakcja musi mieć te 5 punktów)
  BudgetTransaction({
    required this.id,
    required this.title,
    required this.price,
    required this.subCategory,
    required this.date,
  });

  //getter do glownej kategorii
  MainCategory get mainCategory => subCategory.mainCategory;
}

//Miesięczny budżet
class MonthlyBudget {
  final int year;
  final int month;
  double?
  initialBudget; //mozna zmienic w dowolnym momencie. ? oznacza ze moze byc null
  final List<BudgetTransaction>
  transactions; //lista z naszymi transakcjami z danego miesiąca
  double? points;

  MonthlyBudget({
    required this.year,
    required this.month,
    this.initialBudget,
    List<BudgetTransaction>? transactions,
  }) : transactions =
           transactions ??
           []; //jesli lista jest pusta(null) to wstawiamy pustą listę

  //czy budzet nie jest pusty i czy jest > 0
  bool get isdBudgetSet => initialBudget != null && initialBudget! > 0;

  //Suma wszystkich wydatków (lewy wykres)
  double get totalExpenses {
    double sum = 0.0;
    for (var t in transactions) {
      if (t.mainCategory == MainCategory.expense) {
        sum += t.price;
      }
    }
    return sum;
  }

  //Suma wszystkich inwestycji (lewy wykres)
  double get totalInvestments {
    double sum = 0.0;
    for (var t in transactions) {
      if (t.mainCategory == MainCategory.investment) {
        sum += t.price;
      }
    }
    return sum;
  }

  //Wolne środki (lewy wykres)
  double get freeFunds {
    if (initialBudget == null) return 0.0;

    final remaning =
        initialBudget! -
        totalExpenses -
        totalInvestments; //! przy zmiennej oznacza ze na pewno nie jest null
    return remaning > 0
        ? remaning
        : 0.0; //jesli przekroczylismy budzet to zwracamy 0
  }

  //Poszczególne podkategorie (prawy wykres)
  Map<SubCategory, double> get subCategoryTotals {
    final Map<SubCategory, double> totals =
        {}; //klucz->wartośc, kluczami sa podkategorie
    for (var t in transactions) {
      totals[t.subCategory] = (totals[t.subCategory] ?? 0.0) + t.price; //dolicza sume transakcji do danej podkategorii a jesli jej nie bylo dodaje pierwsa do 0
    }
    return totals;
  }
}
