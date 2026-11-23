import type { components } from '../api/schema';
import type { Tone } from '../components/tone';

type S = components['schemas'];
type Label = { label: string; tone: Tone };

/* What each API value reads as, in one place so every screen says the same. */

export const KYC: Record<S['KycStatus'], Label> = {
  in_review: { label: 'In review', tone: 'neutral' },
  needs_fix: { label: 'With the agent', tone: 'neutral' },
  approved: { label: 'Verified', tone: 'success' },
  rejected: { label: 'Not taken up', tone: 'quiet' },
};

export const DOCUMENT: Record<S['DocumentStatus'], Label> = {
  in_review: { label: 'To check', tone: 'neutral' },
  needs_fix: { label: 'Sent back', tone: 'danger' },
  verified: { label: 'Verified', tone: 'success' },
};

export const TASK: Record<S['TaskStatus'], Label> = {
  assigned: { label: 'Assigned', tone: 'neutral' },
  submitted: { label: 'In review', tone: 'neutral' },
  returned: { label: 'Sent back', tone: 'danger' },
  approved: { label: 'Approved', tone: 'success' },
  cancelled: { label: 'Cancelled', tone: 'quiet' },
};

/** The advance, as the projects list says it. */
export const ADVANCE: Record<S['AdminPaymentStatus'], Label> = {
  later: { label: 'Advance not asked', tone: 'quiet' },
  due: { label: 'Advance due', tone: 'warning' },
  claimed: { label: 'Says advance paid', tone: 'warning' },
  paid: { label: 'Advance paid', tone: 'success' },
};

export const EXPENSE: Record<S['ExpenseStatus'], Label> = {
  in_review: { label: 'In review', tone: 'neutral' },
  approved: { label: 'To pay', tone: 'accent' },
  needs_fix: { label: 'Sent back', tone: 'danger' },
  paid: { label: 'Paid', tone: 'success' },
  rejected: { label: 'Not accepted', tone: 'quiet' },
};

export const COMMISSION: Record<S['CommissionStatus'], Label> = {
  in_review: { label: 'In review', tone: 'neutral' },
  approved: { label: 'Waiting for advance', tone: 'quiet' },
  payable: { label: 'Payable', tone: 'accent' },
  paid: { label: 'Paid', tone: 'success' },
};

export const PAYMENT: Record<S['AdminPaymentStatus'], Label> = {
  claimed: { label: 'Says paid', tone: 'warning' },
  due: { label: 'Due', tone: 'warning' },
  later: { label: 'Not asked yet', tone: 'quiet' },
  paid: { label: 'Paid', tone: 'success' },
};

export const MEMBER: Record<S['MemberStatus'], Label> = {
  invited: { label: 'Invited', tone: 'warning' },
  active: { label: 'Active', tone: 'success' },
};

export const CATEGORY: Record<S['ExpenseCategory'], string> = {
  fuel: 'Fuel',
  material: 'Material',
  labour: 'Labour',
  other: 'Other',
};

export const SIDE: Record<S['DocumentSide'], string> = { front: 'Front', back: 'Back' };

export const CONNECTION: Record<S['ConnectionType'], string> = {
  residential: 'Residential',
  commercial: 'Commercial',
  industrial: 'Industrial',
};

export const ROOF: Record<S['RoofType'], string> = {
  rcc: 'RCC (concrete)',
  tin_shed: 'Tin shed',
  other: 'Other',
};

export const PROBLEM: Record<S['TaskProblemReason'], string> = {
  customer_away: 'Customer away',
  material_missing: 'Material missing',
  bad_weather: 'Bad weather',
  site_not_ready: 'Site not ready',
  safety: 'Safety',
  other: 'Other',
};

export const ATTENDANCE: Record<S['AttendanceStatus'], Label> = {
  working: { label: 'Working', tone: 'accent' },
  ended: { label: 'Day ended', tone: 'success' },
  no_check_out: { label: 'No check-out', tone: 'warning' },
};

export const NOT_STARTED: Label = { label: 'Not started', tone: 'quiet' };

export const METHOD = { upi: 'UPI', bank_transfer: 'Bank transfer' } as const;

export const EVENT: Record<S['AdminTaskEvent']['kind'], string> = {
  assigned: 'Assigned',
  photos_uploaded: 'Photos uploaded',
  submitted: 'Submitted',
  resubmitted: 'Submitted again',
  returned: 'Sent back',
  approved: 'Approved',
  problem_reported: 'Problem reported',
  rescheduled: 'Rescheduled',
  reassigned: 'Reassigned',
  cancelled: 'Cancelled',
  message: 'Message',
};

export const LEAD: Record<S['LeadStatus'], Label> = {
  new: { label: 'New', tone: 'accent' },
  contacted: { label: 'Contacted', tone: 'neutral' },
  won: { label: 'Won', tone: 'success' },
  lost: { label: 'Lost', tone: 'quiet' },
};
