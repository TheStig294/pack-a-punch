AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_eq_fraggrenade_thrown.mdl")
ENT.Radius = 400
ENT.Sound = Sound("ttt_pack_a_punch/blue_screen_grenade/error.mp3")
ENT.ExplodeSound = Sound("")
ENT.Duration = 4

function ENT:Explode(tr)
    if SERVER then
        self:SetNoDraw(true)
        self:SetSolid(SOLID_NONE)
        local pos = self:GetPos()

        for _, ply in ipairs(ents.FindInSphere(pos, self.Radius)) do
            if IsValid(ply) and ply:IsPlayer() then end
        end

        local phexp = ents.Create("env_physexplosion")

        if IsValid(phexp) then
            phexp:SetPos(pos)
            phexp:SetKeyValue("magnitude", 100) --max
            phexp:SetKeyValue("radius", self.Radius)
            -- 1 = no dmg
            phexp:SetKeyValue("spawnflags", 1)
            phexp:Spawn()
            phexp:Fire("Explode", "", 0.2)
        end

        local effect = EffectData()
        effect:SetStart(pos)
        effect:SetOrigin(pos)

        if tr.Fraction ~= 1.0 then
            effect:SetNormal(tr.HitNormal)
        end

        util.Effect("Explosion", effect, true, true)
        util.Effect("cball_explode", effect, true, true)
        sound.Play(self.Sound, pos, 100, 100)

        timer.Simple(self.Duration + 1, function()
            if IsValid(self) then
                self:Remove()
            end
        end)
    else
        local spos = self:GetPos()

        for _, ply in ipairs(ents.FindInSphere(spos, self.Radius)) do
            if IsValid(ply) and LocalPlayer() == ply then
                self:DisplayBlueScreen(ply)
            end
        end

        local trs = util.TraceLine({
            start = spos + Vector(0, 0, 64),
            endpos = spos + Vector(0, 0, -128),
            filter = self
        })

        util.Decal("SmallScorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
        self:SetDetonateExact(0)
    end
end

function ENT:DisplayBlueScreen(ply)
    if SERVER or not IsValid(ply) or not ply:IsPlayer() then return end
    surface.PlaySound(self.Sound)
    local frame = vgui.Create("DFrame")
    frame:SetPos(0, 0)
    frame:SetSize(ScrW(), ScrH())
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    local image = vgui.Create("DImage", frame)
    image:SetImage("ttt_pack_a_punch/blue_screen_grenade/bluescreen.jpg")
    image:Dock(FILL)

    timer.Simple(1.7, function()
        hook.Add("Think", "TTTPAPBlueScreenGrenadeStopSound", function()
            RunConsoleCommand("stopsound")
        end)
    end)

    timer.Simple(self.Duration, function()
        hook.Remove("Think", "TTTPAPBlueScreenGrenadeStopSound")

        if IsValid(frame) then
            frame:Close()
        end
    end)
end