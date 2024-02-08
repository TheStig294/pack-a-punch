local UPGRADE = {}
UPGRADE.id = "amongi_spawner"
UPGRADE.class = "weapon_amongussummoner"
UPGRADE.name = "Amongi Spawner"
UPGRADE.desc = "Continually spawns an amogus at the spot you shoot,\nwhenever someone walks near"
UPGRADE.ammoMult = 1 / 3

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function(self)
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
    end)

    if SERVER then
        self:AddHook("EntityRemoved", function(ent)
            if not ent.PAPAmongiSpawnerOwner then return end
            local owner = ent.PAPAmongiSpawnerOwner
            local pos = ent:GetPos()

            if self:IsPlayer(owner) then
                timer.Simple(2, function()
                    -- Don't spawn if the round has restarted
                    if GetRoundState() == ROUND_PREP then return end
                    local amongus = ents.Create("amongus_spawner")
                    if not IsValid(amongus) then return end
                    amongus.PAPAmongiSpawnerOwner = owner
                    -- Don't use the amongus spawner's place_amongus() function, as it causes weird "drifting" of the amongus spawn location
                    -- as more are spawned from the one entity
                    amongus:SetOwner(owner)
                    amongus:SetPos(pos)
                    amongus:Spawn()
                end)
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)