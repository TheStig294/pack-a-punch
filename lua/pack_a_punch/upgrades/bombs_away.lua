local UPGRADE = {}
UPGRADE.id = "bombs_away"
UPGRADE.class = "tfa_tracer_nope"
UPGRADE.name = "Bomb's Away!"
UPGRADE.desc = "Gain Tracer's abilities!\nLShift: Blink, R: Recall, Right-click: Pulse Bomb"

-- Requires "Overwatch Tracer: Abilities" mod to be installed: https://steamcommunity.com/sharedfiles/filedetails/?id=1098898034
hook.Add("InitPostEntity", "TTTPAPBombsAwayInit", function()
    if not OWTA_conVars then return end
    -- For some reason the mod adds the hud whether you're using the tracer weapon or not...
    RunConsoleCommand("tracer_hud", 0)
    RunConsoleCommand("tracer_hud_crosshair", 0)
    RunConsoleCommand("tracer_notification_blips", 0)

    -- Override timer created in InitPostEntity from original mod to stop "Bomb's charged!" callout happening whenever you spawn
    timer.Simple(0, function()
        timer.Remove("passiveBombCharge")
    end)
end)

function UPGRADE:Condition()
    return OWTA_conVars ~= nil
end

function UPGRADE:Apply(SWEP)
    -- Allowing "Bomb's charged!" callout to play again while playing as Tracer
    local own = SWEP:GetOwner()

    if IsValid(own) then
        own:SetNWInt("bombCharge", 100)
    end

    if SERVER then
        local function playOnBombChargeCallout(ply)
            ply:EmitSound(OWTA_CALLOUTS.pulseBomb.ready[math.random(#OWTA_CALLOUTS.pulseBomb.ready)])
            ply:SetNWBool("ultimateNotified", true)
        end

        local function onBombCharge(ply)
            playOnBombChargeCallout(ply)
        end

        local function shouldPlayCallout(ply)
            local wep = ply:GetActiveWeapon()
            if not self:IsUpgraded(wep) then return false end

            return ply:GetNWInt("bombCharge") == 100 and not ply:GetNWBool("ultimateNotified") and ply:GetInfoNum("tracer_callouts", 0) == 1 and ply:Alive() and not ply:IsSpec()
        end

        local function increaseBombCharge(ply, increase)
            if not ply:IsAdmin() and GetConVar("tracer_bomb_admin_only"):GetBool() then return end
            ply:SetNWInt("bombCharge", math.Clamp(ply:GetNWInt("bombCharge", 0) + increase * GetConVar("tracer_bomb_charge_multiplier"):GetInt(), 0, 100))

            if shouldPlayCallout(ply) then
                onBombCharge(ply)
            end
        end

        timer.Create("passiveBombCharge", 2, 0, function()
            for _, ply in player.Iterator() do
                increaseBombCharge(ply, 1)

                if shouldPlayCallout(ply) then
                    playBombReadyCallout(ply)
                end
            end
        end)
    end

    local tracerModel = "models/player/ow_tracer.mdl"

    if util.IsValidModel(tracerModel) then
        local function ToggleTracerModel(ply, toggleOn)
            if not IsValid(ply) then return end

            if not toggleOn and ply.TTTPAPBombsAwayModel then
                UPGRADE:SetModel(ply, ply.TTTPAPBombsAwayModel)
                ply.TTTPAPBombsAwayModel = nil
                RunConsoleCommand("tracer_hud", 0)
                RunConsoleCommand("tracer_hud_crosshair", 0)
            elseif toggleOn then
                ply.TTTPAPBombsAwayModel = ply:GetModel()
                UPGRADE:SetModel(ply, "models/player/ow_tracer.mdl")
                RunConsoleCommand("tracer_hud", 1)
                RunConsoleCommand("tracer_hud_crosshair", 1)
            end
        end

        ToggleTracerModel(SWEP:GetOwner(), true)

        self:AddToHook(SWEP, "Deploy", function()
            ToggleTracerModel(SWEP:GetOwner(), true)
        end)

        self:AddToHook(SWEP, "OnRemove", function()
            ToggleTracerModel(SWEP:GetOwner(), false)
        end)

        self:AddToHook(SWEP, "PreDrop", function()
            ToggleTracerModel(SWEP:GetOwner(), false)
        end)

        self:AddToHook(SWEP, "OnDrop", function()
            ToggleTracerModel(SWEP:GetOwner(), false)
        end)
    end

    if CLIENT then
        -- Fixing a lua error with the base mod effect
        local EFFECT = effects.Create("recall")

        -- local material = Material("models/props_combine/tprings_globe")
        function EFFECT:Init(data)
            local color = Color(192, 255, 255)
            self:SetModel("models/effects/combineball.mdl")
            self:SetMaterial("models/props_combine/stasisshield_sheet")
            self:SetPos(data:GetOrigin())
            self:SetAngles(LocalPlayer():EyeAngles())
            self:SetColor(color)
            self.Scale = 4
            self.Duration = 0.25
            self.Begin = CurTime()
            self:SetModelScale(self.Scale)
            local light = DynamicLight(self:EntIndex())
            light.Pos = self:GetPos()
            light.r, light.g, light.b = color.r, color.g, color.b
            light.brightness = 2
            light.Decay = 1000
            light.Size = 256
            light.DieTime = CurTime() + self.Duration
        end

        effects.Register(EFFECT, "recall")

        local bindToAction = {
            ["+speed"] = "blink",
            ["+reload"] = "recall",
            ["+attack2"] = "throwBomb"
        }

        self:AddHook("PlayerBindPress", function(ply, bind, pressed, code)
            local action = bindToAction[bind]
            if not pressed or not action then return end
            local wep = ply:GetActiveWeapon()
            if not self:IsUpgraded(wep) then return end
            signal("OWTA_" .. action)
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        if ply.TTTPAPBombsAwayModel then
            self:SetModel(ply, ply.TTTPAPBombsAwayModel)
            ply.TTTPAPBombsAwayModel = nil
        end

        ply:ConCommand("tracer_hud 0")
        ply:ConCommand("tracer_hud_crosshair 0")
    end

    timer.Remove("passiveBombCharge")
end

TTTPAP:Register(UPGRADE)