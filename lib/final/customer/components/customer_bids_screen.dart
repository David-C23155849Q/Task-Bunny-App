import 'dart:convert';
import 'dart:typed_data';

import 'package:errand_app/final/customer/components/tracking/tracking/customer_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerBidsPanel extends StatelessWidget {
  final String taskId;

  const CustomerBidsPanel({
    super.key,
    required this.taskId,
  });

  /// ---------------- BASE64 SAFE DECODE ----------------
  Uint8List? _decodeBase64(String input) {
    try {
      String normalized = input.trim();

      // fix missing padding
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  /// ---------------- ACCEPT BID ----------------
  Future<void> _acceptBid({
    required String bidId,
    required String workerId,
    required BuildContext context,
  }) async {
    final taskRef =
    FirebaseFirestore.instance.collection("tasks").doc(taskId);

    final bidsRef = taskRef.collection("bids");

    final acceptedBid = await bidsRef.doc(bidId).get();
    final bidData = acceptedBid.data() as Map<String, dynamic>;
    final acceptedPrice = bidData["amount"];

    final batch = FirebaseFirestore.instance.batch();

    batch.update(taskRef, {
      "assignedWorkerId": workerId,
      "winningBidId": bidId,
      "acceptedPrice": acceptedPrice,
      "status": "assigned",
      "assignedAt": FieldValue.serverTimestamp(),
    });

    final bidsSnap = await bidsRef.get();

    for (final doc in bidsSnap.docs) {
      batch.update(doc.reference, {
        "status": doc.id == bidId ? "accepted" : "rejected",
      });
    }

    final workerRef =
    FirebaseFirestore.instance.collection("workers").doc(workerId);

    batch.update(workerRef, {
      "availability": "busy",
      "currentTaskId": taskId,
    });

    await batch.commit();

    if (!context.mounted) return;

    //  IMPORTANT: avoid pop + pushReplacement conflict
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CustomerTrackingScreen(taskId: taskId),
        ),
            (route) => false,
      );
    });
  }


  /// ---------------- CANCEL TASK ----------------
  Future<void> _cancelTask(BuildContext context) async {
    final taskRef =
    FirebaseFirestore.instance.collection("tasks").doc(taskId);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Task"),
        content: const Text(
          "This will stop all bidding. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await taskRef.update({
      "status": "cancelled",
    });

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task cancelled")),
      );
    }
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final bidsStream = FirebaseFirestore.instance
        .collection("tasks")
        .doc(taskId)
        .collection("bids")
        .orderBy("timestamp", descending: true)
        .snapshots();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          /// HANDLE
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Incoming Bids",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// CANCEL BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _cancelTask(context),
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel Task"),
            ),
          ),

          const SizedBox(height: 10),

          /// STREAM
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bidsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final bids = snapshot.data!.docs;

                if (bids.isEmpty) {
                  return const Center(
                    child: Text("No bids yet"),
                  );
                }

                return ListView.builder(
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    final data =
                    bid.data() as Map<String, dynamic>;

                    final amount = data["amount"] ?? 0;
                    final message = data["message"] ?? "";
                    final status = data["status"] ?? "pending";
                    final workerId = data["workerId"];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("workers")
                          .doc(workerId)
                          .get(),
                      builder: (context, workerSnap) {
                        if (!workerSnap.hasData) {
                          return const SizedBox();
                        }

                        final workerData = workerSnap.data!.data()
                        as Map<String, dynamic>?;

                        final name =
                            workerData?["name"] ?? "Worker";

                        final imageBase64 =
                            workerData?["profileImageBase64"] ?? "";

                        final rating = (workerData?["rating"] ?? 0)
                            .toDouble();

                        final imageBytes =
                        _decodeBase64(imageBase64);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: imageBytes != null
                                  ? ClipOval(
                                child: Image.memory(
                                  imageBytes,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : const Icon(Icons.person),
                            ),

                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text("Bid: \$${amount.toString()}"),
                                Text(message),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            trailing: status == "pending"
                                ? ElevatedButton(
                              onPressed: () =>
                                  _acceptBid(
                                    bidId: bid.id,
                                    workerId: workerId,
                                    context: context,
                                  ),
                              child: const Text("Accept"),
                            )
                                : Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status ==
                                    "accepted"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
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