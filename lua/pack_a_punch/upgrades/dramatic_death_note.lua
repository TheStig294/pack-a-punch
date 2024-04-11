local UPGRADE = {}
UPGRADE.id = "dramatic_death_note"
UPGRADE.class = "death_note_ttt"
UPGRADE.name = "Dramatic Death Note"
UPGRADE.desc = "Each death type has a new effect!"

local upgradeDescriptions = {
    prematureburial = "Victim sinks way further into the ground, plays the lego yoda death noise",
    ignite = "x5 fire damage, starts fires after they die",
    heartattack = "Plays the vine boom",
    fall = "Plays a cartoon fling noise",
    explode = "Extra large explosion and starts some fires!"
}

function UPGRADE:Apply(SWEP)
    local own = SWEP:GetOwner()

    if IsValid(own) then
        own.PAPDramaticDeathNote = true
    end

    function SWEP:OwnerChanged()
        local owner = SWEP:GetOwner()

        if IsValid(owner) then
            owner.PAPDramaticDeathNote = true
        end
    end

    self:AddToHook(SWEP, "PrimaryAttack", function()
        if IsFirstTimePredicted() and SERVER then
            SWEP:GetOwner():ChatPrint(upgradeDescriptions[DN_DeathTypes[SWEP.TTTDeathType]])
        end
    end)

    self:AddHook("dn_module_prematureburial", function(owner, victim)
        if not owner.PAPDramaticDeathNote then return end
        local timername = owner:SteamID64() .. "TTTPAPDramaticDeathNoteBurial"
        victim:EmitSound("ttt_pack_a_punch/dramatic_death_note/lego_yoda.mp3")
        victim:EmitSound("ttt_pack_a_punch/dramatic_death_note/lego_yoda.mp3")

        timer.Create(timername, 0.01, 500, function()
            if GetRoundState() ~= ROUND_PREP and self:IsAlive(victim) then
                local pos = victim:GetPos()
                pos.z = pos.z - 1
                victim:SetPos(pos)
            else
                timer.Remove(timername)

                return
            end
        end)

        timer.Simple(0, function()
            owner:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.prematureburial)
            victim:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.prematureburial)
        end)
    end)

    self:AddHook("dn_module_ignite", function(owner, victim)
        if not owner.PAPDramaticDeathNote then return end
        victim.PAPDramaticDeathNoteIgnite = true

        timer.Simple(0, function()
            owner:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.ignite)
            victim:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.ignite)
        end)
    end)

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if ent.PAPDramaticDeathNoteIgnite and dmg:IsDamageType(DMG_BURN) then
            dmg:ScaleDamage(5)
        end
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.PAPDramaticDeathNoteIgnite then
            local tr = util.QuickTrace(ply:GetPos(), Vector(0, 0, -1))
            StartFires(ply:GetPos(), tr, 20, 40, false, ply)
            ply.PAPDramaticDeathNoteIgnite = nil
        end
    end)

    self:AddHook("dn_module_heartattack", function(owner, victim)
        if not owner.PAPDramaticDeathNote then return end
        victim:EmitSound("ttt_pack_a_punch/dramatic_death_note/vine_boom.mp3")
        victim:EmitSound("ttt_pack_a_punch/dramatic_death_note/vine_boom.mp3")

        timer.Simple(0, function()
            owner:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.heartattack)
            victim:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.heartattack)
        end)
    end)

    self:AddHook("dn_module_fall", function(owner, victim)
        if not owner.PAPDramaticDeathNote then return end
        victim:EmitSound("ttt_pack_a_punch/dramatic_death_note/cartoon_fling_sound.mp3")
        victim:EmitSound("ttt_pack_a_punch/dramatic_death_note/cartoon_fling_sound.mp3")

        timer.Simple(0, function()
            owner:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.fall)
            victim:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.fall)
        end)
    end)

    self:AddHook("dn_module_explode", function(owner, victim)
        if not owner.PAPDramaticDeathNote then return end
        local timername = owner:SteamID64() .. "TTTPAPDramaticDeathNoteExplode"

        timer.Simple(1, function()
            timer.Remove("Expolde_Countdown")
        end)

        timer.Create(timername, 1, GetConVar("DeathNote_ExplodeTimer"):GetInt(), function()
            if GetRoundState() == ROUND_PREP then
                timer.Remove(timername)

                return
            elseif timer.RepsLeft(timername) == 0 and self:IsAlive(victim) then
                if ConVarExists("ttt_deathnote_kill_after_user_dies") and not GetConVar("ttt_deathnote_kill_after_user_dies"):GetBool() and not self:IsAlive(owner) then
                    return
                else
                    victim:EmitSound("ambient/explosions/explode_3.wav")
                    local explode = ents.Create("env_explosion")
                    explode:SetPos(victim:GetPos())
                    explode:SetOwner(owner)
                    explode:SetKeyValue("iMagnitude", 200)
                    explode:SetKeyValue("iRadiusOverride", 200)
                    explode:Spawn()
                    explode:Fire("Explode", 0, 0)
                    local tr = util.QuickTrace(victim:GetPos(), Vector(0, 0, -1))
                    StartFires(victim:GetPos(), tr, 20, 40, false, owner)
                    owner:ChatPrint("Death Note: " .. victim:Nick() .. " exploded!")

                    timer.Simple(0, function()
                        owner:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.explode)
                        victim:ChatPrint("PAP Upgrade: " .. upgradeDescriptions.explode)
                    end)
                end
            end
        end)
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPDramaticDeathNoteIgnite = nil
        ply.PAPDramaticDeathNote = nil
    end
end

TTTPAP:Register(UPGRADE)