import 'package:errand_app/final/worker_components/active_task/worker_active_task_controller.dart';
import 'package:flutter/material.dart';

import 'worker_active_task_controller.dart';

class WorkerTaskStatusWidget extends StatelessWidget {
  final WorkerActiveTaskController controller;

  const WorkerTaskStatusWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final task = controller.task;

    if (task == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// Progress
          Row(
            children: [
              Expanded(
                child: _step(
                  title: "Assigned",
                  active: true,
                ),
              ),
              Expanded(
                child: _step(
                  title: "Heading",
                  active: task.status == "heading_to_customer" ||
                      task.status == "arrived" ||
                      task.status == "in_progress" ||
                      task.status == "completed",
                ),
              ),
              Expanded(
                child: _step(
                  title: "Arrived",
                  active: task.status == "arrived" ||
                      task.status == "in_progress" ||
                      task.status == "completed",
                ),
              ),
              Expanded(
                child: _step(
                  title: "Working",
                  active: task.status == "in_progress" ||
                      task.status == "completed",
                ),
              ),
              Expanded(
                child: _step(
                  title: "Done",
                  active: task.status == "completed",
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final task = controller.task!;

    switch (task.status) {
      case "assigned":
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.navigation),
            label: const Text("Start Navigation"),
            onPressed: () async {
              await controller.startHeading();
            },
          ),
        );

      case "heading_to_customer":
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: const Text("I've Arrived"),
            onPressed: controller.arrived
                ? () async {
              await controller.arrive();
            }
                : null,
          ),
        );

      case "arrived":
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text("Start Task"),
            onPressed: () async {
              await controller.startTask();
            },
          ),
        );

      case "in_progress":
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text("Complete Task"),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Complete Task"),
                  content: const Text(
                    "Are you sure you've completed this task?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text("No"),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await controller.completeTask();
              }
            },
          ),
        );

      case "completed":
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            icon: const Icon(Icons.done_all),
            label: const Text("Task Completed"),
            onPressed: null,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _step({
    required String title,
    required bool active,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
          active ? Colors.green : Colors.grey.shade300,
          child: Icon(
            Icons.check,
            color: active ? Colors.white : Colors.grey,
            size: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active
                ? FontWeight.bold
                : FontWeight.normal,
            color:
            active ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}