local UPGRADE = {}
UPGRADE.id = "bombs_away"
UPGRADE.class = "tfa_tracer_nope"
UPGRADE.name = "Bomb's Away!"
UPGRADE.desc = "Gain Tracer's abilities!\nLShift: Blink, R: Recall, Right-click: Pulse Bomb"

-- Requires "Overwatch Tracer: Abilities" mod to be installed: https://steamcommunity.com/sharedfiles/filedetails/?id=1098898034
hook.Add("InitPostEntity", "TTTPAPBombsAwayInit", function()
    if not OWTA_conVars then return end

    -- For some reason the mod adds the hud whether you're using the tracer weapon or not...
    if CLIENT then
        RunConsoleCommand("tracer_hud", 0)
        RunConsoleCommand("tracer_hud_crosshair", 0)
        RunConsoleCommand("tracer_notification_blips", 0)
    end

    -- Stopping "Bomb's charged!" callout happening whenever you spawn or kill a player
    if SERVER then
        OWTA_CALLOUTS.pulseBomb.ready = {"ttt_pack_a_punch/silence.mp3", "ttt_pack_a_punch/silence.mp3"}
    end
end)

function UPGRADE:Condition()
    return OWTA_conVars ~= nil
end

function UPGRADE:Apply(SWEP)
    local tracerModel = "models/player/ow_tracer.mdl"

    if util.IsValidModel(tracerModel) then
        local function ToggleTracerModel(ply, toggleOn)
            if not IsValid(ply) then return end

            if not toggleOn and ply.TTTPAPBombsAwayModel then
                UPGRADE:SetModel(ply, ply.TTTPAPBombsAwayModel)
                ply.TTTPAPBombsAwayModel = nil
                ply:ConCommand("tracer_hud 0")
                ply:ConCommand("tracer_hud_crosshair 0")
            elseif toggleOn then
                ply.TTTPAPBombsAwayModel = ply:GetModel()
                UPGRADE:SetModel(ply, "models/player/ow_tracer.mdl")
                ply:ConCommand("tracer_hud 1")
                ply:ConCommand("tracer_hud_crosshair 1")
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