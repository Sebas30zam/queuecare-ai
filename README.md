# QueueCare AI

QueueCare AI is an intelligent queue and service-attention management system designed to organize the complete customer journey, from ticket creation to service completion and satisfaction feedback.

The project is being developed as a university MVP with a professional structure and the potential to serve as the foundation for a real operational system.

## Project Goal

QueueCare AI aims to reduce unnecessary waiting lines, organize tickets by service and priority, control the service lifecycle, and collect operational data that can later be used for dashboards and intelligent recommendations.

Once completed, the system will help organizations:

* Track waiting and service times.
* Identify overloaded services and peak-demand periods.
* Measure completed, pending, cancelled, and no-show tickets.
* Analyze customer satisfaction.
* Improve staff and service-window allocation.
* Consider public holidays when analyzing demand.
* Generate AI-assisted operational recommendations.

## Current Status

The main operational workflow is already implemented:

```text
Ticket creation
→ Pending queue
→ Agent calls next ticket
→ Ticket appears on the public screen
→ Agent starts attention
→ Agent finishes attention
→ Customer submits a satisfaction survey
```

The next planned phase is the **Operational Dashboard Foundation**.

## Main Features

### Authentication and Authorization

* Login and logout using Rails sessions.
* Role-based access control.
* Server-side authorization.
* Current user information shared with React through InertiaJS.

### User Management Foundation

* User list.
* Name, email, role, and active status.
* Accessible to administrators and supervisors.

> The current module is read-only. Creating, editing, and deleting users from the panel is not implemented yet.

### Queue Services

* Service list.
* Unique service codes.
* Description and active status.
* Estimated attention time.

> The current module is read-only. Full service CRUD is not implemented yet.

### Service Windows

* Service-window list.
* Each window belongs to a specific queue service.
* Agents only access tickets associated with the selected window's service.

### Self-Service Ticket Intake

* Public access without authentication.
* Customers select a service.
* Optional assistance categories:

  * Disability
  * Senior adult
  * Pregnancy
  * Scheduled appointment
* No personal information is required.
* Normal priority is assigned automatically.
* Daily ticket numbering by service, such as `ADM-001` or `FIN-002`.

### Assisted Ticket Intake

* Available to administrators and receptionists.
* Used when a customer cannot use Self-Service or requires assistance.
* Records the employee who created the ticket.

### Agent Queue

* Service-window selection.
* Pending ticket queue filtered by service.
* Priority and arrival-order selection.
* Call-next workflow.
* Active-ticket protection for agents and service windows.

Tickets are selected using:

1. `priority_weight`
2. `created_at`
3. `id`

Database transactions and `FOR UPDATE SKIP LOCKED` are used to prevent two agents from calling the same ticket.

### Attention Lifecycle

Implemented ticket transitions:

```text
pending → called → in_attention → attended
```

The system records:

* Assigned agent.
* Service window.
* Call time.
* Attention start time.
* Attention finish time.

### No-Show Handling

Implemented transition:

```text
called → no_show
```

The agent must wait at least 15 seconds after calling the ticket before marking it as no-show.

### Ticket Cancellation

Implemented transition:

```text
pending → cancelled
```

Only administrators and receptionists can cancel pending tickets.

### Public Screen

* Public route without authentication.
* Displays active called and in-attention tickets.
* Shows ticket number, service, window, status, and call time.
* Includes recently called tickets.
* Refreshes every five seconds using Inertia polling.

### Satisfaction Survey

* Public survey linked to an attended ticket.
* Uses a secure and unique `survey_token`.
* Rating from 1 to 5.
* Optional comment.
* Only one response is allowed per ticket.
* Only available when the ticket is attended and has a finish time.

> The survey is functional, but automatic delivery of the survey link or QR code to the customer is not implemented yet.

## Ticket States

The current ticket states are:

* `pending`
* `called`
* `in_attention`
* `attended`
* `no_show`
* `cancelled`

## User Roles

### Admin

Can access:

* Users
* Queue services
* Service windows
* Assisted ticket intake
* Agent queue
* Administrative functionality

### Receptionist

Can access:

* Assisted ticket intake
* Assisted ticket creation
* Pending ticket cancellation

### Agent

Can access:

* Agent queue
* Call next ticket
* Start attention
* Finish attention
* Mark no-show

### Supervisor

Can access:

* Users
* Queue services
* Service windows
* Allowed administrative views

## Technology Stack

* Ruby 3.4.9
* Ruby on Rails 8.1.3
* PostgreSQL
* Vite
* InertiaJS
* React
* TypeScript
* Tailwind CSS
* Rails sessions

## Architecture

QueueCare AI uses a Rails monolith.

Rails is responsible for:

* Routes
* Sessions
* Authentication
* Authorization
* Business logic
* Controllers
* Service objects
* PostgreSQL access

