local UPGRADE = {}
UPGRADE.id = "fast_zombie_gun"
UPGRADE.class = "zombiegunspawn"
UPGRADE.name = "Fast Zombie Gun"
UPGRADE.desc = "Spawns fast zombies instead!"

function UPGRADE:Apply(SWEP)
    local function SpawnZombie(tracedata)
        if CLIENT then return end
        local ent = ents.Create("npc_fastzombie")
        if not IsValid(ent) then return end
        ent:SetPos(tracedata.pos)
        ent:Spawn()
        ent:SetPAPCamo()
        local phys = ent:GetPhysicsObject()

        if not IsValid(phys) then
            ent:Remove()

            return
        end
    end

    function SWEP:PrimaryAttack(worldsnd)
        local owner = self:GetOwner()
        local pos = owner:GetEyeTrace().HitPos -- Raytrace
        local tracedata = {}
        local pos2 = owner:GetPos() -- Playerposition
        local playerToWall = Vector(pos.x - pos2.x, pos.y - pos2.y, pos.z - pos2.z + 2)
        local magnitude = playerToWall:Length() - 30
        local playerToWall_normalized = playerToWall:GetNormalized()
        local spawnPoint = pos2 + playerToWall_normalized * magnitude
        tracedata.pos = spawnPoint
        -- The rest is only done on the server
        if not SERVER then return end

        if self:Clip1() > 0 then
            self:TakePrimaryAmmo(1)
            local myPosition = owner:EyePos() + (owner:GetAimVector() * 16)
            local data = EffectData()
            data:SetOrigin(myPosition)
            util.Effect("MuzzleFlash", data)
            SpawnZombie(tracedata)
        else
            self:EmitSound("Weapon_AR2.Empty")
        end
    end
end

TTTPAP:Register(UPGRADE)