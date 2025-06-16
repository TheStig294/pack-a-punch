local UPGRADE = {}
UPGRADE.id = "rocket_jumper"
UPGRADE.class = "weapon_ttt_rdmtrocketsciencelauncher"
UPGRADE.name = "Rocket Jumper"
UPGRADE.desc = "Immune to self-damage, launches players hilariously far!"
UPGRADE.noSound = true

function UPGRADE:Apply(SWEP)
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) then return end

        if inflictor:GetClass() == "rpg_missile" and self:IsValidUpgrade(inflictor.Launcher) then
            local attacker = inflictor.Launcher:GetOwner()

            if IsValid(attacker) and attacker == ent then
                dmg:SetDamage(0)
            end

            local direction = (ent:GetPos() - inflictor:GetPos()):GetNormalized()
            direction.z = 1
            ent:SetVelocity(direction * 562.5)
        end
    end)

    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) or ent:GetClass() ~= "rpg_missile" then return end

            if self:IsValidUpgrade(ent.Launcher) then
                ent:SetPAPCamo()
            end
        end)
    end)
end

TTTPAP:Register(UPGRADE)