React is responsible for:

* User interfaces
* Forms
* Visual state
* User interaction

InertiaJS connects Rails and React without requiring a separate REST API.

The project does not use:

* Rails API-only mode
* JWT authentication
* Separate frontend and backend applications

## Main Models

* `Role`
* `User`
* `QueueService`
* `ServiceWindow`
* `DailySequence`
* `Ticket`
* `SatisfactionSurvey`

## Service Objects

* `Tickets::CreateTicketService`
* `Tickets::CallNextTicketService`
* `Tickets::StartAttentionService`
* `Tickets::FinishAttentionService`
* `Tickets::MarkNoShowService`
* `Tickets::CancelTicketService`
* `SatisfactionSurveys::CreateSurveyService`

## Main Routes

### Authentication

| Method | Route     | Description        |
| ------ | --------- | ------------------ |
| GET    | `/`       | Authenticated home |
| GET    | `/login`  | Login form         |
| POST   | `/login`  | Create session     |
| DELETE | `/logout` | End session        |

### Administration

| Method | Route              | Access            |
| ------ | ------------------ | ----------------- |
| GET    | `/users`           | Admin, Supervisor |
| GET    | `/queue_services`  | Admin, Supervisor |
| GET    | `/service_windows` | Admin, Supervisor |

### Ticket Intake

| Method | Route                   | Access              |
| ------ | ----------------------- | ------------------- |
| GET    | `/self-service`         | Public              |
| POST   | `/self-service/tickets` | Public              |
| GET    | `/tickets/reception`    | Admin, Receptionist |
| POST   | `/tickets`              | Admin, Receptionist |
| PATCH  | `/tickets/:id/cancel`   | Admin, Receptionist |

### Agent Queue

| Method | Route                              | Description      |
| ------ | ---------------------------------- | ---------------- |
| GET    | `/agent-queue`                     | Agent queue      |
| POST   | `/agent-queue/call-next`           | Call next ticket |
| PATCH  | `/agent-queue/tickets/:id/start`   | Start attention  |
| PATCH  | `/agent-queue/tickets/:id/finish`  | Finish attention |
| PATCH  | `/agent-queue/tickets/:id/no-show` | Mark no-show     |

### Public Features

| Method | Route                                | Description          |
| ------ | ------------------------------------ | -------------------- |
| GET    | `/public-screen`                     | Waiting-room display |
| GET    | `/satisfaction-survey/:survey_token` | Survey form          |
| POST   | `/satisfaction-survey/:survey_token` | Submit survey        |

## Demo Accounts

All demo users use the password:

```text
password123
```

| Role         | Email                        |
| ------------ | ---------------------------- |
| Admin        | `admin@queuecare.com`        |
| Receptionist | `receptionist@queuecare.com` |
| Agent        | `agent@queuecare.com`        |
| Supervisor   | `supervisor@queuecare.com`   |

## Local Setup

### Requirements

* Ruby 3.4.9
* Rails 8.1.3
* PostgreSQL
* Node.js 22 or compatible
* Bundler
* npm

### Installation

Clone the repository:

```bash
git clone https://github.com/Sebas30zam/queuecare-ai.git
cd queuecare-ai
```

Install dependencies:

```bash
bundle install
npm install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Load demo data when needed:

```bash
bin/rails db:seed
```

Start the development environment:

```bash
bin/dev
```

Open:

```text
http://localhost:3000
```

## Testing and Validation

Run the Rails test suite:

```bash
VITE_RUBY_AUTO_BUILD=false bin/rails test
```

Run the TypeScript check:

```bash
npm run check
```

Build the frontend in test mode:

```bash
bin/vite build --mode=test
```

Check Git whitespace errors:

```bash
git diff --check
```

Latest confirmed test result:

```text
172 tests
655 assertions
0 failures
0 errors
0 skips
```

## Git Workflow

The project uses:

* `main` as the stable branch.
* `development` as the integration branch.
* `feature/*` branches for individual features.

Each feature is developed and tested separately, committed using Conventional Commits, and merged into `development` with a non-fast-forward merge.

## Roadmap

### Completed Foundations

* Authentication and authorization
* User management list
* Queue services list
* Service windows list
* Self-Service ticket intake
* Assisted ticket intake
* Agent queue
* Attention lifecycle
* No-show handling
* Ticket cancellation
* Public screen
* Satisfaction survey

### Planned Phases

1. Operational Dashboard Foundation
2. Public Holidays Integration
3. AI Recommendations
4. Demo Data and Final Polish

Possible future extensions such as QR delivery, email, SMS, WhatsApp, advanced reports, exports, and WebSockets are not part of the current implemented scope.

## Project Purpose

QueueCare AI is currently an academic MVP, but its architecture and development workflow are designed to support continued growth into a more complete operational queue-management platform.
