# purge-users
A Python script that connects to the MXGuardian API and deletes old users

# Usage

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

# Copyright and License

Copyright (C) 2023 MXGuardian LLC

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License v3.0. See the LICENSE file included with this distribution for more information.

This plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
