local UPGRADE = {}
UPGRADE.id = "big_pickle_gun"
UPGRADE.class = "weapon_ttt_pickle_rick_gun"
UPGRADE.name = "Big Pickle Gun"
UPGRADE.desc = "Increases size and health instead!"

UPGRADE.convars = {
    {
        name = "pap_big_pickle_gun_size",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_big_pickle_gun_health",
        type = "int"
    }
}

local sizeCvar = CreateConVar("pap_big_pickle_gun_size", "2", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size multiplier", 1.1, 5)

local healthCvar = CreateConVar("pap_big_pickle_gun_health", "350", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Health you are set to", 101, 600)

function UPGRADE:Apply(SWEP)
    self:AddHook("TTTPickleRickApplyTransform", function(ply, wep, scale, health, model)
        -- Override size, health, model, and pitch percent of the the transform sound effect
        if self:IsUpgraded(wep) then
            ply.TTTPAPBigPickleGun = true

            return sizeCvar:GetFloat(), healthCvar:GetInt(), nil, 50
        end
    end)
end

function UPGRADE:Reset()
    timer.Simple(0, function()
        for _, ply in player.Iterator() do
            if ply.TTTPAPBigPickleGun then
                ply:SetStepSize(18)
                ply.TTTPAPBigPickleGun = nil
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)