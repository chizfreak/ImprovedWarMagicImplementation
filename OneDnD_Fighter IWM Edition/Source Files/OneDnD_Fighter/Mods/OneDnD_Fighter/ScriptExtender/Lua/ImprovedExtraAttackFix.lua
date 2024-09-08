local debugEnabled = false

if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") and Mods.BG3MCM.MCMAPI:GetSettingValue("debugToggle", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac") then
	debugEnabled = Mods.BG3MCM.MCMAPI:GetSettingValue("debugToggle", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac") 
end

local function debugLog(...)
    if debugEnabled then print(...) end
end

local EXTRA_ATTACK_BLOCKED_TAG = "d0e9dcd3-d65c-4c43-933d-af3fd9c30fb0"
local entityStates = {}

local function safeGetEntityUuid(entity)
    local success, result = pcall(function()
        return Ext.Entity.Get(entity).Uuid.EntityUuid
    end)
    if success then
        return result
    else
        debugLog("Error getting entity UUID: " .. tostring(result))
        return nil
    end
end

local function canUseExtraAttack(entity)
    return Osi.HasPassive(entity, "ExtraAttack_2_EK") == 1
       and Osi.IsTagged(entity, EXTRA_ATTACK_BLOCKED_TAG) == 0
       and Osi.HasActiveStatus(entity, "SLAYER_PLAYER") == 0
       and Osi.HasPassive(entity, "WarMagic_EK") == 1
end

local function canUseExtraAttackSpell(entity)
    return Osi.HasPassive(entity, "ImprovedWarMagic_EK") == 1
end

local function applyExtraAttackStatus(entity)
    Osi.ApplyStatus(entity, "EXTRA_ATTACK_2_EK", 6)
    debugLog("Status EXTRA_ATTACK_2_EK applied to " .. tostring(entity))
end

local function applyExtraAttackCantripStatus(entity)
    Osi.ApplyStatus(entity, "EXTRA_ATTACK_2_EK_CANTRIP", 6)
    debugLog("Status EXTRA_ATTACK_2_EK_CANTRIP applied to " .. tostring(entity))
end

local function applyExtraAttackSpellStatus(entity)
    Osi.ApplyStatus(entity, "EXTRA_ATTACK_2_EK_SPELL", 6)
    debugLog("Status EXTRA_ATTACK_2_EK_SPELL applied to " .. tostring(entity))
end

local function removeExtraAttackCantripStatus(entity)
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK_CANTRIP")
    debugLog("Removed extra attack cantrip status from " .. tostring(entity))
end

local function removeExtraAttackSpellStatus(entity)
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK_SPELL")
    debugLog("Removed extra attack spell status from " .. tostring(entity))
end

local function removeExtraAttackStatuses(entity)
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK_SPELL")
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK_CANTRIP")
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK")
    debugLog("Removed extra attack statuses from " .. tostring(entity))
end

--------------------------
-----Cleanup-and Init-----
--------------------------
local function resetEntityState(entity)
    local entityUuid = Ext.Entity.Get(entity).Uuid.EntityUuid
    if canUseExtraAttack(entity) then
        entityStates[entityUuid] = { attacksLeft = 3, cantripUsed = false }
        debugLog("Reset state for entity: " .. entityUuid)
    end
end

local function cleanupEntityState(entity)
    local entityUuid = Ext.Entity.Get(entity).Uuid.EntityUuid
    if entityStates[entityUuid] then
        entityStates[entityUuid] = nil
        removeExtraAttackStatuses(entity)
        debugLog("Cleaned up state for entity: " .. entityUuid)
    end
end
---------------------------

local function handleSpellCast(entity, spell, state)
    local spellStats = Ext.Stats.Get(spell)
    local spellUseCost = spellStats.UseCosts
    local splitUseCost = spellUseCost:match("[^;]+")

    if spell == "Shout_ActionSurge" then
        state.cantripUsed = false
        state.attacksLeft = 3
        debugLog("ActionSurge used, resetting attacksLeft to 3")
    end

    debugLog("CantripUsed before check:", state.cantripUsed)
    debugLog("Attacks left before action:", state.attacksLeft)
    if state.attacksLeft > 0 then
        debugLog("Starting with " .. state.attacksLeft .. " attacks left")
        
        if spellStats.Level == 0 and Osi.SpellHasSpellFlag(spell, "IsSpell") == 1 then
            debugLog("Cantrip detected. Checking for use cost...")
            if splitUseCost == "BonusActionPoint:1" or spellUseCost == "BonusActionPoint:1" then
                debugLog("Bonus Action cantrip detected. attacksLeft count and cantripUsed not modified.")
            else
                debugLog("Normal Action catrip detected.")
                state.attacksLeft = state.attacksLeft - 1
                if not state.cantripUsed then
                    debugLog("First cantrip use")
                    state.cantripUsed = true
                    applyExtraAttackStatus(entity)
                    if canUseExtraAttackSpell(entity) and state.attacksLeft >= 2 then
                        applyExtraAttackSpellStatus(entity)
                    else
                        removeExtraAttackSpellStatus(entity)
                    end
                else
                    debugLog("Cantrip already used, no extra attack granted")
                end
                removeExtraAttackCantripStatus(entity)
            end
        elseif spellStats.Level > 0 and Osi.SpellHasSpellFlag(spell, "IsSpell") == 1 then
            debugLog("Leveled Spell detected. Checking for use cost...")
            if splitUseCost == "BonusActionPoint:1" or spellUseCost == "BonusActionPoint:1" then
                debugLog("Bonus Action spell detected. attacksLeft count not modified.")
            else
                debugLog("Normal Action spell detected. Checking for Improved War Magic...")
                if canUseExtraAttackSpell(entity) then
                    debugLog("Improved War Magic detected")
                    if state.attacksLeft > 2 then
                        debugLog("First leveled spell use")
                        applyExtraAttackStatus(entity)
                        if not state.cantripUsed(entity) then
                            applyExtraAttackCantripStatus(entity)
                        end
                        state.attacksLeft = state.attacksLeft - 2
                    else
                        debugLog("First leveled spell use. After use no more attacksLeft, no extra attack granted")
                        state.attacksLeft = 0
                    end
                else
                    debugLog("Improved War Magic NOT detected")
                    debugLog("Used leveled spell without Improved War Magic. attacksLeft set to zero.")
                    state.attacksLeft = 0
                end
                removeExtraAttackSpellStatus(entity)
            end
        elseif Osi.SpellHasSpellFlag(spell, "IsAttack") == 1 or Osi.SpellHasSpellFlag(spell, "IsDefaultWeaponAction") == 1 then
            debugLog("Attack spell detected. Checking use cost...")
            if not state.cantripUsed then
                applyExtraAttackCantripStatus(entity)
            end
            if splitUseCost == "BonusActionPoint:1" or spellUseCost == "BonusActionPoint:1" then
                debugLog("Bonus Action attack detected. attacksLeft count not modified.")
            else
                debugLog("Normal Action attack detected")
                applyExtraAttackStatus(entity)
                state.attacksLeft = state.attacksLeft - 1
            end
            if canUseExtraAttackSpell(entity) and state.attacksLeft >= 2 then
                applyExtraAttackSpellStatus(entity)
            else
                removeExtraAttackSpellStatus(entity)
            end
        else
            debugLog("Used Extra Attack incompatible action: Cleaning up")
            cleanupEntityState(entity)
        end
        debugLog("Attacks left after action: " .. state.attacksLeft)
    end

    
    if state.attacksLeft == 0 then
        removeExtraAttackStatuses(entity)
        entityStates[Ext.Entity.Get(entity).Uuid.EntityUuid] = nil
        debugLog("Removed state for entity: " .. Ext.Entity.Get(entity).Uuid.EntityUuid)
    end
end

-- Listener for spell casts
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(attacker, spell, _, _, _)
    local attackerUuid = Ext.Entity.Get(attacker).Uuid.EntityUuid
    local state = entityStates[attackerUuid]

    -- Initialize state if not already present
    if not state then
        resetEntityState(attacker)
    end

    if state then
        handleSpellCast(attacker, spell, state)
    end
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", resetEntityState)
Ext.Osiris.RegisterListener("EnteredForceTurnBased", 1, "after", resetEntityState)
Ext.Osiris.RegisterListener("TurnEnded", 1, "after", cleanupEntityState)
Ext.Osiris.RegisterListener("LeftForceTurnBased", 1, "after", cleanupEntityState)
