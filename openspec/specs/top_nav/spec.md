# TopNavWidget Specification

## Purpose

The `TopNavWidget` provides the primary navigation bar at the top of the application, displaying the user's authentication state, notifications, and access to account settings.

## Requirements

### Requirement: Authentication-based UI Transition

The `TopNavWidget` MUST display different UI elements and trigger different actions based on whether the user is authenticated or acting as a guest.

#### Scenario: Authenticated User

- GIVEN the user is logged in (`loggedIn == true`)
- WHEN the `TopNavWidget` is rendered
- THEN the system MUST display the user's profile picture from the `UsuariosTable`
- AND the system MUST display the user's name from the `UsuariosTable`
- AND clicking the profile area MUST open the `DropdownAccountWidget`

#### Scenario: Guest User

- GIVEN the user is not logged in (`loggedIn == false`)
- AND the user is marked as a guest (`FFAppState().invitado == true`)
- WHEN the `TopNavWidget` is rendered
- THEN the system MUST display the guest asset (`assets/images/guestUser.png`)
- AND clicking the profile area MUST open the `DropdownAccountGuestWidget`

#### Scenario: Unauthenticated Non-Guest (Fallback)

- GIVEN the user is not logged in (`loggedIn == false`)
- AND the user is not marked as a guest (`FFAppState().invitado == false`)
- WHEN the `TopNavWidget` is rendered
- THEN the system MUST default to the Guest UI behavior
- AND display the guest asset (`assets/images/guestUser.png`)
- AND clicking the profile area MUST open the `DropdownAccountGuestWidget`
