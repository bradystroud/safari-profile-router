# URL Router

A native macOS menu bar app that routes URLs to the right Safari profile. Register it as your default browser, define pattern-matching rules, and links from Slack, Teams, email etc. automatically open in the correct profile.

## How it works

1. URLRouter registers as the default browser on macOS
2. When any app opens a URL, macOS hands it to URLRouter
3. The URL is matched against your rules (glob patterns, checked top to bottom)
4. Safari opens the URL in the matched profile's window (or creates a new one)

## Requirements

- macOS Sonoma (14.0+) — Safari profiles were introduced in this version
- Accessibility permission for URLRouter (System Settings > Privacy & Security > Accessibility)

## Install

```bash
./build.sh
cp -r build/URLRouter.app /Applications/
```

Then launch URLRouter and click **Set as Default Browser**.

> **Note:** After each rebuild/reinstall, you'll need to re-add URLRouter.app to the Accessibility permission list in System Settings.

## Usage

### Rules

Rules match URLs using glob patterns:

| Pattern | Matches |
|---|---|
| `*.github.com` | Any github.com subdomain |
| `*jira*` | Any URL with "jira" in the hostname |
| `*/*asfaudits*` | Any URL with "asfaudits" anywhere (full URL match) |
| `mail.google.com` | Exact hostname match |

- Patterns without `/` match against the **hostname** only
- Patterns with `/` match against the **full URL**
- Matching is case-insensitive
- Rules are evaluated top to bottom — first match wins

### Default profile

URLs that don't match any rule open in the default profile (configurable in settings).

### Logs

The **Logs** tab shows real-time routing decisions. Logs are also written to `~/Library/Logs/URLRouter.log`.
