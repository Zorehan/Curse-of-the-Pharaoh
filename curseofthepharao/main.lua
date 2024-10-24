local curseOfThePharao = RegisterMod("Curse of the Pharao", 1.0)

-- Variant / item variable declarations
local angelicBabyVar = Isaac.GetEntityVariantByName("Angelic Baby")
local angelicBabyItem = Isaac.GetItemIdByName("Angelic Baby")
local glowingAnkhItem = Isaac.GetItemIdByName("Glowing Ankh")

local angelicBaby = nil
local entities = {}
local chestPickupCount = 0
local bumMoveSpeed = 40
local chasingSpeed = 50
local itemFrameCount = 150
local playerDistance = 90
local pickupDistance = 150
local collisionDistance = 30
local bumList = {angelicBabyVar, 24, 64, 88, 90, 102}

debug_text = ""

if not __eidItemDescriptions then
    __eidItemDescriptions = {}
end
__eidItemDescriptions[angelicBabyItem] = "Picks up chests# Drops 1 soul heart per 2 chests consumed, only consumes normal chests"
__eidItemDescriptions[glowingAnkhItem] = "Has a chance to fire a burst of 3 homing tears which deal double damage# Maxes out at 10 luck"

function curseOfThePharao:update()
    local player = Isaac.GetPlayer(0)
    
    -- Handle Angelic Baby Familiar
    if player:HasCollectible(angelicBabyItem) then
        entities = Isaac.GetRoomEntities()
        
        if not angelicBaby then
            for _, entity in ipairs(entities) do
                if entity.Type == 3 and entity.Variant == angelicBabyVar then
                    angelicBaby = entity
                    break
                end
            end
        end
        
        if not angelicBaby then
            angelicBaby = Isaac.Spawn(3, angelicBabyVar, 0, player.Position, player.Velocity, player)
        end
    else
        if angelicBaby then
            angelicBaby:Remove()
            angelicBaby = nil
        end
    end
end



function curseOfThePharao:angelicBabyUpdate(bum)
    if not bum then
        print("Error: bum is nil!")
        return
    end
    
    print("Updating familiar: " .. bum.Variant)
    
    local player = Isaac.GetPlayer(0)
    local givestuff = (chestPickupCount % 2 == 0 and chestPickupCount ~= 0)
    local chasing = false
    local Sprite = bum:GetSprite()
    local playanim = "FloatDown"
    local targetpos = bum.Position
    
    -- Update target position based on player distance
    if targetpos:Distance(player.Position) > playerDistance then
        targetpos = player.Position
    end

    -- Handle item pickups
    for _, entity in ipairs(entities) do
        if entity.Type == 5 and entity.Variant == 50 and entity.FrameCount > itemFrameCount then
            if not entity:ToPickup():IsShopItem() then
                if bum.Position:Distance(entity.Position) <= pickupDistance then
                    targetpos = entity.Position
                    chasing = true
                    givestuff = false
                    if bum.Position:Distance(entity.Position) < 17 then
                        entity:GetSprite():Play("Collect", false)
                    end
                    if bum.Position:Distance(entity.Position) < 3 then
                        SFXManager():Play(54, 1.25, 0, false, 1.0)
                        entity:Remove()
                        chestPickupCount = chestPickupCount + 1
                    end
                    break
                end
            end
        end
    end
    
    -- Handle collision with other familiars
    for _, other in ipairs(entities) do
        if other.Type == 3 and other.Variant ~= bum.Variant then
            local distance = bum.Position:Distance(other.Position)
            if distance <= collisionDistance then
                local nudgeVector = (bum.Position - other.Position):Normalized()
                bum.Position = bum.Position + nudgeVector * 0.005
                other.Position = other.Position - nudgeVector * 3
            end
        end
    end
    
    -- Move familiar towards target
    targetpos = normalizedirection(bum.Position, targetpos, chasing)
    bum:ToFamiliar():FollowPosition(targetpos)

    -- Handle animation and item dropping
    if givestuff and bum.Position:Distance(player.Position) <= playerDistance + 5 then
        playanim = "PreSpawn"
        if Sprite:IsFinished("PreSpawn") then
            playanim = "Spawn"
            chestPickupCount = chestPickupCount - 2
            Isaac.Spawn(5, 10, 3, bum.Position, bum.Velocity, nil)
        end
    end
    if not Sprite:IsPlaying(playanim) and not Sprite:IsPlaying("Spawn") then
        Sprite:Play(playanim, true)
    end
end

function normalizedirection(currentpos, targetpos, chasing)
    local moveVector = targetpos - currentpos
    if chasing then
        moveVector = moveVector:Normalized() * chasingSpeed
    else
        moveVector = moveVector:Normalized() * bumMoveSpeed
    end
    moveVector = currentpos + moveVector
    return moveVector
end

function curseOfThePharao:PostPlayerInit()
    chestPickupCount = 0
    angelicBabyVar = Isaac.GetEntityVariantByName("Angelic Baby")
    bumList = {angelicBabyVar, 24, 64, 88, 90, 102}
    
end

function curseOfThePharao:onTear(tear)

    tear.TearFlags = tear.TearFlags | TearFlags.TEAR_HOMING 

  end

curseOfThePharao:AddCallback(ModCallbacks.MC_POST_UPDATE, curseOfThePharao.update)
curseOfThePharao:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, curseOfThePharao.angelicBabyUpdate, angelicBabyVar)
curseOfThePharao:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, curseOfThePharao.PostPlayerInit)
curseOfThePharao:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, curseOfThePharao.onTear)