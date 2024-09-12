if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") then
    if Mods.BG3MCM.MCMAPI:GetSettingValue("improvedExtraAttackFix", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac") then
        Ext.Require("ImprovedExtraAttackFix.lua")
    end
else
    Ext.Require("ImprovedExtraAttackFix.lua")
end
