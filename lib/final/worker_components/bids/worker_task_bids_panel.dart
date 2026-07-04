import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerTaskBidsSheet extends StatefulWidget {
  final String taskId;

  const WorkerTaskBidsSheet({
    super.key,
    required this.taskId,
  });

  @override
  State<WorkerTaskBidsSheet> createState() => _WorkerTaskBidsSheetState();
}

class _WorkerTaskBidsSheetState extends State<WorkerTaskBidsSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String get workerId => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _placeOrUpdateBid() async {
    final amount = double.tryParse(_amountController.text.trim());
    final message = _messageController.text.trim();

    if (amount == null) return;

    final ref = FirebaseFirestore.instance
        .collection("tasks")
        .doc(widget.taskId)
        .collection("bids")
        .doc(workerId);

    await ref.set({
      "workerId": workerId,
      "amount": amount,
      "message": message,
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    }); // ❌ no merge = full overwrite (clean replacement)

    _amountController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bidsStream = FirebaseFirestore.instance
        .collection("tasks")
        .doc(widget.taskId)
        .collection("bids")
        .orderBy("amount", descending: false)
        .snapshots();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [

          const Text(
            "Live Bidding Room",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          const SizedBox(height: 10),

          /// YOUR BID INPUT
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Your Bid Amount",
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: "Message (optional)",
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrUpdateBid,
              child: const Text("Place / Update Bid"),
            ),
          ),

          const Divider(),

          /// LIVE BIDS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bidsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bids = snapshot.data!.docs;

                if (bids.isEmpty) {
                  return const Center(
                    child: Text("No bids yet"),
                  );
                }

                final highestBid =
                bids.first.data() as Map<String, dynamic>;

                final highestAmount = highestBid["amount"];

                return ListView.builder(
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final data =
                    bids[index].data() as Map<String, dynamic>;

                    final isMine = data["workerId"] == workerId;
                    final isHighest = data["amount"] == highestAmount;

                    return Card(
                      color: isMine
                          ? Colors.green.shade50
                          : isHighest
                          ? Colors.amber.shade50
                          : null,
                      child: ListTile(
                        leading: Icon(
                          isHighest
                              ? Icons.emoji_events
                              : Icons.person,
                          color:
                          isHighest ? Colors.amber : Colors.grey,
                        ),
                        title: Text("Bid: \$${data["amount"]}"),
                        subtitle: Text(data["message"] ?? ""),
                        trailing: isMine
                            ? const Text(
                          "YOU",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}