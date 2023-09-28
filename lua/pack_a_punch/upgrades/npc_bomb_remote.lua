local UPGRADE = {}
UPGRADE.id = "npc_bomb_remote"
UPGRADE.class = "weapon_ttt_rsb"
UPGRADE.name = "Remote NPC Bomb"
UPGRADE.desc = "Turns a body into an invincible walking NPC!\nRight-click to explode, auto-explodes when near a player"

UPGRADE.convars = {
    {
        name = "pap_npc_bomb_remote_radius",
        type = "int"
    },
    {
        name = "pap_npc_bomb_remote_damage",
        type = "int"
    },
    {
        name = "pap_npc_bomb_remote_trigger_radius",
        type = "int"
    }
}

local radiusCvar = CreateConVar("pap_npc_bomb_remote_radius", "400", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Explosion radius", 0, 1000)

local damageCvar = CreateConVar("pap_npc_bomb_remote_damage", "1000", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Explosion damage", 0, 4000)

local triggerRadiusCvar = CreateConVar("pap_npc_bomb_remote_trigger_radius", "100", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Distance before triggering explosion", 0, 1000)

function UPGRADE:Apply(SWEP)
    -- Suppressing join/leave messages while the NPC bomb is active so they don't give away one spawning
    self:AddHook("ChatText", function(index, name, text, type)
        if type == "joinleave" then return true end
    end)

    -- Warning traitors about the NPC bomb
    if SERVER then
        util.AddNetworkString("TTTPAPRemoteNpcBombSpawn")
    end

    function SWEP:MarkNPC(npc)
        npc.PAPNpcBomb = true

        -- If we can't replace the npc's name, then hide it instead
        if not CR_VERSION then
            npc:SetNWBool("disguised", true)
        end

        -- Put an outline over the NPC for all traitor players (alive or dead)
        for _, ply in ipairs(player.GetAll()) do
            if (ply.IsTraitorTeam and ply:IsTraitorTeam()) or ply:GetRole() == ROLE_TRAITOR then
                local msg = "An NPC bomb has been spawned!"
                ply:PrintMessage(HUD_PRINTCENTER, msg)
                ply:PrintMessage(HUD_PRINTTALK, msg)
            end
        end

        net.Start("TTTPAPRemoteNpcBombSpawn")
        net.WriteString(npc.PAPNpcBombName)
        net.WriteEntity(npc.PAPOwner)
        net.Broadcast()
    end

    if CLIENT then
        net.Receive("TTTPAPRemoteNpcBombSpawn", function()
            local name = net.ReadString()
            local owner = net.ReadEntity()
            local ply = LocalPlayer()
            local npc = player.GetAll()[#player.GetAll()]
            npc.PAPNpcBomb = true
            npc.PAPNpcBombName = name

            -- Adding an outline around the NPCs
            if (ply.IsTraitorTeam and ply:IsTraitorTeam()) or ply:GetRole() == ROLE_TRAITOR then
                self:AddHook("PreDrawHalos", function()
                    local npcs = {}

                    -- Don't draw a halo around an NPC if they're dead or not valid
                    for _, bot in ipairs(player.GetAll()) do
                        if bot.PAPNpcBomb and bot:Alive() and not bot:IsSpec() then
                            table.insert(npcs, bot)
                        end
                    end

                    halo.Add(npcs, Color(255, 230, 0), 0, 0, 1, true, true)
                end)
            end

            -- Custom roles name changing hooks
            if CR_VERSION then
                self:AddHook("TTTTargetIDPlayerName", function(tgt, client, text, clr)
                    if tgt.PAPNpcBombName then return tgt.PAPNpcBombName, clr end
                end)

                self:AddHook("TTTScoreboardPlayerName", function(tgt, client, currentName)
                    if tgt.PAPNpcBombName then return tgt.PAPNpcBombName end
                end)
            end

            -- Nanny cam for the player that used the weapon that spawned the NPC
            if IsValid(owner) and owner == ply then
                local frame = vgui.Create("DFrame")
                frame:SetSize(ScrW() / 3, ScrH() / 3)
                frame:SetPos(0, 0)
                frame:ShowCloseButton(false)
                frame:SetTitle("")

                function frame:Paint(w, h)
                    if not IsValid(npc) then
                        self:Close()

                        return
                    end

                    local x, y = self:GetPos()
                    local clipping = DisableClipping(true)

                    render.RenderView({
                        angles = Angle(0, npc:EyeAngles().yaw, 0),
                        origin = npc:GetPos() + Vector(0, 0, 100),
                        x = x,
                        y = y,
                        w = w,
                        h = h
                    })

                    DisableClipping(clipping)
                end
            end
        end)
    end

    -- Spawning the NPC bomb
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

            local npc = player.GetAll()[#player.GetAll()]
            npc:SpawnForRound(true)
            npc:SetModel(model)
            npc:Give("weapon_zm_shotgun")
            -- Used for "ShouldCollide" hook
            npc:SetCustomCollisionCheck(true)
            -- Try to make NPC unkillable
            npc:GodEnable()
            npc.PAPOwner = owner
            npc.PAPNpcBombName = name

            npc.PAPExplodeNPCBomb = function()
                -- "self" refers to the SWEP, not the NPC
                if npc.PAPExploded then return end
                npc.PAPExploded = true
                local pos = npc:GetPos()
                local radius = radiusCvar:GetInt()
                local damage = damageCvar:GetInt()
                local attacker = npc.PAPOwner or npc
                util.BlastDamage(npc, attacker, pos, radius, damage)
                local effect = EffectData()
                effect:SetStart(pos)
                effect:SetOrigin(pos)
                effect:SetScale(radius)
                effect:SetRadius(radius)
                effect:SetMagnitude(damage)
                util.Effect("Explosion", effect, true, true)
                sound.Play("c4.explode", npc:GetPos(), 60, 150)

                if SERVER then
                    npc:Kick()
                end
            end

            timer.Simple(0.5, function()
                npc:SetNWString("PlayerName", name)
                npc:SetName(name)
                npc:SelectWeapon("weapon_zm_shotgun")
            end)

            -- Switching roles of the NPC back and forth so the round can end
            local timername = "TTTPAPRemoteNpcBombRoleSwitch" .. npc:EntIndex()

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
            self.PAPRevivedNPC = npc
        end)
    end

    -- Exploding NPC on dying
    -- NPC shouldn't be killable, but we all know it's going to happen somehow...
    self:AddHook("PostPlayerDeath", function(ply)
        if not IsValid(ply) or not ply.PAPNpcBomb then return end
        ply:PAPExplodeNPCBomb()
    end)

    -- Exploding NPC on getting near another player
    if SERVER then
        self:AddHook("ShouldCollide", function(ent1, ent2)
            if not self:IsPlayer(ent1) or not self:IsPlayer(ent2) then return end
            if not ent1.PAPNpcBomb and not ent2.PAPNpcBomb then return end

            if ent1:GetPos():Distance(ent2:GetPos()) < triggerRadiusCvar:GetInt() then
                if ent1.PAPNpcBomb then
                    ent1:PAPExplodeNPCBomb()
                end

                if ent2.PAPNpcBomb then
                    ent2:PAPExplodeNPCBomb()
                end
            end
        end)
    end

    -- Exploding NPC on right-click
    function SWEP:SecondaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()

        if IsValid(self.PAPRevivedNPC) then
            self.PAPRevivedNPC:PAPExplodeNPCBomb()
        elseif IsValid(owner) then
            owner:PrintMessage(HUD_PRINTCENTER, "Couldn't find the NPC!")
            owner:PrintMessage(HUD_PRINTTALK, "Couldn't find the NPC!")
        end

        self:Remove()
    end
end

function UPGRADE:Reset()
    if CLIENT then return end

    for _, bot in ipairs(player.GetAll()) do
        if bot.PAPNpcBomb then
            bot:Kick()
        end
    end
end

TTTPAP:Register(UPGRADE)