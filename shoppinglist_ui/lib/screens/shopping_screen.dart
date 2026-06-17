import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants.dart';
import '../../models/models.dart';

class ShoppingListScreen extends StatefulWidget {
  ShoppingListScreen({super.key});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _unit = "개";
  final List<String> _units = ["개", "kg", "g", "ml", "모", "팩"];
  List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/shopping-list'));
      if (res.statusCode == 200) {
        List data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _items = data
              .map((e) => ShoppingItem(
            name: (e['재료명'] ?? '이름없음').toString(),
            quantity: (e['최종수량'] ?? '0').toString(),
            unit: (e['단위'] ?? '').toString(),
          ))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _add() async {
    if (_nameCtrl.text.isEmpty || _qtyCtrl.text.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/shopping-list/add'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "재료": _nameCtrl.text,
          "수량": double.tryParse(_qtyCtrl.text) ?? 0,
          "단위": _unit,
        }),
      );
    } catch (_) {
      setState(() => _items.add(ShoppingItem(
          name: _nameCtrl.text, quantity: _qtyCtrl.text, unit: _unit)));
    }
    _nameCtrl.clear();
    _qtyCtrl.clear();
    _fetch();
  }

  Future<void> _fromUrl() async {
    if (_urlCtrl.text.isEmpty) return;
    try {
      final res = await http.post(Uri.parse(
          '$baseUrl/generate-shopping-list?youtube_url=${Uri.encodeComponent(_urlCtrl.text)}'));
      if (res.statusCode == 200) {
        _fetch();
        _urlCtrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("레시피가 분석되었습니다!")));
        }
      }
    } catch (_) {}
  }

  Future<void> _delete(String name) async {
    try {
      await http.delete(Uri.parse('$baseUrl/shopping-list/$name'));
    } catch (_) {}
    setState(() => _items.removeWhere((i) => i.name == name));
  }

  Future<void> _update(String name, String qty) async {
    try {
      await http
          .put(Uri.parse('$baseUrl/shopping-list/$name?new_quantity=$qty'));
    } catch (_) {}
    _fetch();
  }

  void _confirmDelete({required VoidCallback onConfirm, String msg = "정말 삭제하시겠습니까?"}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("삭제 확인"),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: kTextSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kError),
            onPressed: () { onConfirm(); Navigator.pop(context); },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editDialog(int idx) {
    final ctrl = TextEditingController(text: _items[idx].quantity);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("수량 수정"),
        content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "수량")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: kTextSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () { _update(_items[idx].name, ctrl.text); Navigator.pop(context); },
            child: const Text("확인", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("쇼핑 목록",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 헤더 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text("오늘의 장보기",
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 16),

          // 유튜브 분석
          _section(
            borderColor: const Color(0xFFFFDAD6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.video_library, color: Colors.redAccent, size: 20),
                SizedBox(width: 6),
                Text("유튜브 레시피 분석",
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
              ]),
              const SizedBox(height: 10),
              _inputField(_urlCtrl, "유튜브 URL 입력"),
              const SizedBox(height: 10),
              _btn("자동으로 재료 추가", Colors.redAccent, _fromUrl),
            ]),
          ),
          const SizedBox(height: 16),

          // 품목 추가
          _section(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.add_shopping_cart, color: kPrimary, size: 20),
                SizedBox(width: 6),
                Text("품목 추가하기",
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
              ]),
              const SizedBox(height: 10),
              _inputField(_nameCtrl, "무엇을 살까요?"),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(flex: 2,
                    child: _inputField(_qtyCtrl, "수량", type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F5),
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _unit,
                        items: _units
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _btn("리스트에 담기", kPrimary, _add, height: 50),
            ]),
          ),
          const SizedBox(height: 24),

          // 목록 헤더
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("구매 목록 (${_items.length})",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: kTextMain)),
            TextButton(
              onPressed: () => _confirmDelete(
                  msg: "모든 항목을 삭제하시겠습니까?",
                  onConfirm: () => setState(() => _items.clear())),
              child: const Text("전체 삭제", style: TextStyle(color: kError)),
            ),
          ]),

          // 구매 목록
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (_, idx) {
              final item = _items[idx];
              return Card(
                color: kSurface,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: item.isChecked ? kPrimary.withOpacity(0.3) : kBorder)),
                child: ListTile(
                  onTap: () => _editDialog(idx),
                  leading: Checkbox(
                    value: item.isChecked,
                    activeColor: kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => item.isChecked = v!),
                  ),
                  title: Text(item.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: item.isChecked ? kTextSub : kTextMain,
                          decoration: item.isChecked ? TextDecoration.lineThrough : null)),
                  subtitle: Text("${item.quantity} ${item.unit}",
                      style: const TextStyle(color: kTextSub, fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: kTextSub),
                    onPressed: () =>
                        _confirmDelete(onConfirm: () => _delete(item.name)),
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _section({required Widget child, Color? borderColor}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor ?? kBorder),
    ),
    child: child,
  );

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType? type}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextSub),
          filled: true,
          fillColor: const Color(0xFFF3F4F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
        ),
      );

  Widget _btn(String label, Color color, VoidCallback onTap, {double height = 45}) =>
      SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}