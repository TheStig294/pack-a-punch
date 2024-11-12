local UPGRADE = {}
UPGRADE.id = "jamifier"
UPGRADE.class = "weapon_ttt_wpnjammer"
UPGRADE.name = "Jamifier"
UPGRADE.desc = "x3 ammo, turns all of a player's weapons into jam!\nLeft-click to use! (Not 'E')"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 3)
    SWEP.Primary.Delay = 0.1
    SWEP.Primary.Automatic = false
    SWEP.Primary.Damage = 1

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local victim = owner:GetEyeTrace().Entity

        if IsPlayer(victim) then
            if SERVER then
                victim:StripWeapons()
                victim:Give("ttt_pap_jam")
                victim:SelectWeapon("ttt_pap_jam")
                victim:ChatPrint("Your weapons got jammed!")
            end
        else
            self:EmitSound("Weapon_Pistol.Empty")

            return
        end

        -- If we have a weapon entity, fire away and replace the weapon with jam!
        self.BaseClass.PrimaryAttack(self)

        if SERVER and self:Clip1() <= 0 then
            self:Remove()
            owner:ConCommand("lastinv")
        end
    end

    function SWEP:Deploy()
        return true
    end
end

TTTPAP:Register(UPGRADE)