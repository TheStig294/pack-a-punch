AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_jarate_proj"

local function ResetJarte(ply)
    ply.TTTPAPViralJarte = nil
    ply:StopParticles()
    ply:SetNWBool("PissedOn", false)
    timer.Remove("TTTPAPViralJarteSpread" .. ply:SteamID64())
end

function ENT:Initialize()
    ParticleEffectAttach("peejar_trail_red", PATTACH_POINT_FOLLOW, self, 0)
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

    if SERVER then
        self:SetExplodeTime(0)
    end

    self:SetPAPCamo()

    -- If players go into water, the jarate is cleaned up
    hook.Add("OnEntityWaterLevelChanged", "TTTPAPViralJarteWaterClean", function(ent, oldLevel, newLevel)
        if ent.TTTPAPViralJarte and newLevel ~= 0 then
            ResetJarte(ent)
            ent:EmitSound("vo/npc/male01/finally.wav")
        end
    end)

    hook.Add("TTTPrepareRound", "TTTPAPViralJarteReset", function()
        for _, ply in player.Iterator() do
            ResetJarte(ply)
        end

        hook.Remove("TTTPrepareRound", "TTTPAPViralJarteReset")
    end)
end

local function SpreadPee(pos)
    for _, ent in ipairs(ents.FindInSphere(pos, 400)) do
        if IsValid(ent) and ent:IsPlayer() and ent:Alive() and not ent:IsSpec() and not ent.TTTPAPViralJarte then
            ParticleEffectAttach("peejar_drips", PATTACH_POINT_FOLLOW, ent, ent:LookupAttachment("eyes"))
            ent:SetNWBool("PissedOn", true)

            if SERVER and not ent.TTTPAPViralJarte then
                ent:PrintMessage(HUD_PRINTCENTER, "You're infected with jarate!")
                ent:PrintMessage(HUD_PRINTTALK, "You're infected with jarate, you'll take double damage!\nFind some water to clean it off!")
            end

            ent.TTTPAPViralJarte = true
            ent:EmitSound("vo/npc/male01/goodgod.wav")
            local timerName = "TTTPAPViralJarteSpread" .. ent:SteamID64()

            timer.Create(timerName, 3, 0, function()
                if not IsValid(ent) or not ent:Alive() or ent:IsSpec() or GetRoundState() ~= ROUND_ACTIVE or not ent.TTTPAPViralJarte or not ent:GetNWBool("PissedOn") then
                    timer.Remove(timerName)

                    return
                end

                -- Recursion whoo!
                SpreadPee(ent:GetPos())
            end)
        end
    end
end

local splashsound = Sound("ambient/water/water_splash2.wav")

function ENT:Explode(tr)
    if SERVER then
        self:SetNoDraw(true)
        self:SetSolid(SOLID_NONE)

        if tr.Fraction ~= 1.0 then
            self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
        end

        local pos = self:GetPos()
        self:Remove()
        SpreadPee(pos)
        local effect = EffectData()
        effect:SetStart(pos)
        effect:SetOrigin(pos)

        if tr.Fraction ~= 1.0 then
            effect:SetNormal(tr.HitNormal)
        end

        util.Effect("AntlionGib", effect, true, true)
        sound.Play(splashsound, pos, 100, 100)
    else
        local spos = self:GetPos()

        local trs = util.TraceLine({
            start = spos + Vector(0, 0, 64),
            endpos = spos + Vector(0, 0, -128),
            filter = self
        })

        util.Decal("YellowBlood", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
        self:SetDetonateExact(0)
    end
end