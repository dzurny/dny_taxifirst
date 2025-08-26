## Features

- Taxi NPC spawns at designated location
- Players can interact with taxi driver
- 1-hour cooldown between taxi uses
- Unlimited usage (with cooldown)
- Automatic teleport to destination
- Progress bar, black screen during ride

## Dependencies

- ESX Framework
- ox_lib
- ox_target

## Configuration

The cooldown duration can be changed in `server/main.lua`:

```lua
local COOLDOWN_HOURS = 1  -- Change this value
```

The language can be changed in `client/main.lua`:

## Usage


Players approach the taxi NPC and interact to use the service. After using the taxi, they must wait 1 hour before they can use it again.


