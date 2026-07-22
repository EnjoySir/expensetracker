import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  
  String _fromCurrency = 'USD';
  String _toCurrency = 'ZWG';

  // Base exchange rates relative to 1 USD
  final Map<String, double> _rates = {
    'USD': 1.0,
    'ZWG': 26.5,
    'ZAR': 18.2,
    'EUR': 0.92,
    'GBP': 0.78,
  };

  final List<String> _currencies = ['USD', 'ZWG', 'ZAR', 'EUR', 'GBP'];

  double get _convertedAmount {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fromRate = _rates[_fromCurrency] ?? 1.0;
    final toRate = _rates[_toCurrency] ?? 1.0;
    final amountInUSD = amount / fromRate;
    return amountInUSD * toRate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromSymbol = Helpers.getCurrencySymbol(_fromCurrency);
    final toSymbol = Helpers.getCurrencySymbol(_toCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Amount Input
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount to Convert',
                        prefixText: fromSymbol,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // From & To Selectors
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _fromCurrency,
                            decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
                            items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _fromCurrency = v!),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz, color: Colors.deepPurple, size: 28),
                            onPressed: () {
                              setState(() {
                                final temp = _fromCurrency;
                                _fromCurrency = _toCurrency;
                                _toCurrency = temp;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _toCurrency,
                            decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
                            items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _toCurrency = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Conversion Result Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Converted Value', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    Helpers.formatCurrency(_convertedAmount, symbol: toSymbol),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 $_fromCurrency = ${(_rates[_toCurrency]! / _rates[_fromCurrency]!).toStringAsFixed(4)} $_toCurrency',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
