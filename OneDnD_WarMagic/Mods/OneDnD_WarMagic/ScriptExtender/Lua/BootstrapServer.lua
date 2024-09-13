if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") then
    if Mods.BG3MCM.MCMAPI:GetSettingValue("improvedExtraAttackFix", "7429b169-5e11-4d31-9db3-b1285df2d191") then
        Ext.Require("ImprovedExtraAttackFix.lua")
    end
else
    Ext.Require("ImprovedExtraAttackFix.lua")
end
