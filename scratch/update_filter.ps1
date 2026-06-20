$files = @(
    "c:\Users\archana\OneDrive\Desktop\z01\z01\lib\screens\equipment\equipment_list_screen.dart",
    "c:\Users\archana\OneDrive\Desktop\z01\z01\lib\screens\manpower\manpower_list_screen.dart",
    "c:\Users\archana\OneDrive\Desktop\z01\z01\lib\screens\studio\studio_list_screen.dart"
)

foreach ($file in $files) {
    $content = Get-Content -Path $file -Raw

    # Update modal backgrounds
    $content = $content -replace 'backgroundColor: const Color\(0xFF1C1C2E\)', 'backgroundColor: const Color(0xFF141414)'
    $content = $content -replace 'decoration: const BoxDecoration\(color: Color\(0xFF222222\), borderRadius: BorderRadius.vertical\(top: Radius.circular\(24\)\)\)', 'decoration: const BoxDecoration(color: Color(0xFF141414), borderRadius: BorderRadius.vertical(top: Radius.circular(24)))'
    $content = $content -replace 'decoration: const BoxDecoration\(color: Color\(0xFF222222\), border: Border\(top: BorderSide\(color: Colors.white12\)\)\)', 'decoration: const BoxDecoration(color: Color(0xFF141414), border: Border(top: BorderSide(color: Colors.white12)))'

    # Update location field
    $oldLoc = 'child: TextField\(\s*controller: locCtrl,\s*style: const TextStyle\(color: Colors.white, fontSize: 13\),\s*decoration: const InputDecoration\(hintText: ''Enter location'', hintStyle: TextStyle\(color: Colors.white38, fontSize: 13\), border: InputBorder.none\),\s*onChanged: \(v\) => setS\(\(\) => tempLocation = v\),\s*\),'
    $newLoc = 'padding: const EdgeInsets.only(left: 12, right: 8), child: Row(children: [Expanded(child: TextField(controller: locCtrl, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(hintText: ''Enter location'', hintStyle: TextStyle(color: Colors.white38, fontSize: 13), border: InputBorder.none), onChanged: (v) => setS(() => tempLocation = v),)), GestureDetector(onTap: () async { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(''Fetching location...''), duration: Duration(seconds: 1))); try { final pos = await Geolocator.getCurrentPosition(); final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude); if (placemarks.isNotEmpty) { final p = placemarks.first; final loc = [p.locality, p.administrativeArea].where((e) => e != null && e.isNotEmpty).join('', ''); locCtrl.text = loc; setS(() => tempLocation = loc); } } catch (e) { debugPrint(''Location error: $e''); } }, child: const Icon(Icons.my_location, color: _purple, size: 20),)],),'
    
    $content = $content -replace 'padding: const EdgeInsets.symmetric\(horizontal: 12\),\s*child: TextField\(\s*controller: locCtrl,\s*style: const TextStyle\(color: Colors.white, fontSize: 13\),\s*decoration: const InputDecoration\(hintText: ''Enter location'', hintStyle: TextStyle\(color: Colors.white38, fontSize: 13\), border: InputBorder.none\),\s*onChanged: \(v\) => setS\(\(\) => tempLocation = v\),\s*\),', $newLoc
    
    Set-Content -Path $file -Value $content
}
