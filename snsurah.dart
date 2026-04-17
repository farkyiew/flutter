import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tafsir/config/loading.dart';
import 'package:tafsir/design/design.dart';

import 'package:tafsir/todb.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class SnaraiSurah extends StatefulWidget {
  const SnaraiSurah({super.key});

  @override
  State<SnaraiSurah> createState() => _SnaraiSurahState();
}

class _SnaraiSurahState extends State<SnaraiSurah> {
  static const _pageSize = 20;

  String _searchQuery = '';
  Timer? _debounce;

  final PagingController<int, Surah> _pagingController = PagingController(
    firstPageKey: 0,
  );

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final List? newItems = await getListData('/sn_surah_c', {
        "muka": pageKey + 1, // Backend menjangkakan 'muka' (1-based index)
        "limit": _pageSize,
        "tapis": _searchQuery,
        "data1": "data",
        "data2": "data2",
      });

      // Jika anda ingin melakukan filter di peringkat API, hantar _searchQuery ke backend.
      // Jika filter local, kita tapis list sebelum append.

      if (!mounted) return;

      // Tukar List<Map> kepada List<Surah>
      final List<Surah> quranObjects = (newItems ?? [])
          .map((item) => Surah.fromMap(item as Map<String, dynamic>))
          .toList();

      // Filter data secara lokal jika ada carian
      List<Surah> filteredItems = quranObjects;
      if (_searchQuery.isNotEmpty) {
        final searchInt = int.tryParse(_searchQuery);
        filteredItems = quranObjects.where((val) {
          final matchNama =
              val.nama?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false;
          final matchNo = searchInt != null && (val.noSurah ?? 0) >= searchInt;
          return matchNama || matchNo;
        }).toList();
      }

      // Memandangkan surah cuma ada 114, kita anggap semua dimuatkan sekaligus
      // Jika menggunakan pagination sebenar, logik isLastPage perlu diselaraskan
      final isLastPage = (newItems?.length ?? 0) < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(filteredItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(filteredItems, nextPageKey);
      }

      if (mounted) {
        final pvdsurah = Provider.of<Surah>(context, listen: false);
        // Kemaskini list di Provider supaya seiring dengan PagingController
        pvdsurah.updateData(_pagingController.itemList ?? []);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final pvdsurah = Provider.of<Surah>(context); // Tidak perlu listen di sini jika guna PagingController
    return Scaffold(
      appBar: AppBar(title: const Text("Tajuk")),
      body: Column(
        children: [
          Consumer<Surah>(
            builder: (context, data, index) {
              return Column(
                children: [
                  // if (myClass.papar == true)
                  Container(
                    //color: Colors.blue,
                    decoration: wrpCari,
                    // margin: paddCarian,
                    child: TextField(
                      // decoration: txtCari,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            _searchQuery = value;
                            _pagingController
                                .refresh(); // Panggil semula _fetchPage selepas delay
                          }
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: PagedGridView<int, Surah>(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Menentukan 2 kolom
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8, // Perbandingan lebar dan tinggi kotak
              ),
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<Surah>(
                itemBuilder: (context, data, index) => Card(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${data.noSurah}"),
                        Text(
                          "${data.nama}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                firstPageProgressIndicatorBuilder: (_) => const Loading(),
                noItemsFoundIndicatorBuilder: (_) =>
                    const Center(child: Text('Tiada data')),
              ),
            ),
            // child: PagedListView<int, Surah>(
            //   pagingController: _pagingController,
            //   builderDelegate: PagedChildBuilderDelegate<Surah>(
            //     itemBuilder: (context, data, index) => ListTile(
            //       leading: CircleAvatar(child: Text("${data.noSurah}")),
            //       title: Text(
            //         "${data.nama}",
            //         style: const TextStyle(fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //     firstPageProgressIndicatorBuilder: (_) => const Loading(),
            //     noItemsFoundIndicatorBuilder: (_) =>
            //         const Center(child: Text('Tiada data')),
            //   ),
            // ),
          ),
        ],
      ),
    );
  }
}

class Surah extends ChangeNotifier {
  dynamic surah;
  List? surahs; // Senarai untuk dipaparkan
  List? filteredList; // = [];
  List<Surah> _allData = []; // Simpan data asal di sini
  String? nama;
  int? noSurah;

  Surah({this.surah, this.surahs, this.nama, this.noSurah, this.filteredList});

  // Fungsi untuk menukar Map dari API kepada Objek Surah
  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      noSurah: map['noSurah'] is int
          ? map['noSurah']
          : int.tryParse(map['noSurah'].toString()) ?? 0,
      nama: map['nama'] ?? 'N/A',
    );
  }

  // Dipanggil apabila data baru dimuatkan dari API
  void updateData(List<Surah> newItems) {
    _allData = newItems;
    surahs = List.from(_allData);
    notifyListeners();
  }

  void assignData(String inputText) async {

    if (surahs == null) return;

    final searchInt = int.tryParse(inputText);

    filteredList = surahs!.map((val) {
          return Surah(nama: val["nama"] ?? '', noSurah: val["noSurah"]);
        })
        .where((val) {
          final matchnama = val.nama!.toLowerCase().contains(
            inputText.toLowerCase(),
          );
          // Hanya buat perbandingan nombor jika input adalah nombor yang sah
          final matchNo =
              searchInt != null &&
              val.noSurah != null &&
              val.noSurah! >= searchInt;
          return matchnama || matchNo;
        })
        .toList();

    print('filteredList!.length:  ${filteredList!.length}');

    notifyListeners();
  }
}
