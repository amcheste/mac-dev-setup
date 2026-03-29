# Security Policy

## Supported Versions

Only the latest release is actively maintained.

| Version | Supported |
|---------|-----------|
| latest  | ✅        |
| older   | ❌        |

## Reporting a Vulnerability

**Please do not open a public issue for security vulnerabilities.**

Use GitHub's [private vulnerability reporting](https://github.com/amcheste/mac-dev-setup/security/advisories/new) to report issues confidentially. This ensures the vulnerability can be assessed and patched before public disclosure.

Please include:
- A clear description of the vulnerability
- Steps to reproduce
- Potential impact

You can expect an acknowledgement within **7 days** and a resolution or status update within **30 days**.

## Scope

Security-relevant areas in this project:

| Area | Concern |
|------|---------|
| `dotfiles/secrets.template` | Must never contain real credentials — only placeholder slots |
| `scripts/setup-credentials.sh` | Credential prompting and `~/.secrets` file handling |
| `setup.sh` | Bootstrap execution — runs with user privileges on a fresh machine |
| `.github/workflows/` | CI/CD pipeline integrity and secret handling |

## Out of Scope

- Preference changes or tool version bumps
- Issues with third-party tools installed by the Brewfile (report those upstream)
