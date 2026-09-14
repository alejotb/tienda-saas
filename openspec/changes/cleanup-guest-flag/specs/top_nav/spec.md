# Delta for top_nav

## MODIFIED Requirements

### Requirement: Authentication-based UI Transition

The `TopNavWidget` MUST display different UI elements and trigger different actions based on whether the user is authenticated or not.
(Previously: The `TopNavWidget` MUST display different UI elements and trigger different actions based on whether the user is authenticated or acting as a guest.)

#### Scenario: Authenticated User

- GIVEN the user is logged in (`loggedIn == true`)
- WHEN the `TopNavWidget` is rendered
- THEN the system MUST display the user's profile picture from the `UsuariosTable`
- AND the system MUST display the user's name from the `UsuariosTable`
- AND clicking the profile area MUST open the `DropdownAccountWidget`

#### Scenario: Guest User

- GIVEN the user is not logged in (`loggedIn == false`)
- WHEN the `TopNavWidget` is rendered
- THEN the system MUST display the guest asset (`assets/images/guestUser.png`)
- AND clicking the profile area MUST open the `DropdownAccountGuestWidget`
