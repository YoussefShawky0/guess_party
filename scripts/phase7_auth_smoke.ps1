param(
  [string]$ApiUrl = 'http://127.0.0.1:54321',
  [Parameter(Mandatory = $true)]
  [string]$PublishableKey
)

$ErrorActionPreference = 'Stop'
$headers = @{ apikey = $PublishableKey }
$suffix = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$password = 'Phase7-test-password-123!'

function Invoke-AuthJson {
  param(
    [Parameter(Mandatory = $true)] [string]$Method,
    [Parameter(Mandatory = $true)] [string]$Path,
    [Parameter(Mandatory = $true)] [hashtable]$Body,
    [string]$AccessToken
  )
  $requestHeaders = @{} + $headers
  if ($AccessToken) {
    $requestHeaders.Authorization = "Bearer $AccessToken"
  }
  Invoke-RestMethod `
    -Method $Method `
    -Uri "$ApiUrl/auth/v1/$Path" `
    -Headers $requestHeaders `
    -ContentType 'application/json' `
    -Body ($Body | ConvertTo-Json -Depth 5)
}

function Invoke-ApiJson {
  param(
    [Parameter(Mandatory = $true)] [string]$Method,
    [Parameter(Mandatory = $true)] [string]$Path,
    [Parameter(Mandatory = $true)] [string]$AccessToken,
    [hashtable]$Body
  )
  $request = @{
    Method = $Method
    Uri = "$ApiUrl/$Path"
    Headers = @{
      apikey = $PublishableKey
      Authorization = "Bearer $AccessToken"
    }
    ContentType = 'application/json'
  }
  if ($null -ne $Body) {
    $request.Body = $Body | ConvertTo-Json -Depth 8
  }
  Invoke-RestMethod @request
}

function New-TestGuest {
  param([string]$DisplayName)
  Invoke-AuthJson -Method Post -Path 'signup' -Body @{
    data = @{
      display_name = $DisplayName
      username = $DisplayName
      is_guest = $true
    }
  }
}

function Assert-Equal {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "$Name failed: expected '$Expected', received '$Actual'."
  }
  Write-Output "PASS $Name"
}

$realEmail = "phase7-real-$suffix@example.com"
$real = Invoke-AuthJson -Method Post -Path 'signup' -Body @{
  email = $realEmail
  password = $password
  data = @{ display_name = 'Same Global Name'; username = 'Same Global Name' }
}
Assert-Equal $real.user.email $realEmail 'real-email registration'
Assert-Equal $real.user.user_metadata.display_name 'Same Global Name' 'separate display name'

$realLogin = Invoke-AuthJson -Method Post -Path 'token?grant_type=password' -Body @{
  email = $realEmail
  password = $password
}
Assert-Equal $realLogin.user.id $real.user.id 'real-email login UID'

$legacyUsername = "legacy_$suffix"
$legacyEmail = "$legacyUsername@guessparty.com"
$legacy = Invoke-AuthJson -Method Post -Path 'signup' -Body @{
  email = $legacyEmail
  password = $password
  data = @{ display_name = 'Legacy Player'; username = 'Legacy Player' }
}
$legacyLogin = Invoke-AuthJson -Method Post -Path 'token?grant_type=password' -Body @{
  email = $legacyEmail
  password = $password
}
Assert-Equal $legacyLogin.user.id $legacy.user.id 'legacy username compatibility login'

$guest = Invoke-AuthJson -Method Post -Path 'signup' -Body @{
  data = @{ display_name = 'Guest Upgrade'; username = 'Guest Upgrade'; is_guest = $true }
}
Assert-Equal $guest.user.is_anonymous $true 'anonymous guest sign-in'
$guestId = $guest.user.id
$upgradeEmail = "phase7-guest-$suffix@example.com"
$upgraded = Invoke-AuthJson -Method Put -Path 'user' -AccessToken $guest.access_token -Body @{
  email = $upgradeEmail
  data = @{ display_name = 'Guest Upgrade'; username = 'Guest Upgrade'; is_guest = $false }
}
Assert-Equal $upgraded.id $guestId 'guest upgrade UID preservation'
Assert-Equal $upgraded.email $upgradeEmail 'guest upgrade real email'

$duplicateEmail = "phase7-duplicate-$suffix@example.com"
$duplicate = Invoke-AuthJson -Method Post -Path 'signup' -Body @{
  email = $duplicateEmail
  password = $password
  data = @{ display_name = 'Same Global Name'; username = 'Same Global Name' }
}
if ($duplicate.user.id -eq $real.user.id) {
  throw 'duplicate global display names unexpectedly produced the same UID.'
}
Write-Output 'PASS duplicate global display names retain distinct UIDs'

$existingRecovery = Invoke-WebRequest `
  -Method Post `
  -Uri "$ApiUrl/auth/v1/recover" `
  -Headers $headers `
  -ContentType 'application/json' `
  -Body (@{ email = $realEmail } | ConvertTo-Json)
$missingRecovery = Invoke-WebRequest `
  -Method Post `
  -Uri "$ApiUrl/auth/v1/recover" `
  -Headers $headers `
  -ContentType 'application/json' `
  -Body (@{ email = "missing-$suffix@example.com" } | ConvertTo-Json)
Assert-Equal $existingRecovery.StatusCode 200 'existing-account recovery request'
Assert-Equal $missingRecovery.StatusCode 200 'missing-account recovery request'

$categories = @(
  Invoke-ApiJson `
    -Method Get `
    -Path 'rest/v1/categories?select=key&is_active=eq.true&order=sort_order&limit=1' `
    -AccessToken $realLogin.access_token
)
$category = $categories[0].key
if (-not $category) {
  throw 'No active seeded category is available for gameplay compatibility.'
}

