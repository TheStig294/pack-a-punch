local UPGRADE = {}
UPGRADE.id = "amongi_spawner"
UPGRADE.class = "weapon_amongussummoner"
UPGRADE.name = "Amongi Spawner"
UPGRADE.desc = "Continually spawns an amogus at the spot you shoot,\nwhenever someone walks near"
UPGRADE.ammoMult = 1 / 3

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        self:PAPOldPrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local tr = owner:GetEyeTrace()
        local tracedata = {}
        tracedata.pos = tr.HitPos + Vector(0, 0, 2)

        for _, ent in ipairs(ents.FindByClass("amongus_spawner")) do
            if ent:GetPos() == tracedata.pos then
                ent.PAPAmongiSpawnerOwner = owner
            end
        end

        if SERVER then
            self:Remove()
        end
    end

    local function FindRespawnLocCust(pos)
        local offsets = {Vector(0, 0, 0)}

        for i = 0, 360, 15 do
            table.insert(offsets, Vector(math.sin(i), math.cos(i), 0))
        end

        local midsize = Vector(34, 34, 76)
        local tstart = pos + Vector(0, 0, midsize.z / 2)

        for i = 1, #offsets do
            local o = offsets[i]
            local v = tstart + o * midsize * 1.5

            local t = {
                start = v,
                endpos = v,
                --filter = target,
                mins = midsize / -2,
                maxs = midsize / 2
            }

            local tr = util.TraceHull(t)
            if not tr.Hit then return v - Vector(0, 0, midsize.z / 2) end
        end

        return false
    end

    local function place_amongus(pos, owner)
        if CLIENT then return end
        local amongus = ents.Create("amongus_spawner")
        if not IsValid(amongus) then return end
        amongus.PAPAmongiSpawnerOwner = owner
        local spawnereasd = FindRespawnLocCust(pos)

        if spawnereasd then
            amongus:SetOwner(owner)
            amongus:SetPos(spawnereasd)
            amongus:Spawn()
        end
    end

    self:AddHook("EntityRemoved", function(ent)
        if not ent.PAPAmongiSpawnerOwner then return end
        local owner = ent.PAPAmongiSpawnerOwner
        local pos = ent:GetPos()

        if self:IsPlayer(owner) then
            timer.Simple(2, function()
                -- Don't spawn if the round has restarted
                if GetRoundState() == ROUND_PREP then return end
                place_amongus(pos, owner)
            end)
        end
    end)
end

TTTPAP:Register(UPGRADE)