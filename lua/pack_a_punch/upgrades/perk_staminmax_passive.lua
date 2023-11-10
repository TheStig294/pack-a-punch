local UPGRADE = {}
UPGRADE.id = "perk_staminmax_passive"
UPGRADE.class = "ttt_perk_staminup"
UPGRADE.name = "Staminmax"
UPGRADE.desc = "Double walk speed"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    owner.TTTPAPStaminmax = true

    timer.Simple(3.2, function()
        if IsValid(owner) and GetRoundState() == ROUND_ACTIVE then
            owner:SetWalkSpeed(owner:GetWalkSpeed() * 2)
        end
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.TTTPAPStaminmax then
            ply:SetWalkSpeed(220)
            ply:SetRunSpeed(220)
            ply.TTTPAPStaminmax = nil
        end
    end)

    self:AddHook("PlayerSpawn", function(ply)
        if ply.TTTPAPStaminmax then
            ply:SetWalkSpeed(220)
            ply:SetRunSpeed(220)
            ply.TTTPAPStaminmax = nil
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if ply.TTTPAPStaminmax then
            ply:SetWalkSpeed(220)
            ply:SetRunSpeed(220)
            ply.TTTPAPStaminmax = nil
        end
    end
end

TTTPAP:Register(UPGRADE)