local UPGRADE = {}
UPGRADE.id = "zeus_cannon"
UPGRADE.class = "tfa_thundergun"
UPGRADE.name = "Zeus Cannon"
UPGRADE.desc = "Hold left-click to charge 1 instant-kill blast!"

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()
    SWEP.PAPCharge = 0

    timer.Simple(0.1, function()
        SWEP.Primary.ClipSize = 100
        SWEP.Primary.ClipMax = 100
        SWEP.Primary_TFA.ClipSize = 100
        SWEP.Primary_TFA.MaxAmmo = 100
        SWEP:SetClip1(0)
    end)

    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
    end

    -- So charge up time is not tied to framerate... unless your framerate is less than 10 frames per second, in which case you have bigger problems lol
    local chargeIncrement = 4
    local secondsIncrement = 0.1
    SWEP.PAPNextThink = CurTime()

    self:AddToHook(SWEP, "Think", function()
        if SWEP.PAPUsed or SWEP.PAPNextThink > CurTime() then return end
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end

        if owner:KeyDown(IN_ATTACK) then
            if not SWEP.PAPCharging then
                for i = 1, 4 do
                    SWEP:EmitSound("ttt_pack_a_punch/fart_cannon/windup.mp3", 150)
                end

                SWEP.PAPCharging = true
            end

            SWEP.PAPCharge = SWEP.PAPCharge + chargeIncrement
            SWEP:SetClip1(SWEP.PAPCharge)

            if SWEP.PAPCharge >= SWEP.Primary.ClipSize then
                SWEP:PAPOldPrimaryAttack()

                for i = 1, 4 do
                    SWEP:EmitSound("ttt_pack_a_punch/fart_cannon/fart.mp3", 150)
                end

                if SERVER then
                    util.ScreenShake(owner:GetPos(), 50, 40, 2, 1000, true)
                end

                SWEP:SetClip1(0)
                SWEP.PAPUsed = true
            end
        elseif SWEP.PAPCharge > 0 then
            SWEP.PAPCharge = SWEP.PAPCharge - chargeIncrement
            SWEP:SetClip1(SWEP.PAPCharge)

            if SWEP.PAPCharge == 0 then
                SWEP.PAPCharging = false
            end
        end

        SWEP.PAPNextThink = CurTime() + secondsIncrement
    end)

    -- Make the upgraded thundergun shot always 1-shot kill, hook from the wonder weapons TTT conversion mod (Always nice to be able to add your own hooks for upgrades...)
    self:AddHook("TTTThundergunDamage", function(dmg)
        local thundergun = dmg:GetInflictor()

        if self:IsUpgraded(thundergun) then
            dmg:SetDamage(10000)
        end
    end)
end

TTTPAP:Register(UPGRADE)