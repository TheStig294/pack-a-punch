local UPGRADE = {}
UPGRADE.id = "platinum_gun_fools"
UPGRADE.class = "weapon_ttt_foolsgoldengun"
UPGRADE.name = "Fool's Platinum Gun"
UPGRADE.desc = "Turns the person you shoot into an innocent and kills you"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:EmitSound(self.Primary.Sound)
        local owner = self:GetOwner()
        local trace = util.GetPlayerTrace(owner)
        local tr = util.TraceLine(trace)
        local victim = tr.Entity
        self:TakePrimaryAmmo(1)

        if IsValid(victim) and victim.IsPlayer() then
            owner:EmitSound("weapons/foolsgoldengun/ting.wav")

            if SERVER then
                victim:SetRole(ROLE_INNOCENT)
                SendFullStateUpdate()
                owner:Kill()
                victim:PrintMessage(HUD_PRINTTALK, "You have been shot by the Fool's Platinum Gun and are now an INNOCENT!")
                victim:PrintMessage(HUD_PRINTCENTER, "You have been shot by the Fool's Platinum Gun and are now an INNOCENT!")
            end
        end

        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    end
end

TTTPAP:Register(UPGRADE)