$onlineRoom = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/create_room' `
  -AccessToken $realLogin.access_token -Body @{
    p_request_id = [guid]::NewGuid().ToString()
    p_category = $category
    p_max_rounds = 1
    p_max_players = 8
    p_round_duration = 60
    p_game_mode = 'online'
    p_host_username = "P$suffix"
    p_local_names = @()
  }
$onlineGuests = @(
  (New-TestGuest "A$suffix"),
  (New-TestGuest "B$suffix"),
  (New-TestGuest "C$suffix")
)
for ($index = 0; $index -lt $onlineGuests.Count; $index++) {
  $null = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/join_room' `
    -AccessToken $onlineGuests[$index].access_token -Body @{
      p_room_code = $onlineRoom.room.room_code
      p_username = "G$index$suffix"
    }
}
$onlineRound = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/start_game' `
  -AccessToken $realLogin.access_token -Body @{
    p_room_id = $onlineRoom.room.id
  }
$null = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/advance_to_voting' `
  -AccessToken $realLogin.access_token -Body @{ p_round_id = $onlineRound }
$onlineResult = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/finalize_voting' `
  -AccessToken $realLogin.access_token -Body @{
    p_round_id = $onlineRound
    p_reason = 'host_skip'
  }
$null = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/finish_game' `
  -AccessToken $realLogin.access_token -Body @{ p_room_id = $onlineRoom.room.id }
$onlineStatus = @(
  Invoke-ApiJson -Method Get `
    -Path "rest/v1/rooms?select=status&id=eq.$($onlineRoom.room.id)" `
    -AccessToken $realLogin.access_token
)[0].status
Assert-Equal $onlineResult.phase 'results' 'online persistent/guest results phase'
Assert-Equal $onlineStatus 'finished' 'online persistent/guest game completion'

$sharedHost = New-TestGuest "S$suffix"
$sharedRoom = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/create_room' `
  -AccessToken $sharedHost.access_token -Body @{
    p_request_id = [guid]::NewGuid().ToString()
    p_category = $category
    p_max_rounds = 1
    p_max_players = 8
    p_round_duration = 60
    p_game_mode = 'local'
    p_host_username = "S$suffix"
    p_local_names = @(
      "L1$suffix",
      "L2$suffix",
      "L3$suffix"
    )
  }
$sharedRound = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/start_game' `
  -AccessToken $sharedHost.access_token -Body @{ p_room_id = $sharedRoom.room.id }
$null = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/advance_to_voting' `
  -AccessToken $sharedHost.access_token -Body @{ p_round_id = $sharedRound }
$sharedResult = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/finalize_voting' `
  -AccessToken $sharedHost.access_token -Body @{
    p_round_id = $sharedRound
    p_reason = 'host_skip'
  }
$null = Invoke-ApiJson -Method Post -Path 'rest/v1/rpc/finish_game' `
  -AccessToken $sharedHost.access_token -Body @{ p_room_id = $sharedRoom.room.id }
$sharedStatus = @(
  Invoke-ApiJson -Method Get `
    -Path "rest/v1/rooms?select=status&id=eq.$($sharedRoom.room.id)" `
    -AccessToken $sharedHost.access_token
)[0].status
Assert-Equal $sharedResult.phase 'results' 'shared-device guest results phase'
Assert-Equal $sharedStatus 'finished' 'shared-device guest game completion'

Write-Output 'Phase 7 local Auth API smoke: PASS'
