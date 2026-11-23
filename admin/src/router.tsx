import { createBrowserRouter, Navigate } from 'react-router';
import { CompanyLayout } from './app/CompanyLayout';
import { SHOW_DEV_TOOLS } from './config';
import { PublicOnly, RequireSession } from './features/auth/guards';
import { CustomerPage } from './features/customers/CustomerPage';
import { ProjectsPage } from './features/customers/ProjectsPage';
import { CustomersPage } from './features/customers/CustomersPage';
import { AttendancePage } from './features/attendance/AttendancePage';
import { NotificationsPage } from './features/inbox/NotificationsPage';
import { LeadPage } from './features/leads/LeadPage';
import { LeadsPage } from './features/leads/LeadsPage';
import { DeleteAccountPage } from './features/legal/DeleteAccountPage';
import { LegalPage } from './features/legal/LegalPage';
import { CommissionsPage } from './features/money/CommissionsPage';
import { ExpensesPage } from './features/money/ExpensesPage';
import { PaymentsPage } from './features/money/PaymentsPage';
import { OverviewPage } from './features/overview/OverviewPage';
import { SettingsPage } from './features/settings/SettingsPage';
import { StagesPage } from './features/settings/StagesPage';
import { NewTaskPage } from './features/tasks/NewTaskPage';
import { TaskPage } from './features/tasks/TaskPage';
import { TasksPage } from './features/tasks/TasksPage';
import { AddMemberPage } from './features/team/AddMemberPage';
import { MemberPage } from './features/team/MemberPage';
import { TeamPage } from './features/team/TeamPage';
import { ForgotPasswordPage } from './pages/ForgotPasswordPage';
import { GalleryPage } from './pages/GalleryPage';
import { HomePage } from './pages/HomePage';
import { LoginPage } from './pages/LoginPage';
import { NotFoundPage } from './pages/NotFoundPage';
import { ResetPasswordPage } from './pages/ResetPasswordPage';

/** Routes. The gallery exists only in development builds. */
export const routes = [
  {
    element: <RequireSession />,
    children: [
      { path: '/', element: <HomePage /> },
      {
        path: '/c/:orgId',
        element: <CompanyLayout />,
        children: [
          { index: true, element: <Navigate to="overview" replace /> },
          { path: 'overview', element: <OverviewPage /> },
          { path: 'notifications', element: <NotificationsPage /> },
          { path: 'customers', element: <CustomersPage /> },
          { path: 'customers/:customerId', element: <CustomerPage /> },
          { path: 'projects', element: <ProjectsPage /> },
          { path: 'projects/:customerId', element: <CustomerPage /> },
          { path: 'tasks', element: <TasksPage /> },
          { path: 'tasks/new', element: <NewTaskPage /> },
          { path: 'tasks/:taskId', element: <TaskPage /> },
          { path: 'expenses', element: <ExpensesPage /> },
          { path: 'expenses/:expenseId', element: <ExpensesPage /> },
          { path: 'commissions', element: <CommissionsPage /> },
          { path: 'payments', element: <PaymentsPage /> },
          { path: 'leads', element: <LeadsPage /> },
          { path: 'leads/:leadId', element: <LeadPage /> },
          { path: 'attendance', element: <AttendancePage /> },
          { path: 'team', element: <TeamPage /> },
          { path: 'team/add', element: <AddMemberPage /> },
          { path: 'team/:userId', element: <MemberPage /> },
          { path: 'settings', element: <SettingsPage /> },
          { path: 'settings/stages', element: <StagesPage /> },
          { path: '*', element: <NotFoundPage /> },
        ],
      },
    ],
  },
  {
    element: <PublicOnly />,
    children: [
      { path: '/login', element: <LoginPage /> },
      { path: '/forgot', element: <ForgotPasswordPage /> },
      { path: '/reset', element: <ResetPasswordPage /> },
    ],
  },
  // The legal documents (F16): open to everyone, logged in or not.
  { path: '/terms', element: <LegalPage document="terms" /> },
  { path: '/privacy', element: <LegalPage document="privacy" /> },
  { path: '/delete-account', element: <DeleteAccountPage /> },
  { path: '/company-terms', element: <LegalPage document="company-terms" /> },
  ...(SHOW_DEV_TOOLS ? [{ path: '/gallery', element: <GalleryPage /> }] : []),
  { path: '*', element: <NotFoundPage /> },
];

export const router = createBrowserRouter(routes);
