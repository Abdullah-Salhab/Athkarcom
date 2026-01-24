import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManualLocationScreen extends StatefulWidget {
  const ManualLocationScreen({super.key});

  @override
  State<ManualLocationScreen> createState() => _ManualLocationScreenState();
}

class _ManualLocationScreenState extends State<ManualLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // قائمة المدن الأردنية الشهيرة
  final List<Map<String, dynamic>> jordanCities = [
    {'name': 'عمّان', 'lat': 31.9454, 'lng': 35.9284},
    {'name': 'إربد', 'lat': 32.5556, 'lng': 35.8500},
    {'name': 'الزرقاء', 'lat': 32.0833, 'lng': 36.1000},
    {'name': 'العقبة', 'lat': 29.5269, 'lng': 35.0078},
    {'name': 'السلط', 'lat': 32.0333, 'lng': 35.7272},
    {'name': 'المفرق', 'lat': 32.3333, 'lng': 36.2000},
    {'name': 'الكرك', 'lat': 31.1850, 'lng': 35.7044},
    {'name': 'معان', 'lat': 30.1919, 'lng': 35.7342},
    {'name': 'جرش', 'lat': 32.2722, 'lng': 35.8911},
    {'name': 'عجلون', 'lat': 32.3328, 'lng': 35.7517},
    {'name': 'مادبا', 'lat': 31.7167, 'lng': 35.7933},
    {'name': 'الطفيلة', 'lat': 30.8333, 'lng': 35.6000},
  ];

  String? selectedCity;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cityController.text = prefs.getString('prayer_city') ?? '';
      _countryController.text = prefs.getString('prayer_country') ?? 'الأردن';
      final lat = prefs.getDouble('prayer_latitude');
      final lng = prefs.getDouble('prayer_longitude');
      if (lat != null) _latitudeController.text = lat.toString();
      if (lng != null) _longitudeController.text = lng.toString();
    });
  }

  void _selectJordanCity(Map<String, dynamic> city) {
    setState(() {
      selectedCity = city['name'];
      _cityController.text = city['name'];
      _countryController.text = 'الأردن';
      _latitudeController.text = city['lat'].toString();
      _longitudeController.text = city['lng'].toString();
    });
  }

  Future<void> _saveLocation() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prayer_city', _cityController.text.trim());
        await prefs.setString('prayer_country', _countryController.text.trim());
        await prefs.setDouble(
            'prayer_latitude', double.parse(_latitudeController.text));
        await prefs.setDouble(
            'prayer_longitude', double.parse(_longitudeController.text));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                'تم حفظ الموقع بنجاح',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                'خطأ في الحفظ: ${e.toString()}',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدخال الموقع يدوياً',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Jordan Cities Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_city, color: Colors.teal),
                          SizedBox(width: 10),
                          Text(
                            'اختر مدينة أردنية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: jordanCities.map((city) {
                          final isSelected = selectedCity == city['name'];
                          return InkWell(
                            onTap: () => _selectJordanCity(city),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.teal
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                city['name'],
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'أو أدخل الموقع يدوياً',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // City Field
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'المدينة',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المدينة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Country Field
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: 'الدولة',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الدولة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Latitude Field
                TextFormField(
                  controller: _latitudeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'خط العرض (Latitude)',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon: const Icon(Icons.my_location),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    hintText: 'مثال: 31.9454',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال خط العرض';
                    }
                    final lat = double.tryParse(value);
                    if (lat == null || lat < -90 || lat > 90) {
                      return 'قيمة خط العرض غير صحيحة (-90 إلى 90)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Longitude Field
                TextFormField(
                  controller: _longitudeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'خط الطول (Longitude)',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    hintText: 'مثال: 35.9284',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال خط الطول';
                    }
                    final lng = double.tryParse(value);
                    if (lng == null || lng < -180 || lng > 180) {
                      return 'قيمة خط الطول غير صحيحة (-180 إلى 180)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'يمكنك معرفة إحداثيات أي مكان من خلال Google Maps',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Save Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _saveLocation,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'حفظ الموقع',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}