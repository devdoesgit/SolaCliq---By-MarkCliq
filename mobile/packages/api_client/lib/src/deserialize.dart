import 'package:api_client/src/model/access_request_create.dart';
import 'package:api_client/src/model/add_member_request.dart';
import 'package:api_client/src/model/checklist_item.dart';
import 'package:api_client/src/model/claim_install_payment_request.dart';
import 'package:api_client/src/model/commission.dart';
import 'package:api_client/src/model/customer_detail.dart';
import 'package:api_client/src/model/customer_detail_advance.dart';
import 'package:api_client/src/model/customer_detail_documents.dart';
import 'package:api_client/src/model/customer_detail_returned.dart';
import 'package:api_client/src/model/customer_detail_stage.dart';
import 'package:api_client/src/model/customer_list.dart';
import 'package:api_client/src/model/customer_registration.dart';
import 'package:api_client/src/model/customer_registration_create.dart';
import 'package:api_client/src/model/customer_registration_create_documents_inner.dart';
import 'package:api_client/src/model/customer_summary.dart';
import 'package:api_client/src/model/email_request.dart';
import 'package:api_client/src/model/expense.dart';
import 'package:api_client/src/model/expense_create.dart';
import 'package:api_client/src/model/expense_page.dart';
import 'package:api_client/src/model/health.dart';
import 'package:api_client/src/model/home_day.dart';
import 'package:api_client/src/model/home_energy.dart';
import 'package:api_client/src/model/home_progress.dart';
import 'package:api_client/src/model/home_row.dart';
import 'package:api_client/src/model/home_segment.dart';
import 'package:api_client/src/model/home_status.dart';
import 'package:api_client/src/model/home_summary.dart';
import 'package:api_client/src/model/home_summary_headline.dart';
import 'package:api_client/src/model/home_summary_list.dart';
import 'package:api_client/src/model/home_tile.dart';
import 'package:api_client/src/model/home_visual.dart';
import 'package:api_client/src/model/install.dart';
import 'package:api_client/src/model/install_next_visit.dart';
import 'package:api_client/src/model/install_next_visit_person.dart';
import 'package:api_client/src/model/install_payment.dart';
import 'package:api_client/src/model/install_stage.dart';
import 'package:api_client/src/model/invite.dart';
import 'package:api_client/src/model/invite_list.dart';
import 'package:api_client/src/model/invite_org.dart';
import 'package:api_client/src/model/login_request.dart';
import 'package:api_client/src/model/login_response.dart';
import 'package:api_client/src/model/me.dart';
import 'package:api_client/src/model/member.dart';
import 'package:api_client/src/model/member_page.dart';
import 'package:api_client/src/model/membership.dart';
import 'package:api_client/src/model/membership_org.dart';
import 'package:api_client/src/model/my_document.dart';
import 'package:api_client/src/model/my_document_list.dart';
import 'package:api_client/src/model/notification.dart';
import 'package:api_client/src/model/notification_page.dart';
import 'package:api_client/src/model/page_info.dart';
import 'package:api_client/src/model/payout_bank.dart';
import 'package:api_client/src/model/person.dart';
import 'package:api_client/src/model/personal_details.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/problem_errors_inner.dart';
import 'package:api_client/src/model/proof_photo.dart';
import 'package:api_client/src/model/proof_photo_create.dart';
import 'package:api_client/src/model/proof_slot.dart';
import 'package:api_client/src/model/quote_estimate.dart';
import 'package:api_client/src/model/quote_request.dart';
import 'package:api_client/src/model/quote_request_create.dart';
import 'package:api_client/src/model/refresh_request.dart';
import 'package:api_client/src/model/replace_customer_document_request.dart';
import 'package:api_client/src/model/replace_expense_receipt_request.dart';
import 'package:api_client/src/model/reset_password_request.dart';
import 'package:api_client/src/model/send_task_message_request.dart';
import 'package:api_client/src/model/set_task_checklist_item_request.dart';
import 'package:api_client/src/model/settings.dart';
import 'package:api_client/src/model/signup_request.dart';
import 'package:api_client/src/model/submit_task_request.dart';
import 'package:api_client/src/model/task.dart';
import 'package:api_client/src/model/task_approved.dart';
import 'package:api_client/src/model/task_customer.dart';
import 'package:api_client/src/model/task_event.dart';
import 'package:api_client/src/model/task_history.dart';
import 'package:api_client/src/model/task_note.dart';
import 'package:api_client/src/model/task_page.dart';
import 'package:api_client/src/model/task_problem.dart';
import 'package:api_client/src/model/task_problem_create.dart';
import 'package:api_client/src/model/task_ref.dart';
import 'package:api_client/src/model/task_stage.dart';
import 'package:api_client/src/model/task_summary.dart';
import 'package:api_client/src/model/token_pair.dart';
import 'package:api_client/src/model/upload.dart';
import 'package:api_client/src/model/upload_create.dart';
import 'package:api_client/src/model/verify_email_request.dart';
import 'package:api_client/src/model/worker_stats.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AccessRequestCreate':
      return AccessRequestCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AddMemberRequest':
      return AddMemberRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BillBand':
    case 'ChecklistItem':
      return ChecklistItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClaimInstallPaymentRequest':
      return ClaimInstallPaymentRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Commission':
      return Commission.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CommissionStatus':
    case 'ConnectionType':
    case 'CustomerDetail':
      return CustomerDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerDetailAdvance':
      return CustomerDetailAdvance.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerDetailDocuments':
      return CustomerDetailDocuments.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerDetailReturned':
      return CustomerDetailReturned.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerDetailStage':
      return CustomerDetailStage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerList':
      return CustomerList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CustomerRegistration':
      return CustomerRegistration.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerRegistrationCreate':
      return CustomerRegistrationCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerRegistrationCreateDocumentsInner':
      return CustomerRegistrationCreateDocumentsInner.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'CustomerSummary':
      return CustomerSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DocumentStatus':
    case 'EmailRequest':
      return EmailRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Expense':
      return Expense.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ExpenseCategory':
    case 'ExpenseCreate':
      return ExpenseCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExpensePage':
      return ExpensePage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ExpenseStatus':
    case 'Health':
      return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeDay':
      return HomeDay.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeEnergy':
      return HomeEnergy.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeProgress':
      return HomeProgress.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeRow':
      return HomeRow.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeSegment':
      return HomeSegment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeStatus':
      return HomeStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeSummary':
      return HomeSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeSummaryHeadline':
      return HomeSummaryHeadline.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HomeSummaryList':
      return HomeSummaryList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HomeTile':
      return HomeTile.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeTone':
    case 'HomeVisual':
      return HomeVisual.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Install':
      return Install.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'InstallNextVisit':
      return InstallNextVisit.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'InstallNextVisitPerson':
      return InstallNextVisitPerson.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'InstallPayment':
      return InstallPayment.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'InstallStage':
      return InstallStage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Invite':
      return Invite.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'InviteList':
      return InviteList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'InviteOrg':
      return InviteOrg.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KycKind':
    case 'KycStatus':
    case 'LoginRequest':
      return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LoginResponse':
      return LoginResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Me':
      return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Member':
      return Member.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MemberPage':
      return MemberPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MemberStatus':
    case 'Membership':
      return Membership.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MembershipOrg':
      return MembershipOrg.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MyDocument':
      return MyDocument.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MyDocumentList':
      return MyDocumentList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Notification':
      return Notification.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'NotificationPage':
      return NotificationPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrgStatus':
    case 'PageInfo':
      return PageInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PayoutBank':
      return PayoutBank.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Person':
      return Person.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PersonalDetails':
      return PersonalDetails.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Problem':
      return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProblemErrorsInner':
      return ProblemErrorsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProofPhoto':
      return ProofPhoto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProofPhotoCreate':
      return ProofPhotoCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProofSlot':
      return ProofSlot.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'QuoteEstimate':
      return QuoteEstimate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'QuoteFor':
    case 'QuoteRequest':
      return QuoteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'QuoteRequestCreate':
      return QuoteRequestCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'QuoteTimeline':
    case 'RefreshRequest':
      return RefreshRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReplaceCustomerDocumentRequest':
      return ReplaceCustomerDocumentRequest.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'ReplaceExpenseReceiptRequest':
      return ReplaceExpenseReceiptRequest.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'ResetPasswordRequest':
      return ResetPasswordRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Role':
    case 'RoofType':
    case 'SendTaskMessageRequest':
      return SendTaskMessageRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SetTaskChecklistItemRequest':
      return SetTaskChecklistItemRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Settings':
      return Settings.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SignupRequest':
      return SignupRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubmitTaskRequest':
      return SubmitTaskRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Task':
      return Task.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskApproved':
      return TaskApproved.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskCustomer':
      return TaskCustomer.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskEvent':
      return TaskEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskHistory':
      return TaskHistory.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskNote':
      return TaskNote.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskPage':
      return TaskPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskProblem':
      return TaskProblem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskProblemCreate':
      return TaskProblemCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TaskProblemReason':
    case 'TaskRef':
      return TaskRef.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskStage':
      return TaskStage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TaskStatus':
    case 'TaskSummary':
      return TaskSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TokenPair':
      return TokenPair.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Upload':
      return Upload.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UploadCreate':
      return UploadCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VerifyEmailRequest':
      return VerifyEmailRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WorkerStats':
      return WorkerStats.fromJson(value as Map<String, dynamic>) as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map(
            (dynamic v) => deserialize<BaseType, BaseType>(
              v,
              targetType,
              growable: growable,
            ),
          ),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
