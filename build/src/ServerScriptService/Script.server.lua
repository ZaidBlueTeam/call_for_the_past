
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create the character lock event if it doesn't exist
local characterLockEvent = ReplicatedStorage:FindFirstChild("CharacterLockEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
characterLockEvent.Name = "CharacterLockEvent"

-- Table to track locked characters
local lockedCharacters = {}

-- Handle character lock requests
ReplicatedStorage.CharacterSelectedEvent.OnServerEvent:Connect(function(player, characterName)
    -- Lock the character
    table.insert(lockedCharacters, {
        player = player,
        name = characterName
    })
    
    -- Notify all clients about the locked character
    characterLockEvent:FireAllClients(player.Name, characterName, true)
end)

-- When player leaves, unlock their character
Players.PlayerRemoving:Connect(function(player)
    for i, lockedChar in ipairs(lockedCharacters) do
        if lockedChar.player == player then
            characterLockEvent:FireAllClients(player.Name, lockedChar.name, false)
            table.remove(lockedCharacters, i)
            break
        end
    end
end)

-- Reset locked characters when round ends
ReplicatedStorage.StartRoundEvent.OnServerEvent:Connect(function()
    lockedCharacters = {}
end)

print("Character locking server script loaded!")