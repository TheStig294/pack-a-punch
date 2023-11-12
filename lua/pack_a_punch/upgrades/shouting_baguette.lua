local UPGRADE = {}
UPGRADE.id = "shouting_baguette"
UPGRADE.class = "weapon_fre_baguette"
UPGRADE.name = "Baguette Qui Crie"
UPGRADE.desc = "Joue des cris en tuant quelqu'un"

function UPGRADE:Apply()
    self:AddHook("DoPlayerDeath", function(_, attacker, _)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end

        if attacker:HasWeapon(self.class) and attacker:GetWeapon(self.class).PAPUpgrade then
            attacker:EmitSound("frenchman/death" .. math.random(6) .. ".mp3")
        end
    end)
end

TTTPAP:Register(UPGRADE)