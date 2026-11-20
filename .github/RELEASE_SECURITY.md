# Release workflow security

The release workflows do not run on pushes, pull requests, comments, or
`workflow_run` events. They accept only manual `workflow_dispatch` events from
`ryamazura-cloud`, in this repository, on `refs/heads/main`. Forks and other refs
skip the jobs. GitHub Actions tokens have read-only permissions.

Private credentials belong only to protected GitHub Environments:

| Environment | Credentials | Required approval |
| --- | --- | --- |
| `app-store-signing` | Distribution identity/password, provisioning profile, Firebase configuration | `ryamazura-cloud` |
| `app-store-upload` | App Store Connect upload API credentials | `ryamazura-cloud` |
| `ios-build-config` | Firebase configuration for unsigned builds | `ryamazura-cloud` |

Each environment accepts only the `main` branch. Administrator bypass is
disabled for the environment approval gate. Self-approval is allowed because
the owner is the only release operator; a separate explicit approval is still
required after dispatch. Do not auto-approve pending deployment jobs.

No signing/upload credentials are repository-level secrets. This prevents old
or newly introduced workflows from obtaining credentials without entering a
protected environment. Never move these credentials back to repository or
organization secrets that are accessible to unprotected jobs.

Actions and the Flutter SDK are pinned to reviewed commit IDs. Dependencies
and tests run before the signing identity is installed. Temporary credentials
are removed by `always()` cleanup steps. Artifact uploads include only the
explicit IPA/unsigned application archive, never the signing directory.

App Store uploads must refer to a successful, owner-dispatched, main-branch
run of `ios-app-store.yml` in this repository. The upload workflow verifies the
IPA SHA-256, app identity, App Store profile, and signature before sending it.

Review workflow, dependency, and application changes before authorizing a
release. CODEOWNERS and main-branch protection require owner review for normal
pull request merges. Repository administrators remain responsible for their
intentional changes to repository/environment policies and direct pushes.

The public-readiness audit covers all reachable Git history, workflow logs,
and build artifacts available on 2026-11-20. It combines a redacted secret
scanner with exact matching against the real private signing/upload keys and
password, including encoded forms and files inside IPAs. No private credentials
were found. A reminder preference identifier was reviewed as a false positive.

Firebase client identifiers, bundle IDs, AdMob unit IDs, public certificates,
and provisioning metadata are not private signing keys. They may be present
in distributed applications. Never publish service-account credentials,
private keys, P12/PFX files, keystores, passwords, or decoded secret values.

Before the next release, check the selected Xcode and iOS SDK. Apple requires
iOS 27 SDK / Xcode 27 or later for uploads/submissions starting April 2027.
