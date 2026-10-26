import 'package:solacliq/tasks/data/task_repository.dart';

const admin = TaskPerson(name: 'Rajeeb Kumar', role: 'Admin');

/// A task to do: two of three photos, one of two steps.
Task assignedTask({
  TaskStatus status = TaskStatus.assigned,
  List<ProofSlot>? photos,
  List<ChecklistItem>? checklist,
  TaskProblem? problem,
  TaskNote? returned,
  TaskNote? cancelled,
  TaskApproval? approved,
}) => Task(
  id: 't1',
  reference: 'TSK-1',
  title: 'Panel installation',
  status: status,
  dueAt: DateTime.utc(2026, 10, 23, 4),
  stageIndex: 3,
  stageCount: 7,
  assignedBy: admin,
  customer: const TaskCustomer(
    name: 'Ramesh Sahoo',
    address: 'Sector 70, Mohali',
    systemKw: 5,
    phone: '9814022671',
    lat: 30.7,
    lng: 76.7,
  ),
  photos:
      photos ??
      [
        ProofSlot(
          id: 'rails',
          label: 'Rails',
          photo: ProofPhoto(
            url: 'asset:thumb-install',
            takenAt: DateTime.utc(2026, 10, 23, 5),
          ),
        ),
        const ProofSlot(id: 'clamp', label: 'Clamp'),
      ],
  checklist:
      checklist ??
      const [
        ChecklistItem(id: 'a', text: 'Mount rails', done: true),
        ChecklistItem(id: 'b', text: 'Check torque', done: false),
      ],
  problem: problem,
  returned: returned,
  cancelled: cancelled,
  approved: approved,
);
