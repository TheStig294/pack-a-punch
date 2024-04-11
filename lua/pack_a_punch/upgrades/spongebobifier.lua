local UPGRADE = {}
UPGRADE.id = "spongebobifier"
UPGRADE.class = "weapon_spn_spongifier"
UPGRADE.name = "Spongebobifier"
UPGRADE.desc = "Turns you into spongebob!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldOnSuccess = SWEP.OnSuccess

    -- Spongebob model
    function SWEP:OnSuccess()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if util.IsValidModel("models/players/sb/spongebob_plyr.mdl") then
            UPGRADE:SetModel(owner, "models/players/sb/spongebob_plyr.mdl")
        end

        owner.PAPSpongebobifier = true

        return self:PAPOldOnSuccess()
    end

    -- Spongebob laugh whenever the player takes damage
    self:AddHook("PlayerHurt", function(victim, attacker)
        if victim.PAPSpongebobifier then
            if victim.PAPSpongebobifierLaughCooldown then return end
            victim.PAPSpongebobifierLaughCooldown = true
            victim:EmitSound("ttt_pack_a_punch/spongebobifier/laugh.mp3")

            if IsValid(attacker) then
                attacker:EmitSound("ttt_pack_a_punch/spongebobifier/laugh.mp3")
            end

            timer.Simple(1.5, function()
                if IsValid(victim) then
                    victim.PAPSpongebobifierLaughCooldown = false
                end
            end)
        end
    end)

    -- Spongebob footstep sound effects
    self:AddHook("PlayerFootstep", function(ply, pos, foot)
        if ply.PAPSpongebobifier then
            if foot == 0 then
                ply:EmitSound("ttt_pack_a_punch/spongebobifier/footstep1.mp3")
            else
                ply:EmitSound("ttt_pack_a_punch/spongebobifier/footstep2.mp3")
            end

            return true
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.PAPSpongebobifier = nil
    end
end

TTTPAP:Register(UPGRADE)