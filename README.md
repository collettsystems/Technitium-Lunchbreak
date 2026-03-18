# Technitium Scheduled Domain Blocking Scripts

Cron-ready shell scripts for **Technitium DNS Server** that automate scheduled domain blocking and unblocking from a shared domain list.

## Overview

This project provides a simple, maintainable way to enforce **time-based DNS access rules** with Technitium DNS Server. It is designed to work with `cron`, a shared configuration file, and a common `domains.txt` list so you can block and later unblock the same set of domains on a schedule.

The scripts use the **Technitium API** to add domains to the blocked list and remove them later, making it possible to automate recurring access policies without manually changing Technitium settings through the web UI.

## Why This Exists

Managing scheduled DNS restrictions by hand is tedious and error-prone. This repository makes the process:

- repeatable
- easy to audit
- easy to schedule
- easy to customize

Common use cases include parental controls, distraction blocking, overnight restrictions, business-hour access policies, and lab or kiosk environments.

## Features

- Cron-ready shell scripts
- Shared `domains.txt` file for both blocking and unblocking
- Shared configuration file for server URL, API token, and related options
- Separate scripts for block and unblock actions
- Basic logging and error handling
- Simple structure that is easy to review and modify
- No manual Technitium UI changes required for daily operation

## Current Scope

This release focuses on the core workflow:

- block a set of domains
- unblock the same set later
- run unattended from cron

Cache invalidation is **not included in this release**.  It didn't seem necessary in my testing.

## Repository Structure

```text
.
├── technitium-block.sh
├── technitium-unblock.sh
├── technitium-common.sh
├── config.example.env
├── config.env                # create this from the example file
├── domains.txt
└── README.md
```

## Requirements

- Ubuntu or another Linux system with:
  - `bash`
  - `curl`
  - `cron`
  - `jq` or `python`
- A running **Technitium DNS Server**
- A valid **Technitium API token**
- Network access from the host running the scripts to the Technitium server

## How It Works

1. Add domains to `domains.txt`, one per line.
2. Copy `config.example.env` to `config.env`.
3. Set your Technitium server URL and API token.
4. Schedule the block and unblock scripts with `cron`.
5. At the scheduled time:
   - the block script adds each domain to Technitium’s blocked zones
   - the unblock script removes each domain from Technitium’s blocked zones

Because both scripts use the same domain list, the block and unblock operations stay aligned.

## Domain List Format

The `domains.txt` file should contain **one domain per line**:

```text
facebook.com
instagram.com
youtube.com
reddit.com
```

Recommended conventions:

- do not include `http://` or `https://`
- do not include paths
- use plain domain names only
- blank lines are fine if your script ignores them
- comments are allowed

## Configuration

Copy the example config:

```bash
cp config.example.env config.env
```

Then edit it with your environment values.

Example:

```bash
TECHNITIUM_BASE_URL="http://192.168.1.10:5380"
TECHNITIUM_API_TOKEN="your_api_token_here"
```

Typical configuration values include:

- `TECHNITIUM_BASE_URL` — base URL of the Technitium server
- `TECHNITIUM_API_TOKEN` — API token for authentication
- optional logging or behavior flags depending on your script implementation

## Installation

Clone the repository:

```bash
git clone https://github.com/yourname/technitium-scheduled-blocking.git
cd technitium-scheduled-blocking
```

Create your local config:

```bash
cp config.example.env config.env
```

Edit the config and domain list:

```bash
nano config.env
nano domains.txt
```

Make the scripts executable:

```bash
chmod +x technitium-common.sh technitium-block.sh technitium-unblock.sh
```

## Manual Testing

Before using cron, test both scripts manually.

Block domains:

```bash
./technitium-block.sh
```

Unblock domains:

```bash
./technitium-unblock.sh
```

This helps confirm:

- the Technitium server is reachable
- the API token is valid
- the domain list is formatted correctly
- the scripts behave as expected in your environment

## Cron Setup

Open your crontab:

```bash
crontab -e
```

Example schedule:

```cron
0 21 * * * /bin/bash /path/to/technitium-block.sh
0 7  * * * /bin/bash /path/to/technitium-unblock.sh
```

This example:

- blocks domains every day at **9:00 PM**
- unblocks them every day at **7:00 AM**

Cron uses **24-hour time**.

## Time Zone Notes

Cron runs according to the server’s configured local time.


## Security Notes

- Treat your API token like a password.
- Do not commit `config.env` to Git.
- Consider adding `config.env` to `.gitignore`.
- Limit file permissions where appropriate.

Example:

```bash
chmod 600 config.env
```

Recommended `.gitignore` entry:

```gitignore
config.env
```

## Example Use Cases

- Block social media during work hours
- Disable selected domains overnight
- Apply parental controls on a schedule
- Restrict access in classrooms, labs, or kiosk environments
- Enforce recurring network access policies with minimal manual effort

## Design Goals

This project is intentionally simple:

- easy to read
- easy to audit
- easy to run from cron
- easy to adapt to different schedules and environments

It is meant to be a lightweight automation layer on top of Technitium’s API rather than a large management system.

## Limitations

- This release does not include cache invalidation (seems unnecessary in testing)
- The scripts assume Technitium is already configured and reachable

## Future Improvements

Potential future enhancements may include:

- bulk operations for large domain sets
- email notifications
- optional dry-run mode
- optional logging improvements
- optional domain validation
- optional cache management
- support for multiple domain groups or schedules
- but probably not any of that

## Contributing

Issues and pull requests are welcome for improvements, cleanup, and portability fixes.

If you contribute, please keep changes aligned with the project’s main goals:

- minimal dependencies
- predictable behavior
- cron-friendly operation

## License

- MIT


## Disclaimer

Use these scripts at your own risk. Review the code, test in your environment, and confirm the resulting Technitium behavior before relying on it in production or on a family network.

