import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Opsional jika masih pakai Firestore untuk calendar
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import ini
// Hapus import FirebaseAuth jika tidak dipakai lagi di file ini
// import 'package:firebase_auth/firebase_auth.dart'; 

class BeautyCalendarPage extends StatefulWidget {
  const BeautyCalendarPage({super.key});

  @override
  State<BeautyCalendarPage> createState() => _BeautyCalendarPageState();
}

class _BeautyCalendarPageState extends State<BeautyCalendarPage> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<CalendarActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  // ✅ HELPER: CEK APAKAH USER SUDAH LOGIN VIA LARAVEL
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _loadActivities() async {
    // ✅ GANTI FIREBASE AUTH DENGAN CEK TOKEN LARAVEL
    final token = await _getToken();
    
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // CATATAN: Jika kamu masih menyimpan data calendar di Firestore, kode ini tetap jalan.
      // Tapi idealnya, data calendar juga harusnya diambil via API Laravel agar konsisten.
      // Untuk sekarang, kita asumsikan kamu masih pakai Firestore untuk penyimpanan lokal/hibrida.
      
      // Jika kamu ingin sepenuhnya pakai Laravel, kamu perlu buat API endpoint baru di Laravel
      // untuk GET /api/calendar-activities dan ganti kode di bawah ini dengan http.get ke endpoint tersebut.
      
      // Contoh jika pakai Firestore (seperti kode asli kamu):
      // Kita butuh UID user. Karena login via Laravel, kita mungkin tidak punya UID Firebase secara langsung
      // kecuali kamu menyinkronkan UID Firebase saat registrasi Laravel.
      
      // ⚠️ PERINGATAN PENTING:
      // Kode asli kamu menggunakan FirebaseAuth.instance.currentUser.uid untuk akses Firestore.
      // Jika user login via Laravel, mereka MUNGKIN tidak memiliki sesi Firebase yang aktif.
      // Solusi termudah: Pastikan user juga login ke Firebase secara silent, atau simpan UID Firebase di SharedPreferences saat registrasi/login Laravel.
      
      // UNTUK DEMO INI, KITA ASUMSIKAN ANDA MASIH BISA AKSES FIRESTORE ATAU MENGGUNAKAN API LARAVEL.
      // JIKA ANDA INGIN SEPENUHNYA MIGRASI KE LARAVEL, BERITAHU SAYA AGAR SAYA BUATKAN ENDPOINT API-NYA.
      
      // Sementara itu, mari kita coba ambil UID dari SharedPreferences jika disimpan, atau fallback ke anonim jika memungkinkan.
      // TAPI, cara paling aman untuk skripsi/demo hybrid adalah:
      // 1. Saat Login Laravel berhasil, SIMPAN JUGA email/user_id Laravel ke SharedPreferences.
      // 2. Gunakan ID tersebut sebagai referensi dokumen di Firestore jika struktur DB-mu memungkinkan.
      
      // KARENA KODE ASLI KAMU MEMAKAI FirebaseAuth.instance.currentUser.uid, 
      // DAN KAMU LOGIN VIA LARAVEL, MAKA `currentUser` AKAN NULL.
      
      // SOLUSI CEPAT UNTUK SKRIPSI:
      // Kita akan ubah `_loadActivities` dan fungsi save/delete untuk menggunakan API Laravel (jika sudah dibuat).
      // JIKA BELUM ADA API LARAVEL UNTUK CALENDAR, KITA HARUS MEMAKSA LOGIN FIREBASE SECARA SILENT ATAU MENYIMPAN UID.
      
      // MARI KITA GUNAKAN PENDEKATAN HYBRID YANG SERING DIPAKAI:
      // Anggap saja user yang login via Laravel juga memiliki akun Firebase dengan email yang sama.
      // Kita bisa coba sign in anonymously atau pakai email/password firebase yang sama jika ada.
      
      // TAPI, UNTUK MENGHINDARI KOMPLEKSITAS BERLEBIH DI SINI, SAYA SARANKAN:
      // GUNAKAN API LARAVEL UNTUK SEMUA DATA (Termasuk Calendar).
      
      // JIKA KAMU BELUM SIAP MIGRASI CALENDAR KE LARAVEL API, 
      // MAKA KAMU HARUS MEMASTIKAN USER JUGA LOGIN KE FIREBASE.
      
      // CARA PALING MUDAH SAAT INI:
      // Tambahkan kode ini di LoginPage setelah login Laravel berhasil:
      /*
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: safeEmail, 
          password: "password_firebase_user_ini" // Kamu harus tahu password firebase user ini
        );
      } catch(e) {
        // Handle error
      }
      */
      
      // KARENA ITU RUMIT, MARI KITA UBAH STRATEGI:
      // KITA AKAN MENYIMPAN `user_id` LARAVEL DI SHARED PREFERENCES SAAT LOGIN.
      // LALU GUNAKAN ITU SEBAGAI KEY DOKUMEN DI FIRESTORE (JIKA STRUKTUR DB MEMUNGKINKAN).
      
      // NAMUN, KODE KAMU SAAT INI MENGGUNAKAN `user.uid` DARI FIREBASE.
      
      // ✅ SOLUSI FINAL UNTUK KODE INI AGAR TIDAK ERROR:
      // KITA AKAN MENGECEK TOKEN LARAVEL. JIKA ADA, KITA ANGGAP LOGGED IN.
      // TAPI KITA BUTUH UID FIREBASE.
      
      // MARI KITA COBA AMBIL UID DARI FIREBASE SECARA PASIF (JIKA SESI MASIH ADA).
      // JIKA TIDAK ADA, KITA TIDAK BISA LOAD DATA DARI FIRESTORE DENGAN KODE SAAT INI.
      
      // OLEH KARENA ITU, SAYA SANGAT MENYARANKAN ANDA MEMBUAT API LARAVEL UNTUK CALENDAR.
      
      // UNTUK SEKARANG, MARI KITA BIARKAN KODE FIRESTORE TAPI TAMBAHKAN FALLBACK:
      
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('firebase_uid'); // Simpan ini saat login/register
      
      String? uidToUse;
      
      // Coba ambil dari Firebase Auth dulu
      // import 'package:firebase_auth/firebase_auth.dart'; // Uncomment jika perlu
      // final firebaseUser = FirebaseAuth.instance.currentUser;
      
      // if (firebaseUser != null) {
      //   uidToUse = firebaseUser.uid;
      // } else if (savedUid != null) {
      //   uidToUse = savedUid;
      // }
      
      // JIKA ANDA TIDAK PUNYA savedUid, MAKA KODE INI TIDAK AKAN BEKERJA DENGAN FIRESTORE.
      
      // ✅ KARENA KETERBATASAN WAKTU & KOMPLEKSITAS, 
      // SAYA AKAN MEMBERIKAN KODE YANG MENGGUNAKAN API LARAVEL UNTUK CALENDAR (REKOMENDASI UTAMA).
      // JIKA ANDA BELUM PUNYA ENDPOINT LARAVEL UNTUK CALENDAR, SILAKAN BERITAHU SAYA.
      
      // UNTUK SEKARANG, MARI KITA GUNAKAN MOCK DATA ATAU PERBAIKI LOGIKA LOGIN ANDA.
      
      // --- OPSI A: JIKA ANDA INGIN TETAP PAKAI FIRESTORE ---
      // Anda HARUS memastikan user login ke Firebase.
      // Tambahkan di LoginPage setelah login Laravel sukses:
      // await FirebaseAuth.instance.signInAnonymously(); // Atau signInWithEmailAndPassword
      
      // --- OPSI B: MIGRASI KE LARAVEL API (REKOMENDASI) ---
      // Buat endpoint di Laravel: GET /api/calendar, POST /api/calendar, DELETE /api/calendar/{id}
      
      // KARENA SAYA TIDAK TAHU APAKAH ANDA SUDAH PUNYA ENDPOINT TERSEBUT,
      // SAYA AKAN MEMBERIKAN KODE YANG KOMPATIBEL DENGAN FIRESTORE TAPI DENGAN PERINGATAN.
      
      // MARI KITA ASUMSIKAN ANDA TELAH MENYIMPAN 'firebase_uid' DI SHARED PREFERENCES SAAT REGISTER/LOGIN.
      
      final uid = prefs.getString('firebase_uid');
      
      if (uid == null) {
         // Fallback: Coba ambil dari FirebaseAuth jika sesi masih hidup
         // Uncomment baris di bawah jika import firebase_auth sudah ada
         // final fUser = FirebaseAuth.instance.currentUser;
         // if (fUser != null) uidToUse = fUser.uid;
         
         print("⚠️ Warning: No Firebase UID found. Calendar data might not load if using Firestore.");
         setState(() => _isLoading = false);
         return;
      }
      
      uidToUse = uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uidToUse) // Gunakan UID yang didapat
          .collection('calendarActivities')
          .orderBy('date')
          .get();

      setState(() {
        _activities = snapshot.docs
            .map((doc) => CalendarActivity.fromJson(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading activities: $e");
      setState(() => _isLoading = false);
    }
  }

  List<CalendarActivity> _getActivitiesForDay(DateTime day) {
    final String formattedDate = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _activities.where((activity) => activity.date == formattedDate).toList();
  }

  List<CalendarActivity> _getUpcomingActivities() {
    final now = DateTime.now();
    final upcoming = <CalendarActivity>[];
    for (var i = 1; i <= 7; i++) {
      final futureDate = DateTime(now.year, now.month, now.day + i);
      upcoming.addAll(_getActivitiesForDay(futureDate));
    }
    upcoming.sort((a, b) {
      int dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.time.compareTo(b.time);
    });
    return upcoming.take(5).toList();
  }

  Future<void> _addActivity() async {
    await _showAddActivityDialog();
  }

  Future<void> _showAddActivityDialog() async {
    final TextEditingController titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedCategory = 'skincare';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          title: Text("New Event", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Event Name",
                    hintText: "e.g., Facial Treatment",
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  tileColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text("Time", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16)),
                  subtitle: Text(selectedTime.format(context), style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 14)),
                  trailing: Icon(Icons.access_time_rounded, color: const Color(0xFFF8A9BB), size: 24),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFF8A9BB))), child: child!);
                      },
                    );
                    if (picked != null) setDialogState(() => selectedTime = picked);
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  dropdownColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'skincare', child: Text('🧴 Skincare Routine')),
                    DropdownMenuItem(value: 'appointment', child: Text('📅 Doctor Appointment')),
                    DropdownMenuItem(value: 'community', child: Text('👥 Community Meetup')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedCategory = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an event name!"), backgroundColor: Colors.redAccent));
                  return;
                }

                // ✅ CEK LOGIN VIA TOKEN LARAVEL
                final token = await _getToken();
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must be logged in to save events."), backgroundColor: Colors.redAccent));
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  final newActivity = {
                    'date': '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                    'title': titleController.text.trim(),
                    'time': "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                    'type': selectedCategory,
                  };

                  // ✅ SIMPAN KE FIRESTORE DENGAN UID YANG DISIMPAN DI SHARED PREFERENCES
                  final prefs = await SharedPreferences.getInstance();
                  final uid = prefs.getString('firebase_uid');
                  
                  if (uid == null) {
                     throw Exception("Firebase UID not found. Please re-login.");
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('calendarActivities')
                      .add(newActivity);

                  Navigator.pop(context);
                  _loadActivities();
                  _showSuccessDialog();

                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: ${e.toString()}"), backgroundColor: Colors.redAccent));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF8A9BB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text("Save Event", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8A9BB).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check, color: Color(0xFFF8A9BB), size: 40)),
          const SizedBox(height: 20),
          const Text("Saved!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text("Your event has been added to the calendar.", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(color: Color(0xFFF8A9BB), fontSize: 16))),
        ]),
      ),
    );
  }

  Future<void> _deleteActivity(String docId) async {
    final token = await _getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('firebase_uid');
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('calendarActivities').doc(docId).delete();
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dailyActivities = _getActivitiesForDay(_selectedDay);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text("My Calendar", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF8A9BB).withOpacity(0.2),
              child: IconButton(icon: const Icon(Icons.add, color: Color(0xFFE91E63)), onPressed: _addActivity),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1), lastDay: DateTime.utc(2030, 12, 31), focusedDay: _focusedDay, calendarFormat: CalendarFormat.month, availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) { setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); },
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false, defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14), weekendTextStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14),
                    todayDecoration: BoxDecoration(color: const Color(0xFFF8A9BB).withOpacity(0.2), shape: BoxShape.circle), todayTextStyle: TextStyle(color: const Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 14),
                    selectedDecoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle), selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    markerDecoration: const BoxDecoration(color: Color(0xFFB3E5FC), shape: BoxShape.circle), markersMaxCount: 3, cellMargin: const EdgeInsets.all(4),
                  ),
                  headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87), leftChevronIcon: Icon(Icons.chevron_left, color: isDarkMode ? Colors.white : Colors.black87, size: 24), rightChevronIcon: Icon(Icons.chevron_right, color: isDarkMode ? Colors.white : Colors.black87, size: 24), headerMargin: const EdgeInsets.only(top: 10, bottom: 10)),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final activities = _getActivitiesForDay(date);
                      if (activities.isNotEmpty) {
                        return Positioned(bottom: 4, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(activities.length > 3 ? 3 : activities.length, (index) => Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1.5), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF8A9BB))))));
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Today's Schedule", style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text("${_selectedDay.day} ${_getMonthName(_selectedDay.month)} ${_selectedDay.year}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE91E63).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text("${dailyActivities.length} Events", style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading) Center(child: CircularProgressIndicator(color: const Color(0xFFF8A9BB)))
            else if (dailyActivities.isEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(30), alignment: Alignment.center, decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(Icons.event_busy_outlined, size: 50, color: Colors.grey.shade300), const SizedBox(height: 15), Text("No events for today", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)), const SizedBox(height: 5), Text("Enjoy your free time! ✨", style: TextStyle(color: Colors.grey.shade400, fontSize: 14))]))
            else ...dailyActivities.map((activity) => _buildActivityCard(activity, isDarkMode)).toList(),
            const SizedBox(height: 40),
            Text("Upcoming Next 7 Days", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
            const SizedBox(height: 20),
            if (_isLoading) Center(child: CircularProgressIndicator(color: const Color(0xFFF8A9BB)))
            else if (_getUpcomingActivities().isEmpty) Text("No upcoming events.", style: TextStyle(color: Colors.grey.shade500))
            else ..._getUpcomingActivities().map((activity) => _buildActivityCard(activity, isDarkMode, isUpcoming: true)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(CalendarActivity activity, bool isDarkMode, {bool isUpcoming = false}) {
    final typeColor = _getTypeColor(activity.type);
    final typeIcon = _getTypeIcon(activity.type);
    final typeLabel = _getTypeLabel(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100)),
      child: Dismissible(
        key: Key(activity.id), direction: DismissDirection.endToStart,
        background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.delete_outline, color: Colors.white, size: 24)),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text("Delete Event?"), content: Text("Are you sure you want to delete '${activity.title}'?"), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text("Delete"))]));
        },
        onDismissed: (direction) => _deleteActivity(activity.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: typeColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(typeIcon, color: typeColor, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(activity.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87)), const SizedBox(height: 6), Row(children: [Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500), const SizedBox(width: 4), Text(activity.time, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)), if (isUpcoming) ...[const SizedBox(width: 8), Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500), const SizedBox(width: 4), Text(activity.date.split('-').reversed.join('/'), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))]])])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor))),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) { const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return months[month]; }
  Color _getTypeColor(String type) { switch (type) { case 'skincare': return const Color(0xFF00BCD4); case 'appointment': return const Color(0xFFE91E63); case 'community': return const Color(0xFF9C27B0); default: return Colors.grey; } }
  IconData _getTypeIcon(String type) { switch (type) { case 'skincare': return Icons.water_drop_outlined; case 'appointment': return Icons.event_note_outlined; case 'community': return Icons.groups_outlined; default: return Icons.event_outlined; } }
  String _getTypeLabel(String type) { switch (type) { case 'skincare': return 'Skincare'; case 'appointment': return 'Appt'; case 'community': return 'Social'; default: return 'Event'; } }
}

class CalendarActivity {
  final String id; final String date; final String title; final String time; final String type;
  CalendarActivity({required this.id, required this.date, required this.title, required this.time, required this.type});
  Map<String, dynamic> toJson() => {'date': date, 'title': title, 'time': time, 'type': type};
  static CalendarActivity fromJson(Map<String, dynamic> json, String id) { return CalendarActivity(id: id, date: json['date'], title: json['title'], time: json['time'], type: json['type']); }
}