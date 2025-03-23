local UPGRADE = {}
UPGRADE.id = "time_skip_time_stop"
UPGRADE.class = "weapon_ttt_timestop"
UPGRADE.name = "Time Skip"
UPGRADE.desc = "Slows down time for everyone but you!\nLasts longer and gain damage resistance while acitve"

UPGRADE.convars = {
    {
        name = "pap_time_skip_time_stop_length_secs",
        type = "int"
    },
    {
        name = "pap_time_skip_time_stop_dmg_resist_mult",
        type = "float",
        decimal = 1
    },
}

local lengthSecsCvar = CreateConVar("pap_time_skip_time_stop_length_secs", 10, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds length of time skip", 0, 60)

local dmgResistCvar = CreateConVar("pap_time_skip_time_stop_dmg_resist_mult", 0.5, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage resistance multiplier", 0, 1)

local function StopSkip(wep, owner, timername)
    if timername then
        timer.Remove(timername)
    end

    if IsValid(owner) then
        owner.PAPTimeSkipTSDmgResist = nil
    end

    if IsValid(wep) then
        wep:Remove()
    end

    timer.Simple(0.1, function()
        if SERVER then
            game.SetTimeScale(1)
        end

        for _, ply in pairs(player.GetAll()) do
            if SERVER then
                ply:SetLaggedMovementValue(1)
            end

            ply:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 200), 0, 0)

            if IsValid(ply:GetViewModel()) then
                ply:GetViewModel():SetPlaybackRate(1)
            end
        end
    end)

    timer.Simple(0.2, function()
        if SERVER then
            net.Start("TTTPAPTimeSkipTSScreenEffectsRemove")
            net.Broadcast()
        end
    end)
end

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPTimeSkipTSScreenEffects")
        util.AddNetworkString("TTTPAPTimeSkipTSScreenEffectsRemove")
    end

    local timername = SWEP:GetOwner():SteamID64() .. "TTTPAPTimeSkipTSEnd"

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.PAPTimeSkipTSDmgResist then
            StopSkip(nil, ply, timername)
        end
    end)

    function SWEP:PrimaryAttack()
        if SERVER and not self.PAPUsedTimeSkip then
            self.PAPUsedTimeSkip = true
            local owner = self:GetOwner()
            BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/time_skip/time_skip.mp3\")")

            timer.Simple(7.256, function()
                if not IsValid(owner) or not IsValid(self) then return end
                game.SetTimeScale(0.5)
                owner:SetLaggedMovementValue(2)
                owner.PAPTimeSkipTSDmgResist = true

                for _, ply in player.Iterator() do
                    ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 200), 0.5, lengthSecsCvar:GetInt() - 0.5)
                end

                util.ScreenShake(owner:GetPos(), 20, 10, 1.5, 1000, true)
                net.Start("TTTPAPTimeSkipTSScreenEffects")
                net.Broadcast()

                timer.Create(timername, lengthSecsCvar:GetInt(), 1, function()
                    StopSkip(self, owner, timername)
                end)
            end)
        end
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.PAPTimeSkipTSDmgResist then
            dmg:ScaleDamage(dmgResistCvar:GetFloat())
        end
    end)

    if CLIENT then
        local playedSound = false

        -- Adds a blur effect around the edges of the screen
        net.Receive("TTTPAPTimeSkipTSScreenEffects", function()
            playedSound = false

            hook.Add("RenderScreenspaceEffects", "TTTPAPTimeSkipTSScreenEffects", function()
                DrawToyTown(4, ScrH() / 1.75)
            end)
        end)

        net.Receive("TTTPAPTimeSkipTSScreenEffectsRemove", function()
            hook.Remove("RenderScreenspaceEffects", "TTTPAPTimeSkipTSScreenEffects")

            if not playedSound then
                playedSound = true
                surface.PlaySound("the_world_time_start.mp3")
            end
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        timer.Remove(ply:SteamID64() .. "TTTPAPTimeSkipTSEnd")
        StopSkip(nil, ply)
    end
end

TTTPAP:Register(UPGRADE)