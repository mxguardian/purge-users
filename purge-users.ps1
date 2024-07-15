param(
    [string]$domain,
    [switch]$dryRun,
    [switch]$Help
)

# Display help information
if ($Help) {
    Write-Host "Usage: .\purge-users.ps1 [<domain_name>] [-dryRun] [-Help]"
    Write-Host ""
    Write-Host "Delete users who haven't received an email in the last 30 days"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "  domain_name            Process a specific domain. If not specified, all domains will be processed."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -dryRun                Print users instead of deleting them."
    Write-Host "  -Help                  Display this help message."
    Write-Host ""
    Write-Host "If the MXG_API_KEY environment variable is not set, you will be prompted for your API key."
    exit
}

if ($dryRun) {
	Write-Host "================ DRY RUN! No changes will be made ================="
}

# Check for API key in environment variable
$apiKey = [System.Environment]::GetEnvironmentVariable("MXG_API_KEY")
if (-not $apiKey) {
    Write-Host "The MXG_API_KEY environment variable is not set."
    $apiKey = Read-Host "Enter your MXGuardian API key to continue: "
    if (-not $apiKey) {
        Write-Host "No API key provided. Exiting."
        exit
    }
}

# API base URL
$baseUrl = [System.Environment]::GetEnvironmentVariable("MXG_API_URL")
if (-not $baseUrl) {
	$baseUrl = "https://secure.mxguardian.net/api/v1"
}

# Initialize variables
$userCount = 0
$domainDict = @{}
$afterDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssK")

# Function to make API calls
function Invoke-APIRequest {
    param (
        [string]$url,
        [string]$method = 'GET'
    )
    $headers = @{
        "Authorization" = "Bearer $script:apiKey";
		"Content-Type" = "application/json";
		"Accept" = "application/json"
    }
	try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method $method
        return $response
    } catch {
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Host "HTTP Error: $statusCode - $statusDescription"
        } else {
            Write-Host "An error occurred: $_"
        }
        exit
    }
}

# Get the list of domains
if ($domain) {
    $domainList = @(@{ "domain_name" = $domain })
} else {
    $domainListUrl = "$baseUrl/domains"
    $response = Invoke-APIRequest -url $domainListUrl
    $domainList = $response.results
}

# Iterate over the domains
foreach ($d in $domainList) {
    $domainName = $d.domain_name
    Write-Host "Processing domain $domainName..."

    # Get the list of users for the current domain
    $userListUrl = "$baseUrl/domains/$domainName/users"
    $userListResponse = Invoke-APIRequest -url $userListUrl
    $userList = $userListResponse.results

    # Iterate over the users
    foreach ($user in $userList) {
        $userEmail = $user.user_email

        # Get the number of messages for the current user in the last 30 days
        $messagesUrl = "$baseUrl/users/$userEmail/messages?mode=I&pagesize=1&filter=after:$afterDate"
        $messagesResponse = Invoke-APIRequest -url $messagesUrl
        $messageCount = $messagesResponse.count

        if ($messageCount -eq 0) {
            if ($dryRun) {
                Write-Host "$userEmail has not received any messages in the last 30 days."
                $userCount++
                $domainDict[$domainName] = 1
            } else {
                # Delete the user
                $deleteUserUrl = "$baseUrl/users/$userEmail"
                $deleteUserResponse = Invoke-APIRequest -url $deleteUserUrl -method 'DELETE'
                if ($deleteUserResponse -eq "") {
                    Write-Host "$userEmail has been deleted."
                    $userCount++
                    $domainDict[$domainName] = 1
                } else {
                    Write-Host "Failed to delete user $userEmail."
                    Write-Host $deleteUserResponse
                }
            }
        }
    }
}

if ($dryRun) {
    Write-Host "$userCount users from $($domainDict.Count) domains would have been deleted."
} else {
    Write-Host "Deleted $userCount users from $($domainDict.Count) domains."
}
