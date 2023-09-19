# purge-users
A collection of scripts that connect to the MXGuardian API and deletes old users

# Installation

Depending on your language preference, download one of the following files:

* [purge-users.py](https://raw.githubusercontent.com/mxguardian/purge-users/master/purge-users.py) (Python3)
* [purge-users.ps1](https://raw.githubusercontent.com/mxguardian/purge-users/master/purge-users.ps1) (PowerShell)

# Python Usage

```
usage: purge-users.py [-h] [-d] [domain]

Delete users who haven't received an email in the last 30 days

positional arguments:
  domain Process a specific domain. Leave blank to process all domains

optional arguments:
  -h, --help show this help message and exit
  -d, --dry-run Print users instead of deleting them

If the MXG_API_KEY environment variable is not set, you will be prompted for the API key.
```

# PowerShell Usage

```
Usage: .\purge-users.ps1 [<domain_name>] [-dryRun] [-Help]

Delete users who haven't received an email in the last 30 days

Arguments:
  domain_name            Process a specific domain. If not specified, all domains will be processed.

Options:
  -dryRun                Print users instead of deleting them.
  -Help                  Display this help message.

If the MXG_API_KEY environment variable is not set, you will be prompted for your API key.
```

# Copyright and License

Copyright (C) 2023 MXGuardian LLC

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License v3.0. See the LICENSE file included with this distribution for more information.

This plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
