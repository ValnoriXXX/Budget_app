import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import '../models/budget_models.dart';

import 'package:fl_chart/fl_chart.dart';

//Główna klasa widżetu
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

//Klasa State (mamy tu pamięć ekranu i jego wygląd)
class _HomeScreenState extends State<HomeScreen> {
  //pobieramy akutalny rok i miesiąc z komputera _ oznacza ze zmienna jest private
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _currentChartIndex = 0; //0-glowny wykres 1-wykres podkategorii

  static const List<String> _monthNames = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
    'Listopad',
    'Grudzień',
  ];

  //Klucz to np. 2026-6 a wartość to obiekt typu MonthlyBudget
  final Map<String, MonthlyBudget> _budgets = {};

  //getter do aktualnego miesiąca i roku
  MonthlyBudget get _currentBudget {
    final key = '$_selectedYear-$_selectedMonth';

    if (!_budgets.containsKey(key)) {
      _budgets[key] = MonthlyBudget(
        year: _selectedYear,
        month: _selectedMonth,
      ); //dla kazdego nieodwiedzonej daty(klucza) tworzymy nowy obiekt
    }
    return _budgets[key]!;
  }

  //Funkcja cofająca o miesiąc
  void _previusMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  //Funkcja idąca o 1 misiąc do przodu
  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  //funkcja build rysuje tylko to co widać na ekranie
  @override
  Widget build(BuildContext context) {
    final budget = _currentBudget;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          //pasek wyboru miesiąca
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppColors.monthBar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //strzałka w lewo
              children: [
                IconButton(
                  onPressed: _previusMonth,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 32,
                    color: AppColors.appBarText,
                  ),
                ),
                //Nazwa miesiąca i rok
                Text(
                  '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appBarText,
                  ),
                ),
                //Strzalka w prawo
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 32,
                    color: AppColors.appBarText,
                  ),
                ),
              ],
            ),
          ),
          //Reszta ekranu pod paskiem
          Expanded(
            child: !budget.isdBudgetSet
                ? _buildEmptyMonthCard()
                : _buildActiveMonthView(budget),
          ),
        ],
      ),
    );
  }

  //wywołanie okienka wpisania budzetu
  void _showSetBudgetDialog() {
    final controller = TextEditingController(
      text: _currentBudget.initialBudget?.toStringAsFixed(2) ?? '', //jesli budzet jest wpisany pokaz go w polu w przeciwnym razie pole bedzie puste (nasza kwota bedzie zawsze miala 2 miejsca po przecinku)
    );
    String? _errorMessage;
    //funkcja fluttera do pop-up na srodku ekranu
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.monthBar,
              title: Text(
                'Budżet na ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(color: AppColors.appBarText),
                    controller: controller, //podpiecie kontrolera
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ), //otworzy sie typ klawiatury z cyframi ulatwiajac wpisywanie kwot
                    autofocus: true, //od razu po otwarciu okna wysun klawiature
                    decoration: InputDecoration(
                      labelText: 'Wielkość budżetu',
                      labelStyle: const TextStyle(color: AppColors.sub_text),
                      floatingLabelStyle: const TextStyle(color: Colors.white),
                      border: const OutlineInputBorder(),
                      suffixText: 'PLN', //staly dopisek na koncu pola
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.appBarText,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                  ),
                  onPressed: () => Navigator.pop(context), //zamykamy okno
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(color: AppColors.appBarText),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                  ),
                  //co sie dzieje po kliknięciu zapisz
                  onPressed: () {
                    final input = controller.text.replaceAll(',', '.'); //podmienia przecinek na programistyczna kropke by uniknac bledów
                    final amount = double.tryParse(input); //zamieniamy tekst na liczbe double(jesli ktos wpisze np 'abc' to null wiec apka nie pozwoli go zapisac)

                    if (amount != null && amount > 0) {
                      final totalSpends =
                          _currentBudget.totalExpenses +
                          _currentBudget.totalInvestments;

                      if (amount < totalSpends) {
                        setDialogState(() {
                          _errorMessage =
                              'Budżet musi wynosić minimum ${totalSpends.toStringAsFixed(2)} PLN';
                        });
                        return;
                      }

                      setState(() {
                        _currentBudget.initialBudget = amount;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    ); //przyciski na dole okienk
  }

  //funkcja wysuwajaca panel dodania transakcji z dolu ekranu
  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, //panel moze zajac wiecej miejsca na ekranie (np przy wysunieciu klawiatury)
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ), //zaokraglone gorne rogi panelu
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom, //podnosi zawartość panelu o wysokość klawiatury tel
            left: 24,
            right: 24,
            top: 24,
          ),
          child: AddTransactionForm(
            availableFunds: _currentBudget.freeFunds,
            onSave: (title, price, category) {
              //obiekt nowej transakcji
              final newTx = BudgetTransaction(
                id: DateTime.now()
                    .toString(), //unikalne Id to dokładna data transakcji
                title: title,
                price: price,
                subCategory: category,
                date: DateTime.now(),
              );
              setState(() {
                _currentBudget.transactions.add(newTx);
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  //Funkcja rysująca lewy wykres
  Widget _buildMainChart(MonthlyBudget budget) {
    return SizedBox(
      height:
          220, //ograniczamy wysokosc by zysk nie rozjechal sie na caly ekran
      child: PieChart(
        PieChartData(
          //glowne ustawienia wykresu
          sectionsSpace: 4, //niewielki pusty odstep miedzy wycinkami
          centerSpaceRadius: 40, //Dziura w śroku koła (wykres pierścieniowy)
          sections: [
            //wolne srodki
            if (budget.freeFunds >
                0) //wykres nie probuje rysowac pustych kawalkow
              PieChartSectionData(
                value: budget.freeFunds,
                color: AppColors.freeFunds,
                radius: 50, //grubosc pierscienia
                // Obliczamy procent: (Wartość / Cały budżet) * 100
                title:
                    '${(budget.freeFunds / budget.initialBudget! * 100).toStringAsFixed(0)}%', //usuwamy miejsca po przecinku z obliczeń
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            //wydane srodki
            if (budget.totalExpenses >
                0) //wykres nie probuje rysowac pustych kawalkow
              PieChartSectionData(
                value: budget.totalExpenses,
                color: AppColors.expense,
                radius: 50, //grubosc pierscienia
                // Obliczamy procent: (Wartość / Cały budżet) * 100
                title:
                    '${(budget.totalExpenses / budget.initialBudget! * 100).toStringAsFixed(0)}%', //usuwamy miejsca po przecinku z obliczeń
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            //zainwestowane srodki
            if (budget.totalInvestments >
                0) //wykres nie probuje rysowac pustych kawalkow
              PieChartSectionData(
                value: budget.totalInvestments,
                color: AppColors.investment,
                radius: 50, //grubosc pierscienia
                // Obliczamy procent: (Wartość / Cały budżet) * 100
                title:
                    '${(budget.totalInvestments / budget.initialBudget! * 100).toStringAsFixed(0)}%', //usuwamy miejsca po przecinku z obliczeń
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  //Funkcja rysująca prawy wykres
  Widget _buildSubCategoryChart(MonthlyBudget budget) {
    final totals = budget.subCategoryTotals;

    if (totals.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Dodaj pierwszą transakcję.',
            style: TextStyle(color: AppColors.appBarText),
          ),
        ),
      );
    }

    final totalSpent = budget.totalExpenses + budget.totalInvestments;

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: totals.entries.map((entry) {
            final category = entry.key; //podkategoria
            final amount = entry.value; //wydane srodki
            final percentage =
                (amount / totalSpent) *
                100; //jaki % wydatkow to dana podkategoria

            return PieChartSectionData(
              value: amount,
              color: category.color,
              radius: 50,
              title: '${percentage.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  //wykres + legenda
  Widget _buildActiveMonthView(MonthlyBudget budget) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Budżet: ${budget.initialBudget!.toStringAsFixed(2)} PLN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.appBarText,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showSetBudgetDialog,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.appBarText,
                  size: 26,
                ),
              ),
            ],
          ),
          //napis z calkowitym budzetem

          const SizedBox(height: 24),

          //Przełącznik wykresów
          SegmentedButton<int>(
            //Wyłączenie ikony ptaszka, dzięki czemu przycisk nie zmienia rozmiaru
            showSelectedIcon: false,

            style: ButtonStyle(
              // Tło przycisków w zależności od stanu
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  // Zaznaczony: półprzezroczysta biel (efekt oszronionego szkła)
                  return Colors.white.withValues(alpha: 0.15);
                }
                // Niezaznaczony: całkowicie przezroczysty
                return Colors.transparent;
              }),
              // Kolor tekstu
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white; // Mocna biel dla wybranego
                }
                return Colors.white.withValues(
                  alpha: 0.5,
                ); // Przygaszona biel dla niewybranego
              }),
              // Delikatna, półprzezroczysta ramka wokół całego przełącznika
              side: WidgetStateProperty.all(
                BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            segments: const [
              ButtonSegment(
                value: 0,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Ogólny'),
                ),
              ),
              ButtonSegment(
                value: 1,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Szczegółowy'),
                ),
              ),
            ],
            selected: {_currentChartIndex},
            onSelectionChanged: (newSelection) {
              setState(() {
                _currentChartIndex = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _showAddTransactionSheet,
            icon: const Icon(Icons.add, color: AppColors.appBarText),
            label: const Text(
              'Dodaj transakcję',
              style: TextStyle(color: AppColors.appBarText, fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),

          //Wyswietlamy wykres w zaleznosci od przelacznika
          _currentChartIndex == 0
              ? _buildMainChart(budget)
              : _buildSubCategoryChart(budget),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.sub_text),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showLegendSheet(budget),
                  child: const Text(
                    'Legenda i kwoty',
                    style: TextStyle(color: AppColors.appBarText, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.sub_text),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showHistorySheet(budget),
                  child: const Text(
                    'Historia transakcji',
                    style: TextStyle(color: AppColors.appBarText, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //funkcja pomocnicza do rysowania pojedynczego wiersza legendy
  Widget _buildLegendsRow(String title, double price, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 8,
            ), //mala kropka w kolorze danej kategorii
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: AppColors.appBarText),
            ),
          ],
        ),
        Text(
          '${price.toStringAsFixed(2)} PLN',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.appBarText,
          ),
        ),
      ],
    );
  }

  // Panel wysuwany z legendą
  void _showLegendSheet(MonthlyBudget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryButton,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Szary uchwyt
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Legenda i kwoty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appBarText,
                  ),
                ),
                const SizedBox(height: 24),

                Flexible(
                  child: SingleChildScrollView(
                    child: _currentChartIndex == 0
                        ? Column(
                            children: [
                              _buildLegendsRow(
                                'Wolne Środki',
                                budget.freeFunds,
                                AppColors.freeFunds,
                              ),
                              const Divider(height: 24),
                              _buildLegendsRow(
                                'Wydatki',
                                budget.totalExpenses,
                                AppColors.expense,
                              ),
                              const Divider(height: 24),
                              _buildLegendsRow(
                                'Inwestycje',
                                budget.totalInvestments,
                                AppColors.investment,
                              ),
                            ],
                          )
                        : Column(
                            children: budget.subCategoryTotals.entries.map((
                              entry,
                            ) {
                              return Column(
                                children: [
                                  _buildLegendsRow(
                                    entry.key.label,
                                    entry.value,
                                    entry.key.color,
                                  ),
                                  const Divider(height: 24),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Panel wysuwany z historią transakcji
  void _showHistorySheet(MonthlyBudget budget) {
    final Set<String> selectedTransaction = {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pozwala panelowi zająć więcej miejsca
      backgroundColor: AppColors.primaryButton,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // DraggableScrollableSheet pozwala płynnie przewijać długą listę wewnątrz panelu
        return StatefulBuilder(
          //pozwala zaznaczać transakcje bez zamykania panelu
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6, // Panel zajmie na start 60% ekranu
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Historia transakcji',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.appBarText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Przewijana lista z transakcjami
                      Expanded(
                        child: budget.transactions.isEmpty
                            ? const Center(
                                child: Text(
                                  'Brak wpisów w tym miesiącu.',
                                  style: TextStyle(color: AppColors.sub_text),
                                ),
                              )
                            : ListView(
                                controller:
                                    scrollController, // Podpinamy przewijanie
                                children: budget.transactions.reversed.map((
                                  tx,
                                ) {
                                  final isSelected = selectedTransaction
                                      .contains(tx.id);
                                  return Card(
                                    color: isSelected
                                        ? AppColors.expense.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.monthBar,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.expense
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        setSheetState(() {
                                          if (isSelected) {
                                            selectedTransaction.remove(tx.id);
                                          } else {
                                            selectedTransaction.add(tx.id);
                                          }
                                        });
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: tx.subCategory.color,
                                        radius: 12,
                                      ),
                                      title: Text(
                                        tx.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.appBarText,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${tx.date.day}.${tx.date.month}.${tx.date.year}',
                                        style: const TextStyle(
                                          color: AppColors.sub_text,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: AppColors.expense,
                                            )
                                          : Text(
                                              '${tx.price.toStringAsFixed(2)} PLN',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.appBarText,
                                              ),
                                            ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      if (selectedTransaction.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.expense,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(
                              double.infinity,
                              50,
                            ), // Rozciąga przycisk na całą szerokość
                          ),
                          onPressed: () {
                            // setState ekranu głównego przelicza wykresy i usuwa transakcje z modelu
                            setState(() {
                              budget.transactions.removeWhere(
                                (tx) => selectedTransaction.contains(tx.id),
                              );
                            });
                            // setSheetState odświeża sam panel (ukrywa przycisk usuwania)
                            setSheetState(() {
                              selectedTransaction.clear();
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Usuń (${selectedTransaction.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyMonthCard() {
    return Center(
      child: SingleChildScrollView(
        child: Card(
          //widzet z zaokraglonymi rogami i cieniem
          margin: const EdgeInsets.all(24), //odpycha karte od krawedzi telfonu
          elevation: 10, //wielkosc cienia pod kartą (efekt 3D)
          color: AppColors.primaryButton,
          child: Padding(
            padding: const EdgeInsets.all(
              32,
            ), //odpycha napis i ikone od krawedzi karty
            child: Column(
              mainAxisSize: MainAxisSize.min, //karta ma być tak wysoka jak jej zawartosc nie na caly ekran
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppColors.appBarText,
                ),
                const SizedBox(height: 16), //pusty odstęp (w pionie bo collumn)
                Text(
                  'Brak budżetu na ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appBarText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zacznij od określenia kwoty, jaką dysponujesz w tym miesiącu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.sub_text),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pageBackground,
                  ),
                  onPressed: _showSetBudgetDialog,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Dodaj budżet na ten miesiąc',
                    style: TextStyle(color: AppColors.appBarText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddTransactionForm extends StatefulWidget {
  final double availableFunds;
  final Function(String, double, SubCategory)
  onSave; //funkcja ktora przekaze zebrane dane do glownego ekranu
  const AddTransactionForm({
    super.key,
    required this.availableFunds,
    required this.onSave,
  });

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  SubCategory?
  _selectedCategory; //na poczatku kategoria nie jest wybrana wiec jest null
  String? _errorMessage;

  // Panel do wyboru kategorii z wyszukiwarką
  void _showCategoryPicker() {
    String searchQuery = ''; // Zmienna przechowująca wpisywany tekst

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pozwala panelowi zająć więcej miejsca
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Filtrowanie kategorii na żywo (ignoruje wielkość liter)
            final filteredCategories = SubCategory.values.where((cat) {
              return cat.label.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom, //zabezpieczenie by klawiatura nie zaslonila listy
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pole wyszukiwarki na samej górze
                      TextField(
                        autofocus: true, // Automatycznie otwiera klawiaturę
                        style: const TextStyle(color: AppColors.appBarText),
                        decoration: const InputDecoration(
                          hintText: 'Wyszukaj kategorię...',
                          hintStyle: TextStyle(color: AppColors.sub_text),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.sub_text,
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.appBarText,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wygenerowana, przefiltrowana lista wyników
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color,
                                radius: 8,
                              ),
                              title: Text(
                                category.label,
                                style: const TextStyle(
                                  color: AppColors.appBarText,
                                ),
                              ),
                              onTap: () {
                                // Główny setState formularza, by zapisać wybór
                                setState(() {
                                  _selectedCategory = category;
                                });
                                Navigator.pop(context); // Zamknięcie panelu
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _submitData() {
    final title = _titleController.text;
    final priceText = _priceController.text.replaceAll(',', '.');
    final price = double.tryParse(priceText);

    setState(() {
      _errorMessage = null;
    });

    if (title.isEmpty ||
        price == null ||
        price <= 0 ||
        _selectedCategory == null) {
      return;
    }

    if (price > widget.availableFunds) {
      setState(() {
        _errorMessage = 'Brak wolnych środków na koncie';
      });
      return;
    }
    //jesli wszystko jest poprawnie wysyłamy dane w góre(do HomeScreen)
    widget.onSave(title, price, _selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.stretch, //rozciaga przycisk na cala szerokosc
      children: [
        //maly szary uchwyt
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Nowa Transakcja',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.appBarText,
          ),
        ),
        const SizedBox(height: 24),

        //pole nazwy transakcji
        TextField(
          controller: _titleController,
          style: const TextStyle(color: AppColors.appBarText),
          decoration: const InputDecoration(
            labelText: 'Krótki opis transakcji',
            labelStyle: TextStyle(color: AppColors.sub_text),
            floatingLabelStyle: TextStyle(color: AppColors.appBarText),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.appBarText, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        //Pole kwoty
        TextField(
          controller: _priceController,
          style: const TextStyle(color: AppColors.appBarText),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Kwota (zł)',
            labelStyle: TextStyle(color: AppColors.sub_text),
            floatingLabelStyle: TextStyle(color: AppColors.appBarText),
            border: OutlineInputBorder(),
            suffixText: 'PLN',
            suffixStyle: TextStyle(color: AppColors.appBarText),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.appBarText, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rozwijana lista z podkategoriami
        InkWell(
          onTap: _showCategoryPicker,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Wybierz kategorię transakcji',
              labelStyle: TextStyle(color: AppColors.sub_text),
              floatingLabelStyle: TextStyle(color: AppColors.appBarText),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Jeśli nic nie wybrano, pokaż tekst zastępczy. Jeśli wybrano - pokaż kolor i nazwę.
                if (_selectedCategory == null)
                  const Text(
                    'Kliknij, by wyszukać...',
                    style: TextStyle(color: AppColors.sub_text),
                  )
                else
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _selectedCategory!.color,
                        radius: 8,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedCategory!.label,
                        style: const TextStyle(color: AppColors.appBarText),
                      ),
                    ],
                  ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.sub_text,
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        //komunikat błędu
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        //przycisk zapisu
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.monthBar,
          ),
          onPressed: _submitData,
          child: const Text(
            'Dodaj transakcję',
            style: TextStyle(fontSize: 16, color: AppColors.appBarText),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
