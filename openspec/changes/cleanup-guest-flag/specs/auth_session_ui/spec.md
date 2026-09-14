# auth_session_ui Specification

## Purpose

This specification defines the requirement to replace the persisted `FFAppState().invitado` flag with the session-based `loggedIn` state as the single source of truth for UI authentication branching across the application.

## Requirements

### Requirement: Auth-Driven UI Branching

All UI components MUST use the `loggedIn` state from `BaseAuthUserProvider` to determine whether to render "Guest" or "Authenticated" content.

#### Scenario: Guest View Visibility

- GIVEN the user is not logged in (`loggedIn == false`)
- WHEN a widget that depends on auth state is rendered
- THEN the system MUST display the Guest UI content
- AND it MUST ignore any value previously stored in `FFAppState().invitado`

#### Scenario: Authenticated View Visibility

- GIVEN the user is logged in (`loggedIn == true`)
- WHEN a widget that depends on auth state is rendered
- THEN the system MUST display the Authenticated UI content

#### Scenario: Immediate UI Update on Login

- GIVEN the user is on a page with auth-dependent UI
- WHEN the user successfully logs in and `loggedIn` becomes `true`
- THEN the UI MUST update immediately to show the Authenticated content without requiring a page reload

### Requirement: Removal of Redundant Guest State

The system MUST NOT manually assign values to `FFAppState().invitado` for the purpose of triggering UI states.

#### Scenario: Cleanup of Guest Assignments

- GIVEN the removal of `FFAppState().invitado` as a UI trigger
- WHEN auditing `LoginPageWidget`, `ModalCreateAccountWidget`, `DropdownAccountGuestWidget`, and `MainProfileWidget`
- THEN any assignment to `FFAppState().invitado` that was used solely for UI branching MUST be removed
