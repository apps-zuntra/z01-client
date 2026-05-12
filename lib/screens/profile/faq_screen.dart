import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:animate_do/animate_do.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFBA68C8),
          indicatorWeight: 3,
          labelColor: const Color(0xFFBA68C8),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          dividerColor: Colors.white10,
          tabs: const [
            Tab(text: 'Studio'),
            Tab(text: 'Equipment'),
            Tab(text: 'Manpower'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQList('Studio'),
          _buildFAQList('Equipment'),
          _buildFAQList('Manpower'),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF121212),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA68C8).withOpacity(0.3),
              foregroundColor: const Color(0xFFBA68C8),
              side: const BorderSide(color: Color(0xFFBA68C8), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Live Chat Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQList(String category) {
    List<Map<String, String>> faqs = [];
    
    if (category == 'Studio') {
      faqs = [
        {'q': 'What is Z01 Studio Rental??', 'a': 'Z01 lets you book verified photography, videography, podcast and production studios across Chennai through one platform.'},
        {'q': 'Does Z01 own the studios?', 'a': 'Z01 follows a hybrid model — some studios are owned by Z01 and others are verified partner studios.'},
        {'q': 'Who do I pay for a studio booking?', 'a': 'Payments are made directly to the studio vendor, not to Z01.'},
        {'q': 'What types of studios are available?', 'a': 'Photography, Videography, Podcast, Green Screen, White Cyclorama, and Home/Lifestyle studios.'},
      ];
    } else if (category == 'Equipment') {
      faqs = [
        {'q': 'What is Z01 Equipment Rental?', 'a': 'Z01 lets you rent professional production equipment from verified vendors.'},
        {'q': 'Who owns the equipment?', 'a': 'Equipment belongs to Z01 or verified partner vendors.'},
        {'q': 'Who do I pay?', 'a': 'You pay the equipment vendor directly.'},
        {'q': 'What equipment can I rent?', 'a': 'Cameras, Lenses, Lighting, Audio gear, Stabilizers, Drones, and Accessories.'},
      ];
    } else {
      faqs = [
        {'q': 'What is Z01 Manpower Rental?', 'a': 'Z01 allows you to hire verified freelance professionals for shoots and productions.'},
        {'q': 'Who provides the crew?', 'a': 'All professionals are freelancers verified by Z01.'},
        {'q': 'Who do I pay?', 'a': 'You pay the freelancer or vendor directly.'},
        {'q': 'What roles are available?', 'a': 'Photographers, Videographers, Cinematographers, Editors, Assistants, Sound Engineers, Makeup Artists, Lighting Technicians, and Drone Operators.'},
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSearchBox(),
          const SizedBox(height: 24),
          ...faqs.map((faq) => _buildFAQItem(faq['q']!, faq['a']!)).toList(),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(hintText: 'Search for help', hintStyle: TextStyle(color: Colors.white24, fontSize: 14), border: InputBorder.none, isDense: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), border: Border.all(color: Colors.white.withOpacity(0.05)), borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
