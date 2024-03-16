local UPGRADE = {}
UPGRADE.id = "npc_spawner"
UPGRADE.class = "weapon_tax_kit"
UPGRADE.name = "NPC Spawner"
UPGRADE.desc = "Turns a body into an invincible walking NPC!"

function UPGRADE:Apply(SWEP)
    -- Suppressing join/leave messages while the NPC is active so they don't give away one spawning
    self:AddHook("ChatText", function(index, name, text, type)
        if type == "joinleave" then return true end
    end)

    -- Replacing the name of the NPC
    if SERVER then
        util.AddNetworkString("TTTPAPNpcSpawner")
    end

    function SWEP:MarkNPC(npc)
        npc.PAPNpc = true

        -- If we can't replace the npc's name, then hide it instead
        if not CR_VERSION then
            npc:SetNWBool("disguised", true)
        end

        net.Start("TTTPAPNpcSpawner")
        net.WriteString(npc.PAPNpcName)
        net.Broadcast()
    end

    if CLIENT then
        net.Receive("TTTPAPNpcSpawner", function()
            local name = net.ReadString()
            local npc = player.GetAll()[#player.GetAll()]
            npc.PAPNpc = true
            npc.PAPNpcName = name

            -- Custom roles name changing hooks
            if CR_VERSION then
                self:AddHook("TTTTargetIDPlayerName", function(tgt, client, text, clr)
                    if tgt.PAPNpcName then return tgt.PAPNpcName, clr end
                end)

                self:AddHook("TTTScoreboardPlayerName", function(tgt, client, currentName)
                    if tgt.PAPNpcName then return tgt.PAPNpcName end
                end)
            end
        end)
    end

    -- Spawning the NPC
    function SWEP:PrimaryAttack()
        if CLIENT or self.PAPRevivedNPCCoolown then return end
        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace()
        local rag = tr.Entity
        -- ".player_ragdoll = true" is a flag set by vanilla TTT on player bodies
        if not IsValid(rag) or not rag.player_ragdoll then return end
        -- Only allow to revive on a cooldown to prevent many NPCs from spawning when spamming the button
        self.PAPRevivedNPCCoolown = true

        timer.Simple(2, function()
            if IsValid(self) then
                self.PAPRevivedNPCCoolown = false
            end
        end)

        -- Get the info we need from the ragdoll before removing it
        local ragPly = CORPSE.GetPlayer(rag)
        -- if ragPly:IsBot() then
        --     owner:PrintMessage(HUD_PRINTCENTER, "You can't revive an NPC!")
        --     return
        -- end
        local name = ragPly:Nick()
        local model = ragPly:GetModel()
        -- Spawn the npc bot!
        RunConsoleCommand("bot")

        timer.Simple(0.5, function()
            if IsValid(rag) then
                rag:Remove()
            end

            local npc = player.GetAll()[#player.GetAll()]
            npc:SpawnForRound(true)
            npc:SetModel(model)
            npc.PAPNpcModel = model
            npc:Give("weapon_zm_shotgun")
            -- Used for "ShouldCollide" hook
            npc:SetCustomCollisionCheck(true)
            -- Try to make NPC unkillable
            npc:GodEnable()
            npc.PAPNpcName = name

            timer.Simple(0.5, function()
                if not IsValid(npc) then return end
                npc:SetNWString("PlayerName", name)
                npc:SetName(name)
                npc:SelectWeapon("weapon_zm_shotgun")
            end)

            -- Setting the role of the NPC to none so the round can end
            npc:SetRole(ROLE_NONE)
            local timername = "TTTPAPNPCSpawnerForceRoleNone" .. npc:EntIndex()

            timer.Create(timername, 1, 0, function()
                if IsValid(npc) then
                    npc:SetRole(ROLE_NONE)
                else
                    timer.Remove(timername)
                end
            end)

            -- Make the revive sound
            self:EmitSound("ambient/energy/zap7.wav")
            -- Warn all traitors and draw an outline around the NPC
            self:MarkNPC(npc)
        end)
    end

    -- If an NPC changes roles, make then able to take damage again, as an extra fail-safe in case a randomat or something is continually forcing their role back
    if SERVER then
        self:AddHook("TTTPlayerRoleChanged", function(npc, oldRole, newRole)
            if npc.PAPNpcName and newRole ~= ROLE_NONE then
                npc:GodDisable()
            end
        end)
    end

    -- Reset NPC's model after they respawn
    self:AddHook("PlayerSpawn", function(npc)
        if npc.PAPNpcModel then
            timer.Simple(0.1, function()
                npc:SetModel(npc.PAPNpcModel)
            end)
        end
    end)
end

function UPGRADE:Reset()
    if CLIENT then return end

    for _, bot in ipairs(player.GetAll()) do
        if bot.PAPNpc then
            bot:Kick()
        end
    end
end

TTTPAP:Register(UPGRADE)