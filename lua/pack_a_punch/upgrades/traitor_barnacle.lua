local UPGRADE = {}
UPGRADE.id = "traitor_barnacle"
UPGRADE.class = "weapon_ttt_barnacle"
UPGRADE.name = "Traitor Barnacle"
UPGRADE.desc = "Plays a 'Help I'm stuck in a barnacle' sound,\nkilled players become traitors! (But still stuck)"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPlaceTurret = SWEP.PlaceTurret

    function SWEP:PlaceTurret()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local pos = owner:GetEyeTrace().HitPos
        self:PAPOldPlaceTurret()

        for _, barnacle in ipairs(ents.FindByClass("npc_barnacle")) do
            if barnacle:GetPos() == pos then
                barnacle.PAPTraitorBarnacle = true
                barnacle:SetMaterial(TTTPAP.camo)
                barnacle.CurrentSound = 1
            end
        end
    end

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if CLIENT and not self:IsPlayer(ply) then return end
        local barnacle = dmg:GetInflictor()
        if not barnacle.PAPTraitorBarnacle then return end

        -- Plays the "Help i'm stuck in a barnacle!" sound for everyone
        if barnacle.CurrentSound > 4 then
            barnacle.CurrentSound = 1
        end

        if not ply.PAPTraitorBarnacleSoundCooldown then
            ply:EmitSound("ttt_pack_a_punch/traitor_barnacle/help" .. barnacle.CurrentSound .. ".mp3", 0)
            barnacle.CurrentSound = barnacle.CurrentSound + 1
            ply.PAPTraitorBarnacleSoundCooldown = true

            timer.Simple(2, function()
                ply.PAPTraitorBarnacleSoundCooldown = false
            end)
        end

        -- If the current damage is about to kill the player, and they are not a traitor, then heal them and turn them into a traitor instead!
        if ply:Health() <= dmg:GetDamage() and ply:GetRole() ~= ROLE_TRAITOR and (not ply.IsTraitorTeam or not ply:IsTraitorTeam()) then
            ply:SetRole(ROLE_TRAITOR)
            ply:SetHealth(ply:GetMaxHealth())
            ply:ChatPrint("You were killed by an upgraded banacle and changed to a traitor!\nHopefully someone frees you...")
            SendFullStateUpdate()

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)