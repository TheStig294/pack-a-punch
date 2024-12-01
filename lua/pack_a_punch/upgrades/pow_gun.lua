local UPGRADE = {}
UPGRADE.id = "pow_gun"
UPGRADE.class = "custom_pewgun"
UPGRADE.name = "POW Gun"
UPGRADE.desc = "x2 damage, launches hit players away!"
UPGRADE.damageMult = 2

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function()
        if not SWEP:CanPrimaryAttack() then return end
        local owner = SWEP:GetOwner()
        owner:StopSound("entities/weapons/pew/pew.wav")
        owner:EmitSound("ttt_pack_a_punch/pow_gun/pow.mp3")

        -- This weapon LOVES to set itself on fire when you hit someone with it and kill you...
        -- Due to a bug in the base weapon that occurs whenever a mod adds the global ROLE_SWAPPER:
        -- "if self:GetOwner():GetRole() == ROLE_JESTER or ROLE_SWAPPER then self:Ignite(20, 0) end"
        -- (See the problem?)
        if SERVER then
            SWEP:Extinguish()
        end

        local victim = owner:GetEyeTrace().Entity
        if not self:IsAlivePlayer(victim) then return end
        victim:SetGroundEntity(nil)
        victim:SetPos(victim:GetPos() + Vector(0, 0, 5))
        victim:SetVelocity(owner:GetAimVector() * 500 + Vector(0, 0, 250))
        victim:StopSound("entities/weapons/pew/pew.wav")
        victim:EmitSound("ttt_pack_a_punch/pow_gun/pow.mp3")
    end)
end

TTTPAP:Register(UPGRADE)