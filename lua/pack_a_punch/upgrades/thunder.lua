local UPGRADE = {}
UPGRADE.id = "thunder"
UPGRADE.class = "tfa_thundergun"
UPGRADE.name = "Thunder"
UPGRADE.desc = "Extra ammo and sound effects!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()

    function SWEP:PAPPlayThunderSound()
        if SERVER and IsFirstTimePredicted() then
            local owner = self:GetOwner()

            if IsValid(owner) then
                owner:EmitSound("ttt_pack_a_punch/thunder/thunder" .. math.random(1, 5) .. ".mp3")
            elseif IsValid(self) then
                self:EmitSound("ttt_pack_a_punch/thunder/thunder" .. math.random(1, 5) .. ".mp3")
            end
        end
    end

    SWEP:PAPPlayThunderSound()
    local timername = "TTTPAPThunderLoopSound" .. SWEP:EntIndex()

    timer.Create(timername, 10, 0, function()
        if not IsValid(SWEP) then
            timer.Remove(timername)

            return
        end

        SWEP:PAPPlayThunderSound()
    end)

    if not SWEP.ThunderPrimarySoundApplied then
        SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

        function SWEP:PrimaryAttack()
            self:PAPOldPrimaryAttack()

            if self:Clip1() > 0 then
                self:PAPPlayThunderSound()
            else
                if self.PAPThunderReloadSoundCooldown then return end
                self.PAPThunderReloadSoundCooldown = true
                self:PAPPlayThunderSound()

                timer.Create("TTTPAPThunderReloadCooldown" .. self:EntIndex(), 5, 1, function()
                    if IsValid(self) then
                        self.PAPThunderReloadSoundCooldown = false
                    end
                end)
            end
        end
    end

    function SWEP:Deploy()
        self:PAPPlayThunderSound()

        return self.BaseClass.Deploy(self)
    end

    function SWEP:Holster()
        self:PAPPlayThunderSound()

        return true
    end

    function SWEP:Equip()
        self:PAPPlayThunderSound()
    end

    function SWEP:OnRemove()
        self:PAPPlayThunderSound()
    end

    SWEP.PAPOldReload = SWEP.Reload

    function SWEP:Reload()
        self:PAPOldReload()
        if self.PAPThunderReloadSoundCooldown then return end
        self.PAPThunderReloadSoundCooldown = true
        self:PAPPlayThunderSound()

        timer.Create("TTTPAPThunderReloadCooldown" .. self:EntIndex(), 5, 1, function()
            if IsValid(self) then
                self.PAPThunderReloadSoundCooldown = false
            end
        end)
    end

    function SWEP:PreDrop()
        self:PAPPlayThunderSound()
    end
end

TTTPAP:Register(UPGRADE)