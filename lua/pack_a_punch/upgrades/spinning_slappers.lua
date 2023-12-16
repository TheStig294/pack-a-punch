local UPGRADE = {}
UPGRADE.id = "spinning_slappers"
UPGRADE.class = "ttt_slappers"
UPGRADE.name = "Spinning Slappers"

UPGRADE.convars = {
    {
        name = "pap_spinning_slappers_cooldown",
        type = "int"
    },
    {
        name = "pap_spinning_slappers_strength",
        type = "int"
    }
}

local cooldownCvar = CreateConVar("pap_spinning_slappers_cooldown", 3, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds cooldown on weapon use", 0, 30)

local strengthCvar = CreateConVar("pap_spinning_slappers_strength", 1000, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Fling strength", 0, 10000)

UPGRADE.desc = "Slaps send people flying! Has a " .. cooldownCvar:GetInt() .. " second cooldown"

function UPGRADE:Apply(SWEP)
    SWEP.PAPFlingSound = Sound("ttt_pack_a_punch/flinging_spin_attack/fling.mp3")
    SWEP.Primary.Delay = cooldownCvar:GetInt()

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

        if SERVER then
            self:GetOwner():EmitSound(Sound("ttt_pack_a_punch/spinning_slappers/spinattack.mp3"))
        end

        self.Spinning = true

        timer.Simple(0.49, function()
            self.Spinning = false
        end)
    end

    SWEP.PAPOldThink = SWEP.Think

    function SWEP:Think()
        SWEP:PAPOldThink()

        if self.Spinning and SERVER then
            local owner = self:GetOwner()
            owner:SetEyeAngles(Angle(0, owner:EyeAngles().y + 20, 0))

            for i, ply in pairs(player.GetAll()) do
                if (ply ~= owner) and ply:Alive() and not ply:IsSpec() and (owner:GetPos():DistToSqr(ply:GetPos()) < (150 * 150)) and not ply.PAPSpinningSlappersCooldown then
                    ply.PAPSpinningSlappersCooldown = true
                    self:Slap()
                    ply:EmitSound(self.PAPFlingSound)
                    -- Use vector subtraction to get the direction vector to know which way to fling the player
                    local ownerPos = owner:GetPos()
                    local plyPos = ply:GetPos()
                    local flingDirection = ownerPos - plyPos
                    flingDirection:Normalize()
                    flingDirection:Mul(strengthCvar:GetInt())
                    flingDirection.z = strengthCvar:GetInt()
                    ply:SetVelocity(flingDirection)

                    timer.Simple(cooldownCvar:GetInt(), function()
                        if IsValid(ply) then
                            ply.PAPSpinningSlappersCooldown = nil
                        end
                    end)
                end
            end
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPSpinningSlappersCooldown = nil
    end
end

TTTPAP:Register(UPGRADE)