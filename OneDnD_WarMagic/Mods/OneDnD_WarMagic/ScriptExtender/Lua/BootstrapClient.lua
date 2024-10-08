local CF_MOD_GUID = "67fbbd53-7c7d-4cfa-9409-6d737b4d92a9"
local MCM_MOD_GUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"
local MOD_GUID = "7429b169-5e11-4d31-9db3-b1285df2d191"

if not Ext.Mod.IsModLoaded(CF_MOD_GUID) then return end

local function getConfigSettings()
    local defaults = {improvedExtraAttackFix = true}
    
    if not Ext.Mod.IsModLoaded(MCM_MOD_GUID) then return defaults end
    
    return {
        improvedExtraAttackFix = Mods.BG3MCM.MCMAPI:GetSettingValue("improvedExtraAttackFix", MOD_GUID)
    }
end


local function createExtraAttackPayloads(settings)
    if not settings.improvedExtraAttackFix then return {} end

    return {
        {
            modGuid = MOD_GUID,
            Target = "d393b47c-629b-4c26-a857-741f9ef2eff2",
            FileType = "Progression",
            Type = "PassivesAdded",
            Strings = {"ExtraAttack_2_EK"}
        },
  		{
		    modGuid = MOD_GUID,
            Target = "d393b47c-629b-4c26-a857-741f9ef2eff2",
            FileType = "Progression",
			Type = "PassivesRemoved",
            Strings = {"ExtraAttack_2"}
        }
    }
end

local function OnStatsLoaded()
    local settings = getConfigSettings()
    local payloads = {}

    for _, payload in ipairs(createExtraAttackPayloads(settings)) do
        table.insert(payloads, payload)
    end

    for _, payload in ipairs(payloads) do
        Mods.SubclassCompatibilityFramework.Api.InsertPassives({payload})
    end
end

Ext.Events.StatsLoaded:Subscribe(OnStatsLoaded)