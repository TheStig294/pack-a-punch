local UPGRADE = {}
UPGRADE.id = "orbital_bass_cannon"
UPGRADE.class = "weapon_ttt_obc"
UPGRADE.name = "Orbital Bass Cannon"
UPGRADE.desc = "x2 ammo, tracks directly shot players,\nslams the victim with bass, as in the fish..."
UPGRADE.ammoMult = 2

-- Hopefully Lua is chill with calling a function inside a table like this... never tried it before
local fishModels = {Model("models/props/cs_militia/fishriver01.mdl"), Model("models/props/de_inferno/goldfish.mdl"), Model("models/props_swamp/trophy_bass.mdl")}

-- There needs to be at least one valid fish model installed for this upgrade to work
-- These models are from CS:S which should be installed since TTT requires it
function UPGRADE:Condition()
    for _, model in ipairs(fishModels) do
        if util.IsValidModel(model) then return true end
    end

    return false
end

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Delay = 5
    local validFishModels = {}

    for _, model in ipairs(fishModels) do
        if util.IsValidModel(model) then
            table.insert(validFishModels, model)
        end
    end

    self:AddHook("EntityEmitSound", function(data)
        if data.SoundName == "OBC/Drop.wav" then return false end
    end)

    function SWEP:PrimaryAttack()
        if not IsFirstTimePredicted() then return end
        local tr = self:GetOwner():GetEyeTrace()
        local hitEnt = tr.Entity
        local hitPos = tr.HitPos
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        if not SERVER then return end
        self:TakePrimaryAmmo(1)

        if IsValid(hitEnt) then
            hitEnt:EmitSound("OBC/LTBCKI.wav", 125, 100)
        else
            sound.Play("OBC/LTBCKI.wav", hitPos, 125, 100)
        end

        local removerEnt
        local blastwaveEnt

        timer.Simple(5, function()
            local validEnt = IsValid(hitEnt)
            local tracedata = {}
            local originPos

            if validEnt then
                originPos = hitEnt:GetPos()
            else
                originPos = hitPos
            end

            tracedata.start = originPos + Vector(0, 0, 0)
            tracedata.endpos = originPos + Vector(0, 0, 50000)
            tracedata.filter = ents.GetAll()
            local ceilingTrace = util.TraceLine(tracedata)
            local ceilingHitPos = ceilingTrace.HitPos

            timer.Create("TTTPAPOrbitalBassCannonSpawnFish", 0.2, 50, function()
                local spos = ceilingHitPos + Vector(math.random(-75, 75), math.random(-75, 75), math.random(0, 50))
                local contents = util.PointContents(spos)

                while contents == CONTENTS_SOLID or contents == CONTENTS_PLAYERCLIP do
                    spos = ceilingHitPos + Vector(math.random(-125, 125), math.random(-125, 125), math.random(-50, 50))
                    contents = util.PointContents(spos)
                end

                local fish = ents.Create("prop_physics")
                fish:SetModel(validFishModels[math.random(#validFishModels)])
                fish:SetPos(spos)
                fish:Spawn()

                timer.Simple(30, function()
                    if IsValid(fish) then
                        fish:Remove()
                    end
                end)
            end)

            timer.Create("TTTPAPOrbitalBassCannonFishSound", 0.5, 20, function()
                sound.Play("ttt_pack_a_punch/orbital_bass_cannon/fish" .. math.random(4) .. ".mp3", originPos, math.random(50, 150), math.random(50, 100))
            end)

            removerEnt = ents.Create("remover")
            removerEnt:SetPos(ceilingHitPos)
            removerEnt:Spawn()
            local tracedata2 = {}
            tracedata2.start = ceilingHitPos
            tracedata2.endpos = ceilingHitPos + Vector(0, 0, -50000)
            tracedata2.filter = ents.GetAll()
            local trace2 = util.TraceLine(tracedata2)
            blastwaveEnt = ents.Create("blastwave")
            blastwaveEnt:SetPos(trace2.HitPos)
            blastwaveEnt:Spawn()
        end)

        timer.Simple(18, function()
            local entsToRemove = {removerEnt, blastwaveEnt}

            for _, ent in ipairs(entsToRemove) do
                if IsValid(ent) then
                    ent:Remove()
                end
            end
        end)

        if self:Clip1() <= 0 then
            local owner = self:GetOwner()

            if IsValid(owner) then
                owner:ConCommand("lastinv")
            end

            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)