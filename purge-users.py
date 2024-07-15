#!/usr/bin/python3
import sys
import requests
import argparse
import os
from datetime import datetime, timedelta, timezone

# Parse command line arguments
parser = argparse.ArgumentParser(
    description="Delete users who haven't received an email in the last 30 days",
    epilog="If the MXG_API_KEY environment variable is not set, you will be prompted for the API key.")
parser.add_argument("domain", nargs="?", help="Process a specific domain")
parser.add_argument("-d","--dry-run", action="store_true", help="Print users instead of deleting them")
args = parser.parse_args()

if args.dry_run:
    print("================ DRY RUN! No changes will be made =================")

# Get the API key from environment variable or prompt for it
api_key = os.environ.get("MXG_API_KEY")
if not api_key:
    print("The MXG_API_KEY environment variable is not set.")
    api_key = input("Enter your MXGuardian API key to continue: ")
    if not api_key:
        print("No API key provided. Exiting.")
        sys.exit()

# Set API base URL
base_url = os.environ.get("MXG_API_URL")
if not base_url:
    base_url = "https://secure.mxguardian.net/api/v1"

# Verify server certificate (replace with path to CA bundle if using self-signed certificate)
verify = True

# Endpoint for retrieving domain list
domain_list_url = f"{base_url}/domains"

# Endpoint for retrieving user list
user_list_url = f"{base_url}/domains/{{domain}}/users"

# Endpoint for retrieving user messages (pagesize=1 to limit results)
afterDate = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat(timespec='seconds')
messages_url = f"{base_url}/users/{{user}}/messages?mode=I&pagesize=1&filter=after:{afterDate}"

# Endpoint for deleting a user
delete_user_url = f"{base_url}/users/{{user_email}}"

# Set the headers
headers = {"Authorization": f"Bearer {api_key}"}

# Initialize count variables
user_count = 0
domain_dict = {}  # Used to count the number of domains that have users deleted

# Get the list of domains
if args.domain:
    domain_list = [{"domain_name": args.domain}]
else:
    response = requests.get(domain_list_url, headers=headers, verify=verify)
    if not response.ok:
        print(f"Error getting domain list. Reason: {response.reason}")
        sys.exit()
    domain_list = response.json()["results"]

# Iterate over the domains
for domain in domain_list:
    domain_name = domain["domain_name"]
    print(f"Processing domain {domain_name}...")

    # Get the list of users for the current domain
    user_list_response = requests.get(user_list_url.format(domain=domain_name), headers=headers, verify=verify)
    if not user_list_response.ok:
        print(f"Error getting user list for domain {domain_name}. Reason: {user_list_response.reason}")
        sys.exit()
    user_list = user_list_response.json()["results"]

    # Iterate over the users
    for user in user_list:
        user_email = user["user_email"]

        # Get the number of messages for the current user in the last 30 days
        messages_response = requests.get(messages_url.format(user=user_email), headers=headers, verify=verify)
        if not messages_response.ok:
            print(f"Error getting messages for {user_email}. Reason: {messages_response.reason}")
            sys.exit()
        message_count = messages_response.json()["count"]

        if message_count == 0:
            if args.dry_run:
                print(f"{user_email} has not received any messages in the last 30 days.")
                user_count += 1
                domain_dict[domain_name] = 1
            else:
                # Delete the user
                delete_user_response = requests.delete(delete_user_url.format(user_email=user_email), headers=headers, verify=verify)
                if delete_user_response.ok:
                    print(f"{user_email} has been deleted.")
                    user_count += 1
                    domain_dict[domain_name] = 1
                else:
                    print(f"Failed to delete user {user_email}. Reason: {delete_user_response.reason}")

if args.dry_run:
    print(f"{user_count} users from {len(domain_dict)} domains would have been deleted.")
else:
    print(f"Deleted {user_count} users from {len(domain_dict)} domains.")