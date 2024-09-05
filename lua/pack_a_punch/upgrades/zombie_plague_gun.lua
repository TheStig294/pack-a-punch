local UPGRADE = {}
UPGRADE.id = "zombie_plague_gun"
UPGRADE.class = "weapon_plm_dartgun"
UPGRADE.name = "Zombie Plague Gun"
UPGRADE.desc = "Victims to the plague respawn and change to your side!"

function UPGRADE:Apply(SWEP)
    self:AddHook("TTTOnCorpseCreated", function(rag, ply)
        if not ply.TTTPlaguemasterPlagueDeath or ply.TTTPAPZombiePlagueGunRespawned then return end
        ply.TTTPAPZombiePlagueGunRespawned = true

        timer.Simple(0.1, function()
            if self:IsAlivePlayer(ply) then return end
            ply:SpawnForRound(true)
            ply:SetRole(ROLE_PLAGUEMASTER)
            ply:QueueMessage(MSG_PRINTBOTH, "You have changed into " .. ROLE_STRINGS_EXT[ROLE_PLAGUEMASTER] .. ", spread the plague to win!")
            SendFullStateUpdate()

            timer.Simple(0.1, function()
                local dartGunKind = weapons.Get(self.class).Kind

                for _, wep in ipairs(ply:GetWeapons()) do
                    if wep.Kind == dartGunKind then
                        wep:Remove()
                        break
                    end
                end

                if IsValid(rag) then
                    ply:SetPos(rag:GetPos())
                    rag:Remove()
                end

                timer.Simple(0.1, function()
                    ply:Give(UPGRADE.class)
                end)
            end)
        end)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPZombiePlagueGunRespawned = nil
    end
end

TTTPAP:Register(UPGRADE)