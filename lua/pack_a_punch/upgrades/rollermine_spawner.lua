local UPGRADE = {}
UPGRADE.id = "rollermine_spawner"
UPGRADE.class = "weapon_ttt_rollermine"
UPGRADE.name = "Rollermine Spawner"
UPGRADE.desc = "Slowly spawns many rollermines!"

UPGRADE.convars = {
    {
        name = "pap_rollermine_spawner_delay",
        type = "int"
    },
    {
        name = "pap_rollermine_spawner_cap",
        type = "int"
    }
}

local delayCvar = CreateConVar("pap_rollermine_spawner_delay", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds between spawning rollermines", 1, 60)

local capCvar = CreateConVar("pap_rollermine_spawner_cap", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max no. of rollermines spawned", 1, 60)

function UPGRADE:Apply(SWEP)
    local healthCvar = GetConVar("weapon_ttt_rollermine_health")

    local function SpawnRollermine(pos, vthrow, owner)
        local rollermine = ents.Create("npc_rollermine")

        if IsValid(rollermine) then
            self.Planted = true
            rollermine:SetHealth(healthCvar:GetFloat())
            rollermine:SetPos(pos)
            rollermine.Deployer = owner
            rollermine.IsTraitorRollermine = true
            rollermine:Spawn()
            rollermine:Activate()
            rollermine:SetPAPCamo()
            local phys = rollermine:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetVelocity(vthrow)
            end
        end
    end

    function SWEP:DeployRollermine()
        if SERVER then
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            if self.Planted then return end
            local vsrc = owner:GetShootPos()
            local vang = owner:GetAimVector()
            local vvel = owner:GetVelocity()
            local vthrow = vvel + vang * 500
            local pos = vsrc + vang * 50
            SpawnRollermine(pos, vthrow, owner)
            local timerName = "TTTPAPRollermineSpawner" .. owner:SteamID64()
            local spawnCount = 1

            timer.Create(timerName, delayCvar:GetInt(), 0, function()
                if spawnCount >= capCvar:GetInt() or not IsValid(owner) then
                    timer.Remove(timerName)

                    return
                end

                SpawnRollermine(pos, vthrow, owner)
                spawnCount = spawnCount + 1
            end)

            self:Remove()
        end

        self:EmitSound("Weapon_SLAM.SatchelThrow")
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        timer.Remove("TTTPAPRollermineSpawner" .. ply:SteamID64())
    end
end

TTTPAP:Register(UPGRADE)