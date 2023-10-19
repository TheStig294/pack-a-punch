local UPGRADE = {}
UPGRADE.id = "wave_gun"
UPGRADE.class = "tfa_wavegun"
UPGRADE.name = "Wave Gun"
UPGRADE.desc = "Shoot at the ground to instantly \"microwave\"\nnearby players in an AOE!"

UPGRADE.convars = {
    {
        name = "pap_wave_gun_radius",
        type = "int"
    }
}

function UPGRADE:Apply(SWEP)
    -- We need a delay so the animation can be triggered properly
    timer.Simple(0.1, function()
        -- Trigger the "Put guns together" animation
        local _, tanim = SWEP:ChooseSilenceAnim(not SWEP:GetSilenced())
        SWEP:ScheduleStatus(TFA.Enum.STATUS_SILENCER_TOGGLE, SWEP:GetActivityLength(tanim, true))
        -- Set the clip of primary ammo to 1 to display 1 ammo on the ammo counter
        -- But we are actually using Tertiary ammo here, so the ammo counter won't decrease when we shoot
        -- The weapon's ammo will have to manually be set on shoot
        SWEP:SetClip1(1)
        SWEP:SetClip2(0)
        SWEP:SetClip3(1)
        SWEP:SetMaxClip3(1)
        SWEP.Primary.ClipSize = 1
        SWEP.Secondary.ClipSize = 1
        SWEP.Tertiary.ClipSize = 1
        local owner = SWEP:GetOwner()
        owner:SetAmmo(0, "CombineHeavyCannon")
        owner:SetAmmo(0, "CombineCannon")
        SWEP.PAPOldTertiaryAttack = SWEP.TertiaryAttack

        function SWEP:TertiaryAttack()
            self.Primary_TFA.Projectile = "ttt_pap_wave_gun_projectile"
            self:PAPOldTertiaryAttack()
            -- Making it so the ammo displayed on the HUD is accurate
            self:SetClip1(0)
        end
    end)
end

TTTPAP:Register(UPGRADE)