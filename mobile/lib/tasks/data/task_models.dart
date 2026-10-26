import 'package:equatable/equatable.dart';

/// Where a task is: to do, with the admin, sent back, or final.
enum TaskStatus { assigned, submitted, returned, approved, cancelled }

/// Which tasks a list shows.
enum TaskView { today, upcoming, done }

enum TaskProblemReason {
  customerAway,
  materialMissing,
  badWeather,
  siteNotReady,
  safety,
  other,
}

enum TaskEventKind {
  assigned,
  photosUploaded,
  submitted,
  resubmitted,
  returned,
  approved,
  problemReported,
  rescheduled,
  reassigned,
  cancelled,
  message,
}

class TaskPerson extends Equatable {
  const new({required this.name, this.role, this.you = false});

  final String name;
  final String? role;

  /// The person using the app.
  final bool you;

  @override
  List<Object?> get props => [name, role, you];
}

/// A row of a task list.
class TaskSummary extends Equatable {
  const new({
    required this.id,
    required this.reference,
    required this.title,
    required this.status,
    required this.dueAt,
    required this.customerName,
    this.image,
    this.distanceKm,
    this.statusAt,
    this.hasProblem = false,
  });

  final String id;
  final String reference;

  /// The work: "Panel installation".
  final String title;
  final TaskStatus status;
  final DateTime dueAt;
  final String customerName;
  final String? image;
  final double? distanceKm;
  final DateTime? statusAt;
  final bool hasProblem;

  @override
  List<Object?> get props => [
    id,
    reference,
    title,
    status,
    dueAt,
    customerName,
    image,
    distanceKm,
    statusAt,
    hasProblem,
  ];
}

class TaskCustomer extends Equatable {
  const new({
    required this.name,
    required this.address,
    this.systemKw,
    this.phone,
    this.lat,
    this.lng,
  });

  final String name;
  final String address;
  final double? systemKw;

  /// Ten digits.
  final String? phone;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [name, address, systemKw, phone, lat, lng];
}

class ProofPhoto extends Equatable {
  const new({required this.url, required this.takenAt, this.accuracyM});

  /// A link, or `asset:<name>` in sample data, or `file:<path>` for a
  /// photo just taken on this phone.
  final String url;
  final DateTime takenAt;
  final double? accuracyM;

  @override
  List<Object?> get props => [url, takenAt, accuracyM];
}

/// One photo the task needs: "Clamp close-up".
class ProofSlot extends Equatable {
  const new({
    required this.id,
    required this.label,
    this.hint,
    this.photo,
    this.retake = false,
  });

  final String id;
  final String label;
  final String? hint;
  final ProofPhoto? photo;

  /// The admin asked for this one again.
  final bool retake;

  /// Has a photo the admin hasn't asked to retake.
  bool get done => photo != null && !retake;

  ProofSlot withPhoto(ProofPhoto photo) =>
      ProofSlot(id: id, label: label, hint: hint, photo: photo);

  @override
  List<Object?> get props => [id, label, hint, photo, retake];
}

class ChecklistItem extends Equatable {
  const new({required this.id, required this.text, required this.done});

  final String id;
  final String text;
  final bool done;

  @override
  List<Object> get props => [id, text, done];
}

/// Words from someone, with when: the admin's note, a return, a cancel.
class TaskNote extends Equatable {
  const new({required this.text, required this.by, required this.at});

  final String text;
  final TaskPerson by;
  final DateTime at;

  @override
  List<Object> get props => [text, by, at];
}

class TaskProblem extends Equatable {
  const new({required this.reason, required this.note, required this.at});

  final TaskProblemReason reason;
  final String note;
  final DateTime at;

  @override
  List<Object> get props => [reason, note, at];
}

class TaskApproval extends Equatable {
  const new({required this.by, required this.at, this.nextTask});

  final TaskPerson by;
  final DateTime at;
  final TaskSummary? nextTask;

  @override
  List<Object?> get props => [by, at, nextTask];
}

class Task extends Equatable {
  const new({
    required this.id,
    required this.reference,
    required this.title,
    required this.status,
    required this.dueAt,
    required this.stageIndex,
    required this.stageCount,
    required this.customer,
    required this.photos,
    required this.checklist,
    this.assignedBy,
    this.adminNote,
    this.submittedAt,
    this.workerNote,
    this.returned,
    this.problem,
    this.cancelled,
    this.approved,
  });

  final String id;
  final String reference;
  final String title;
  final TaskStatus status;
  final DateTime dueAt;

  /// The customer's install stage this task finishes, 1-based.
  final int stageIndex;
  final int stageCount;
  final TaskCustomer customer;
  final List<ProofSlot> photos;
  final List<ChecklistItem> checklist;
  final TaskPerson? assignedBy;
  final TaskNote? adminNote;
  final DateTime? submittedAt;
  final String? workerNote;
  final TaskNote? returned;
  final TaskProblem? problem;
  final TaskNote? cancelled;
  final TaskApproval? approved;

  int get photosDone => photos.where((p) => p.done).length;
  int get checklistDone => checklist.where((c) => c.done).length;

  /// Photos and checklist can still change.
  bool get editable =>
      status == TaskStatus.assigned || status == TaskStatus.returned;

  /// Everything is in: it can be submitted.
  bool get ready =>
      editable &&
      photosDone == photos.length &&
      checklistDone == checklist.length;

  /// The first slot still needing a photo, if any.
  ProofSlot? get nextSlot {
    for (final slot in photos) {
      if (!slot.done) return slot;
    }
    return null;
  }

  Task copyWith({List<ProofSlot>? photos, List<ChecklistItem>? checklist}) =>
      Task(
        id: id,
        reference: reference,
        title: title,
        status: status,
        dueAt: dueAt,
        stageIndex: stageIndex,
        stageCount: stageCount,
        customer: customer,
        photos: photos ?? this.photos,
        checklist: checklist ?? this.checklist,
        assignedBy: assignedBy,
        adminNote: adminNote,
        submittedAt: submittedAt,
        workerNote: workerNote,
        returned: returned,
        problem: problem,
        cancelled: cancelled,
        approved: approved,
      );

  @override
  List<Object?> get props => [
    id,
    reference,
    title,
    status,
    dueAt,
    stageIndex,
    stageCount,
    customer,
    photos,
    checklist,
    assignedBy,
    adminNote,
    submittedAt,
    workerNote,
    returned,
    problem,
    cancelled,
    approved,
  ];
}

class TaskEvent extends Equatable {
  const new({
    required this.kind,
    required this.actor,
    required this.at,
    this.detail,
  });

  final TaskEventKind kind;
  final TaskPerson actor;
  final DateTime at;
  final String? detail;

  @override
  List<Object?> get props => [kind, actor, at, detail];
}

/// Where and when a proof photo was taken.
class CaptureFix extends Equatable {
  const new({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.takenAt,
    this.mocked = false,
  });

  final double lat;
  final double lng;
  final double accuracyM;
  final DateTime takenAt;

  /// The phone reported a fake location.
  final bool mocked;

  @override
  List<Object> get props => [lat, lng, accuracyM, takenAt, mocked];
}

class WorkerStats extends Equatable {
  const new({
    required this.tasksThisMonth,
    required this.returnedThisMonth,
    required this.avgMinutesOnSite,
  });

  final int tasksThisMonth;
  final int returnedThisMonth;
  final int avgMinutesOnSite;

  @override
  List<Object> get props => [
    tasksThisMonth,
    returnedThisMonth,
    avgMinutesOnSite,
  ];
}
