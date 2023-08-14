#!/usr/bin/env bash
# Contains function stubs for validating ebuilds.

# inherit is not required for linting of ebuilds currently, so it does
# nothing. Eventually, if we do more static linting validation, we may
# want to implement this further.
inherit() { return 0; }

# version related functions that don't need to work for linting.
ver_cut() { return 0; }
ver_rs() { return 0; }

# cargo_crate_uris is not required for linting of ebuilds currently, noop.
cargo_crate_uris() { return 0; }
