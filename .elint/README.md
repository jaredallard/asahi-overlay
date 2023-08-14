# elint

An ebuild static linter and validator.

## Linting Configuration

This linter configuration is used by the CI to ensure that the overlay
is in a consistent state. It does the following for all ebuilds:

- Ensures that `DESCRIPTION` and `LICENSE` are set.
- Validates that the `Manifest` file is up-to-date.