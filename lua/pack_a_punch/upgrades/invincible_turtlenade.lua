local UPGRADE = {}
UPGRADE.id = "invincible_turtlenade"
UPGRADE.class = "weapon_ttt_poisonturtlenade"
UPGRADE.name = "Invincible Turtlenade"
UPGRADE.desc = "Spawns invincible Poison Turtles!"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local turtleProj = ents.Create("ttt_poisonturtlenade_proj")
        UPGRADE:SetUpgraded(turtleProj)

        function turtleProj:SpawnPoisonTurtleNPC(Position)
            self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            local spawnPos = FindSpawnLocationPoisonT(Position - Vector(0, 0, -8))

            if spawnPos then
                local NPC = ents.Create("npc_headcrab_black")
                if not IsValid(NPC) then return end
                NPC:SetPos(spawnPos)
                NPC:Spawn()
                NPC:Activate()
                local min, max = NPC:GetCollisionBounds()
                local hull = NPC:GetHullType()
                NPC:SetModel("models/poisonturtle/poisonturtle.mdl")
                NPC:SetSolid(SOLID_BBOX)
                NPC:SetName("poisonturtle")
                NPC:SetMoveType(MOVETYPE_STEP)
                NPC:SetPos(NPC:GetPos())
                NPC:SetHullType(hull)
                NPC:SetHullSizeNormal()
                NPC:SetCollisionBounds(min, max)
                local health = GetConVar("ttt_poisonturtle_health"):GetFloat()
                NPC:SetHealth(health)
                NPC:DropToFloor()
                NPC:SetModelScale(1)
                UPGRADE:SetUpgraded(NPC)
                local curPly = nil
                local curPlyPos = nil
                local curDist = math.huge

                for _, ply in player.Iterator() do
                    if ply:Alive() and not ply:IsSpec() then
                        local plyPos = ply:GetPos()
                        local dist = Position:DistToSqr(plyPos)

                        if dist < curDist then
                            curPly = ply
                            curPlyPos = plyPos
                            curDist = dist
                        end
                    end
                end

                if curPly then
                    NPC:SetEnemy(curPly)
                    NPC:UpdateEnemyMemory(curPly, curPlyPos)
                end

                local facingVec = (curPlyPos - Position) * Vector(1, 1, 0)
                facingVec:Normalize()
                NPC:SetAngles(facingVec:Angle())
            end

            self:Remove()
        end

        function turtleProj:TurtleExplode()
            if SERVER then
                local turtleMax = self.TurtleCount
                local degIncr = 360 / (turtleMax - 1)
                local turtleProj2 = ents.Create("ttt_poisonturtlenade_proj")
                turtleProj2.SpawnPoisonTurtleNPC = self.SpawnPoisonTurtleNPC
                UPGRADE:SetUpgraded(turtleProj2)
                turtleProj2.ProjType = 2
                turtleProj2:SetPos(self:GetPos() + Vector(0, 0, 16))
                turtleProj2:Spawn()
                turtleProj2:Activate()
                local Physics = turtleProj2:GetPhysicsObject()

                if IsValid(Physics) then
                    local vec = Vector(0, 0, 1)
                    local randMag = 85 + (math.random() * 140)
                    Physics:ApplyForceCenter(Physics:GetMass() * randMag * vec)
                end

                for i = 0, turtleMax - 2 do
                    turtleProj2 = ents.Create("ttt_poisonturtlenade_proj")
                    turtleProj2.SpawnPoisonTurtleNPC = self.SpawnPoisonTurtleNPC
                    UPGRADE:SetUpgraded(turtleProj2)
                    turtleProj2.ProjType = 2
                    local randAngle = math.random() * (degIncr / 2)
                    local vec = Angle(0, (i * degIncr) + randAngle, 0):Forward()
                    local pos = self:GetPos() + (vec * 25) + Vector(0, 0, 16)
                    turtleProj2:SetPos(pos)
                    turtleProj2:Spawn()
                    turtleProj2:Activate()
                    Physics = turtleProj2:GetPhysicsObject()

                    if IsValid(Physics) then
                        vec = vec + Vector(0, 0, 1)
                        vec:Normalize()
                        local randMag = 120 + (math.random() * 200)
                        Physics:ApplyForceCenter(Physics:GetMass() * randMag * vec)
                    end
                end

                self:Remove()
            end
        end

        if IsValid(turtleProj) then
            turtleProj.ProjType = 1
            turtleProj:SetPos(owner:EyePos() + owner:GetAimVector() * 60)
            turtleProj:Spawn()
            turtleProj:Activate()
            local Physics = turtleProj:GetPhysicsObject()

            if IsValid(Physics) then
                turtleProj:EmitSound(Sound("weapons/grenade_throw.wav"))
                Physics:ApplyForceCenter(owner:GetAimVector() * Physics:GetMass() * 1600)
                self:SendWeaponAnim(ACT_VM_THROW)
            else
                turtleProj:Remove()
            end
        end

        self:Remove()
    end

    self:AddHook("EntityTakeDamage", function(ent)
        if self:IsValidUpgrade(ent) then return true end
    end)
end

TTTPAP:Register(UPGRADE)