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
            local npc = player.GetBots()[#player.GetBots()]
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
        if CLIENT or self.PAPRevivedNPC then return end
        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace()
        local rag = tr.Entity
        -- ".player_ragdoll = true" is a flag set by vanilla TTT on player bodies
        if not IsValid(rag) or not rag.player_ragdoll then return end
        -- Only allow to revive once
        self.PAPRevivedNPC = true
        -- Get the info we need from the ragdoll before removing it
        local ragPly = CORPSE.GetPlayer(rag)
        local name = ragPly:Nick()
        local model = ragPly:GetModel()
        -- Spawn the npc bot!
        RunConsoleCommand("bot")

        timer.Simple(0.5, function()
            if IsValid(rag) then
                rag:Remove()
            end

            local npc = player.GetBots()[#player.GetBots()]
            npc:SpawnForRound(true)
            npc:SetModel(model)
            npc:Give("weapon_zm_shotgun")
            -- Used for "ShouldCollide" hook
            npc:SetCustomCollisionCheck(true)
            -- Try to make NPC unkillable
            npc:GodEnable()
            npc.PAPOwner = owner
            npc.PAPNpcName = name

            timer.Simple(0.5, function()
                npc:SetNWString("PlayerName", name)
                npc:SetName(name)
                npc:SelectWeapon("weapon_zm_shotgun")
            end)

            -- Switching roles of the NPC back and forth so the round can end
            local timername = "TTTPAPNpcRoleSwitch" .. npc:EntIndex()

            timer.Create(timername, 2, 0, function()
                if not IsValid(npc) then
                    timer.Remove(timername)

                    return
                elseif npc:GetRole() == ROLE_TRAITOR then
                    npc:SetRole(ROLE_INNOCENT)
                else
                    npc:SetRole(ROLE_TRAITOR)
                end
            end)

            -- Make the revive sound
            self:EmitSound("ambient/energy/zap7.wav")
            -- Warn all traitors and draw an outline around the NPC
            self:MarkNPC(npc)
            self:Remove()
        end)
    end
end

function UPGRADE:Reset()
    if CLIENT then return end

    for _, bot in ipairs(player.GetBots()) do
        if bot.PAPNpc then
            bot:Kick()
        end
    end
end

TTTPAP:Register(UPGRADE)