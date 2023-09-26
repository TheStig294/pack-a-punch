local UPGRADE = {}
UPGRADE.id = "communist_bomb"
UPGRADE.class = "weapon_ttt_comrade_bomb"
UPGRADE.name = "Communist Bomb"
UPGRADE.desc = "Turns players into communists"

function UPGRADE:Condition()
    return ROLE_COMMUNIST ~= nil
end

function UPGRADE:Apply(SWEP)
    function SWEP:Asplode()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not UPGRADE:IsPlayer(owner) then return end

        for _, ent in ipairs(ents.FindInSphere(owner:GetPos(), 300)) do
            if UPGRADE:IsPlayer(ent) then
                ent:SetRole(ROLE_COMMUNIST)
                ent:StripRoleWeapons()
                ent:Give("weapon_com_manifesto")
                ent:SelectWeapon("weapon_com_manifesto")

                if ent ~= owner then
                    ent:PrintMessage(HUD_PRINTCENTER, "You are now a Communist!")
                    ent:PrintMessage(HUD_PRINTTALK, "You are now a Communist! Convert everyone to communism using your maifesto to win!")
                end
            end
        end

        SendFullStateUpdate()
        owner:Kill()
        self:Remove()
    end
end

TTTPAP:Register(UPGRADE)