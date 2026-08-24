local UPGRADE = {}
UPGRADE.id = "guardian_spammer"
UPGRADE.class = "weapon_guardiansummoner"
UPGRADE.name = "Guardian Spammer"
UPGRADE.desc = "Spawns regular antlion guardians instead!"

UPGRADE.convars = {
    {
        name = "pap_guardian_spammer_antlion_cap",
        type = "int"
    }
}

local antlionCapCvar = CreateConVar("pap_guardian_spammer_antlion_cap", "5", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Max number of antlions summoned", 1, 10)

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local tr = owner:GetEyeTrace()
        local tracedata = {}
        tracedata.pos = tr.HitPos + Vector(0, 0, 2)
        if not SERVER then return end

        if self:Clip1() > 0 then
            local myPosition = owner:EyePos() + (owner:GetAimVector() * 16)
            local data = EffectData()
            data:SetOrigin(myPosition)
            util.Effect("MuzzleFlash", data)
            local spawnLocation = FindSpawnLocationAntG(tracedata.pos)

            if spawnLocation == false then
                owner:PrintMessage(HUD_PRINTTALK, "Can't Place there.")
            else
                place_guardian(tracedata, true)
                self:TakePrimaryAmmo(1)
            end
        else
            self:EmitSound("Weapon_AR2.Empty")
        end
    end

    function place_guardian(tracedata, upgraded)
        if CLIENT then return end
        local ent = ents.Create("npc_antlionguard")

        if upgraded then
            self:SetUpgraded(ent)
        end

        if not IsValid(ent) then return end
        local spawnLocation = FindSpawnLocationAntG(tracedata.pos)

        if spawnLocation then
            ent:SetPos(spawnLocation)
            ent:SetSkin(1)
            ent:Spawn()
            ent:Activate()
            ent:SetKeyValue("allowbark", 1)
            local doesPoison = GetConVar("ttt_guardian_does_poison"):GetBool()

            if doesPoison then
                ent:SetKeyValue("cavernbreed", 1)
                ent:SetKeyValue("incavern", 1)
            end

            ent.barking = false
            ent.startTime = CurTime()
            ent:SetName("guardianS")
            local health = GetConVar("ttt_guardian_health"):GetFloat()
            ent:SetHealth(health)
            local curPly = nil
            local curPlyPos = nil
            local curDist = math.huge
            local npcPos = ent:GetPos()

            for _, ply in player.Iterator() do
                if ply:Alive() and not ply:IsSpec() then
                    local plyPos = ply:GetPos()
                    local dist = npcPos:DistToSqr(plyPos)

                    if dist < curDist then
                        curPly = ply
                        curPlyPos = plyPos
                        curDist = dist
                    end
                end
            end

            if curPly then
                ent:SetEnemy(curPly)
                ent:UpdateEnemyMemory(curPly, curPlyPos)
            end

            local facingVec = (curPlyPos - npcPos) * Vector(1, 1, 0)
            facingVec:Normalize()
            ent:SetAngles(facingVec:Angle())
        end

        local phys = ent:GetPhysicsObject()

        if not IsValid(phys) then
            ent:Remove()

            return
        end
    end

    local function CountAliveAntlions()
        local counter = 0

        local countedEnts = {
            npc_antlion_worker = true,
            npc_antlion = true,
            npc_antlionguard = true,
        }

        for _, ent in ents.Iterator() do
            -- Check if the antlion is alive
            if IsValid(ent) and ent:IsNPC() and countedEnts[ent:GetClass()] and ent:Alive() then
                counter = counter + 1
            end
        end

        GM_AliveAntlionCount = counter
    end

    timer.Create("AntlionCounterTimer", 10, 0, CountAliveAntlions)

    hook.Add("Think", "MyNPCActivityChecker", function()
        for _, ent in ipairs(ents.FindByClass("npc_antlionguard")) do
            if IsValid(ent) and ent:IsNPC() then
                if ent:GetSequence() == 34 and not ent.barking then
                    ent.barking = true
                    ent.startTime = CurTime()

                    timer.Create("Guardian_Summon_Antlions_" .. tostring(ent:EntIndex()), 0.75, 6, function()
                        if self:IsUpgraded(ent) and GM_AliveAntlionCount > antlionCapCvar:GetInt() then return end

                        if ent then
                            local enemy = ent:GetInternalVariable("m_hEnemy")

                            if enemy then
                                local enemyPos = enemy:GetPos()
                                local vec = Vector(1, 0, 0)
                                vec:Rotate(Angle(0, math.random() * 360, 0))
                                vec = (vec * 64) + Vector(0, 0, 16)
                                local pos = FindSpawnLocationAntG(enemyPos + vec)

                                if pos then
                                    local ent2

                                    if math.random(3) == 1 and GS_workers then
                                        if self:IsUpgraded(ent) then
                                            ent2 = ents.Create("npc_antlionguard")
                                        else
                                            ent2 = ents.Create("npc_antlion_worker")
                                        end
                                    else
                                        if self:IsUpgraded(ent) then
                                            ent2 = ents.Create("npc_antlionguard")
                                        else
                                            ent2 = ents.Create("npc_antlion")
                                        end
                                    end

                                    ent2:SetHealth(GetConVar("ttt_guardian_health"):GetFloat())
                                    ent2:SetPos(pos)
                                    ent2:SetSpawnFlags(512)
                                    ent2:Spawn()
                                    ent2:SetName("gardianSpawn")
                                    ent2:SetSequence("digout")
                                    EmitSound("npc/antlion/digup1.wav", pos, 0, CHAN_AUTO, 1, 75, 0, 120)
                                    local facingVec = (enemyPos - pos) * Vector(1, 1, 0)
                                    facingVec:Normalize()
                                    ent2:SetAngles(facingVec:Angle())
                                end
                            end
                        end
                    end)
                elseif ent:GetSequence() ~= 34 and ent.barking then
                    ent.barking = false
                    timer.Remove("Guardian_Summon_Antlions_" .. tostring(ent:EntIndex()))
                    ent:SetSaveValue("m_iNumLiveAntlions", 0)
                end

                if GM_AliveAntlionCount > antlionCapCvar:GetInt() then
                    ent:SetSaveValue("m_iNumLiveAntlions", 3)
                else
                    ent:SetSaveValue("m_iNumLiveAntlions", 0)
                end
            end

            if engine.ActiveGamemode() == "terrortown" and IsValid(ent) and ent:IsNPC() and not ent:IsPlayer() then
                local enemy = ent:GetInternalVariable("m_hEnemy")

                if not IsValid(enemy) or not enemy:IsPlayer() then
                    for _, ent2 in ipairs(ents.FindInSphere(ent:GetPos(), 1200)) do
                        if IsValid(ent2) and ent2:IsPlayer() and ent2:Alive() and ent:IsLineOfSightClear(ent2) and ent.UpdateEnemyMemory then
                            ent:SetSaveValue("m_hEnemy", ent2)
                            ent:UpdateEnemyMemory(ent2, ent2:GetPos())
                        end
                    end
                end
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)