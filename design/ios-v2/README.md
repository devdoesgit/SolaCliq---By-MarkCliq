# iOS v2 mobile designs

Pulled 2026-10-27 from the "SolaCliq Login" canvas
(https://claude.ai/artifact/8nC3HVvyGMq7v2wf3gVGUZ, version 1793039182-d66c).
Mobile pages only; "v2 · 5 Admin web" is left out for now. Each `.dc.html`
is one 390×844 artboard as the canvas holds it (it needs the canvas's
`support.js` to render; read it as source). Images are the ones already in
`mobile/packages/sola_ui/assets/images` (identical files). Names and
figures in the screens are illustrative.

## v2 · 1 Start and users (`1-start/`)

> Start on Welcome. Everyone signs up as a normal user; a company adds them as Worker, Sales or Customer. Every button on every screen goes somewhere or changes something.

- `Ios2Welcome.dc.html`: Welcome
- `Ios2Intro.dc.html`: Intro walkthrough
- `Ios2Login.dc.html`: Log in
- `Ios2Forgot.dc.html`: Forgot password
- `Ios2ForgotSent.dc.html`: Reset link sent
- `Ios2SignUp.dc.html`: Create account
- `Ios2Verify.dc.html`: Verify email
- `Ios2UserHome.dc.html`: Home
- `Ios2Quote.dc.html`: Solar quote
- `Ios2QuoteSent.dc.html`: Quote sent
- `Ios2Learn.dc.html`: Learn
- `Ios2UserNotifications.dc.html`: Notifications · user
- `Ios2UserProfile.dc.html`: Profile · user
- `Ios2SettingsUser.dc.html`: Settings · user
- `Ios2HelpUser.dc.html`: Help · user
- `Ios2Invite.dc.html`: Invite
- `Ios2RoleSwitch.dc.html`: Switch workspace
- `Ios2Request.dc.html`: Request access
- `Ios2RequestSent.dc.html`: Request sent

## v2 · 2 Worker (`2-worker/`)

> Suresh Yadav. Tasks start as Assigned. Add the photos, tick the checklist, Submit task. Admin approves (next stage gets a new task) or returns it. On the other task screens, tap the empty photo slots to add them, then Submit.

- `Ios2HubWorker.dc.html`: Home · Worker
- `Ios2Tasks.dc.html`: Tasks
- `Ios2TaskDetail.dc.html`: Task · assigned
- `Ios2ProofCamera.dc.html`: Proof camera
- `Ios2TaskSubmit.dc.html`: Task · ready to submit
- `Ios2TaskSubmitted.dc.html`: Task · in review
- `Ios2TaskReturned.dc.html`: Task · returned
- `Ios2TaskReply.dc.html`: Task · reply to admin
- `Ios2TaskApproved.dc.html`: Task · approved
- `Ios2TaskHistory.dc.html`: Task history
- `Ios2TaskPriya.dc.html`: Task · Priya Nair (assigned)
- `Ios2TaskAnil.dc.html`: Task · Anil Mehta (returned)
- `Ios2TaskKiran.dc.html`: Task · Kiran Patel (in review)
- `Ios2TaskNext.dc.html`: Task · Ramesh Sahoo Stage 4 (Fri)
- `Ios2TaskTejinder.dc.html`: Task · Tejinder Gill (Mon)
- `Ios2TaskBaljit.dc.html`: Task · Baljit Kaur (done)
- `Ios2TaskCancelled.dc.html`: Task · cancelled
- `Ios2TaskProblem.dc.html`: Task · report a problem
- `Ios2TaskReported.dc.html`: Task · problem reported
- `Ios2Expenses.dc.html`: Expenses
- `Ios2Expense.dc.html`: Log expense
- `Ios2ExpenseSent.dc.html`: Expense sent
- `Ios2ExpFuel.dc.html`: Expense · fuel (in review)
- `Ios2ExpenseDetail.dc.html`: Expense detail
- `Ios2ExpMaterial.dc.html`: Expense · material (approved)
- `Ios2ExpPaid.dc.html`: Expense · fuel (paid)
- `Ios2Notifications.dc.html`: Notifications
- `Ios2WorkerProfile.dc.html`: Profile · Worker
- `Ios2WorkerDetails.dc.html`: Worker · personal details
- `Ios2WorkerDocs.dc.html`: Worker · ID and documents
- `Ios2SettingsWorker.dc.html`: Settings · worker
- `Ios2HelpWorker.dc.html`: Help · worker

## v2 · 3 Sales (`3-sales/`)

> One Sales role, two pay types. Meena Jain (agent) types a commission on every customer; it becomes payable when the advance is paid. Aman Gill (salaried) has the same flow with no commission. Both see their customers' install stages.

- `Ios2HubAgent.dc.html`: Home · Agent
- `Ios2AddDetails.dc.html`: New customer · details
- `Ios2AddSite.dc.html`: New customer · site
- `Ios2AddDocs.dc.html`: New customer · documents
- `Ios2AddReview.dc.html`: New customer · review (agent)
- `Ios2AddSent.dc.html`: New customer · sent
- `Ios2AgentCustomers.dc.html`: Customers · agent
- `Ios2AgentCustomer.dc.html`: Customer · detail
- `Ios2AgentSunita.dc.html`: Customer · Sunita Rao (fix KYC)
- `Ios2AgentFix.dc.html`: Agent · re-upload document
- `Ios2AgentArjun.dc.html`: Customer · Arjun Mehra (in review)
- `Ios2AgentHarpal.dc.html`: Customer · Harpal Singh (payable)
- `Ios2AgentGurpreet.dc.html`: Customer · Gurpreet Kaur (paid)
- `Ios2AgentEarnings.dc.html`: Earnings
- `Ios2AgentNotifications.dc.html`: Notifications · agent
- `Ios2AgentProfile.dc.html`: Profile · Agent
- `Ios2AgentBank.dc.html`: Agent · bank for payouts
- `Ios2AgentWorkspaces.dc.html`: Agent · workspaces
- `Ios2SettingsAgent.dc.html`: Settings · agent
- `Ios2HelpAgent.dc.html`: Help · agent
- `Ios2HubSales.dc.html`: Home · Sales employee
- `Ios2SalesDetails.dc.html`: Sales · new customer details
- `Ios2SalesSite.dc.html`: Sales · site
- `Ios2SalesDocs.dc.html`: Sales · documents
- `Ios2SalesReview.dc.html`: Sales · review (no commission)
- `Ios2SalesSent.dc.html`: Sales · sent to admin
- `Ios2SalesCustomers.dc.html`: Customers · sales employee
- `Ios2SalesVikas.dc.html`: Customer · Vikas Kumar (fix KYC)
- `Ios2SalesFix.dc.html`: Sales · re-upload document
- `Ios2SalesRohit.dc.html`: Customer · Rohit Bansal (in review)
- `Ios2SalesNeha.dc.html`: Customer · Neha Gupta (installing)
- `Ios2SalesNotifications.dc.html`: Notifications · sales
- `Ios2SalesProfile.dc.html`: Profile · Sales employee
- `Ios2SalesWorkspaces.dc.html`: Sales · workspaces
- `Ios2SettingsSales.dc.html`: Settings · sales
- `Ios2HelpSales.dc.html`: Help · sales

## v2 · 4 Customer (`4-customer/`)

> Rajinder Kaur, added by Meena. Welcome email, set password, then track the install, pay the advance (this makes Meena's commission payable), message Arka Solar. Prototype link on Home shows the after-handover energy home.

- `Ios2CustEmail.dc.html`: Welcome email
- `Ios2SetPassword.dc.html`: Set password
- `Ios2HubCustomer.dc.html`: Home · Customer
- `Ios2CustTrack.dc.html`: Customer · track install
- `Ios2CustPayments.dc.html`: Customer · payments
- `Ios2CustSupport.dc.html`: Customer · messages
- `Ios2HubCustomerLive.dc.html`: Home · Customer, live
- `Ios2CustNotifications.dc.html`: Customer · notifications
- `Ios2CustProfile.dc.html`: Customer · profile
- `Ios2CustDocs.dc.html`: Customer · documents
- `Ios2CustWorkspaces.dc.html`: Customer · workspaces
- `Ios2SettingsCust.dc.html`: Settings · customer
- `Ios2HelpCust.dc.html`: Help · customer
