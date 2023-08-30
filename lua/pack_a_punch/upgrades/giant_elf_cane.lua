local UPGRADE = {}
UPGRADE.id = "giant_elf_cane"
UPGRADE.class = "weapon_ttt_randomatcandycane"
UPGRADE.name = "Giant Elf Cane"
UPGRADE.desc = "Become larger and have more health!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    if IsValid(owner) then
        local oldHealth = owner:GetMaxHealth()

        if SERVER then
            owner:SetMaxHealth(oldHealth * 8)
            owner:SetPlayerScale(4)
            owner:PrintMessage(HUD_PRINTCENTER, "Crouch to convert players!")
            owner:PrintMessage(HUD_PRINTTALK, "Crouch to convert players!")
        end

        owner:SetHealth(oldHealth * 8)
    end

    -- Play the slowed christmas sound
    local sound_christmas = Sound("ttt_pack_a_punch/giant_elf_cane/jinglebells_slow.mp3")
    local STATE_ERROR = -1
    local STATE_NONE = 0
    local STATE_CONVERT = 1

    function SWEP:Convert(entity)
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:EmitSound(sound_christmas)
        end

        self:SetState(STATE_CONVERT)
        self:SetStartTime(CurTime())
        self:SetMessage("SPREADING CHRISTMAS CHEER")
        self:CancelUnfreeze(entity)
        entity:PrintMessage(HUD_PRINTCENTER, "A giant Elf is spreading Christmas cheer to you!")
        self.TargetEntity = entity
        self:DoFreeze()
        self:SetNextPrimaryFire(CurTime() + self:GetDeviceDuration())
    end

    function SWEP:FireError()
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:StopSound(sound_christmas)
        end

        self:SetState(STATE_NONE)
        self:UnfreezeTarget()
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    if SERVER then
        function SWEP:Reset()
            local owner = self:GetOwner()

            if IsValid(owner) then
                owner:StopSound(sound_christmas)
            end

            self:SetState(STATE_NONE)
            self:SetStartTime(-1)
            self:SetMessage('')
            self:SetNextPrimaryFire(CurTime() + 0.1)
        end

        function SWEP:Error(msg)
            local owner = self:GetOwner()

            if IsValid(owner) then
                owner:StopSound(sound_christmas)
            end

            self:SetState(STATE_ERROR)
            self:SetStartTime(CurTime())
            self:SetMessage(msg)
            self:SetNextPrimaryFire(CurTime() + 0.75)
            self:UnfreezeTarget()

            timer.Simple(0.75, function()
                if IsValid(self) then
                    self:Reset()
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)