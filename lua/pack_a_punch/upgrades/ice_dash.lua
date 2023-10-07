local UPGRADE = {}
UPGRADE.id = "ice_dash"
UPGRADE.class = "weapon_ttt_fire_dash"
UPGRADE.name = "Ice Dash"
UPGRADE.desc = "Briefly freezes players instead!\nDoesn't kill you, you can swap weapons!"

UPGRADE.convars = {
    {
        name = "pap_ice_dash_freeze_secs",
        type = "int"
    }
}

local freezeSecsCvar = CreateConVar("pap_ice_dash_freeze_secs", 5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs players are frozen", 1, 20)

function UPGRADE:Apply(SWEP)
    local freezeColour = Color(0, 255, 255, 255)

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) or self.Active then return end
        self.Active = true
        local timerName = owner:SteamID64() .. "TTTFlameRunTimer"
        owner:SetFriction(0)
        owner:SetLaggedMovementValue(self.SpeedMultiplier)
        owner:EmitSound("ttt_pack_a_punch/cold_spaghetti/freeze.mp3")
        owner:EmitSound("ttt_pack_a_punch/cold_spaghetti/freeze.mp3")
        owner:SetColor(freezeColour)
        self:SearchForPlayers()

        timer.Create(timerName, 1, self.Seconds, function()
            if not IsValid(self) then
                if IsValid(owner) then
                    owner:SetLaggedMovementValue(1)
                    owner:SetFriction(1)
                    owner:SetColor(COLOR_WHITE)
                end

                timer.Remove(timerName)

                return
            end

            self:TakePrimaryAmmo(1)
            owner = self:GetOwner()

            if not IsValid(owner) then
                timer.Remove(timerName)

                return
            end

            if timer.RepsLeft(timerName) <= 0 then
                if IsValid(owner) then
                    owner:SetLaggedMovementValue(1)
                    owner:SetFriction(1)
                    owner:SetColor(COLOR_WHITE)
                end

                timer.Remove(timerName)
                self:Remove()
            end
        end)
    end

    function SWEP:Holster()
        return true
    end

    function SWEP:Think()
    end

    local screenFadeColour = Color(255, 255, 255, 50)

    if SERVER then
        local freezeRadius = SWEP.KillRadius * 4

        self:AddHook("PlayerPostThink", function(owner)
            local wep = owner:GetWeapon(self.class)

            if IsValid(wep) and wep.Active then
                for _, ent in ipairs(ents.FindInSphere(owner:GetPos(), freezeRadius)) do
                    if not UPGRADE:IsPlayer(ent) or ent == owner or ent:IsFrozen() then continue end
                    ent:Freeze(true)
                    ent:ScreenFade(SCREENFADE.OUT, screenFadeColour, 1, freezeSecsCvar:GetInt() - 1)
                    -- Re-use the freeze sound from the cold spaghetti
                    ent:EmitSound("ttt_pack_a_punch/cold_spaghetti/freeze.mp3")
                    ent:EmitSound("ttt_pack_a_punch/cold_spaghetti/freeze.mp3")
                    ent:SetColor(freezeColour)

                    timer.Create("TTTPAPIceDash" .. ent:SteamID64(), freezeSecsCvar:GetInt(), 1, function()
                        if IsValid(ent) then
                            ent:SetColor(COLOR_WHITE)
                            ent:Freeze(false)
                        end
                    end)
                end
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)