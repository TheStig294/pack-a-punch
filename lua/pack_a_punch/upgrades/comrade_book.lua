local UPGRADE = {}
UPGRADE.id = "comrade_book"
UPGRADE.class = "weapon_com_manifesto"
UPGRADE.name = "Comrade Book"
UPGRADE.desc = "OUR upgrade, comrade..."

function UPGRADE:Apply(SWEP)
    -- Upgrades everyone's held weapon and plays a sound
    if SERVER then
        local chosenSound = Sound("ttt_pack_a_punch/comrade_book/anthem" .. math.random(1, 4) .. ".mp3")
        local luaString = "surface.PlaySound(\"" .. chosenSound .. "\")"
        local owner = SWEP:GetOwner()

        for _, ply in ipairs(self:GetAlivePlayers()) do
            -- Don't upgrade the player's manifesto endlessly...
            if IsValid(owner) and owner == ply then continue end
            ply:ChatPrint("This is OUR upgrade comrade...")

            if TTTPAP:CanOrderPAP(ply, true) then
                TTTPAP:OrderPAP(ply)
                ply:SendLua(luaString)
            end
        end
    end

    -- Playing sound
    SWEP.PAPOldConvert = SWEP.Convert

    function SWEP:Convert(entity)
        self:PAPOldConvert(entity)
        local own = self:GetOwner()
        -- Stop the old sound
        own:StopSound("anthem.mp3")

        if IsValid(own) then
            self.PAPLastSound = "ttt_pack_a_punch/comrade_book/anthem" .. math.random(1, 4) .. ".mp3"
            own:EmitSound(self.PAPLastSound)
        end
    end

    -- Resetting sound
    SWEP.PAPOldFireError = SWEP.FireError

    function SWEP:FireError(entity)
        self:PAPOldFireError(entity)
        local own = self:GetOwner()

        if IsValid(own) and self.PAPLastSound then
            own:StopSound(self.PAPLastSound)
        end
    end

    SWEP.PAPOldReset = SWEP.Reset

    function SWEP:Reset(entity)
        self:PAPOldReset(entity)
        local own = self:GetOwner()

        if IsValid(own) and self.PAPLastSound then
            own:StopSound(self.PAPLastSound)
        end
    end

    SWEP.PAPOldError = SWEP.Error

    function SWEP:Error(entity)
        self:PAPOldError(entity)
        local own = self:GetOwner()

        if IsValid(own) and self.PAPLastSound then
            own:StopSound(self.PAPLastSound)
        end
    end
end

TTTPAP:Register(UPGRADE)