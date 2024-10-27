local UPGRADE = {}
UPGRADE.id = "wall_hacker"
UPGRADE.class = "ttt_player_pinger"
UPGRADE.name = "Wall Hacker"
UPGRADE.desc = "Lets everyone see the outlines!\nIf you're a baddie, just your teammates!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        self:PAPOldPrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not UPGRADE:IsPlayer(owner) then return end

        if owner.IsTraitorTeam and owner:IsTraitorTeam() then
            -- If a traitor uses an upgraded player pinger, and CR is installed, all traitor team members get wall hacks
            for _, ply in player.Iterator() do
                if not UPGRADE:IsAlive(ply) then continue end
                if ply == owner then continue end

                if ply.IsTraitorTeam and ply:IsTraitorTeam() then
                    ply:PrintMessage(HUD_PRINTTALK, "A fellow traitor used an upgraded player pinger, you recieved temorary wall hacks!")
                    self:ActivatePing(ply)
                end
            end
        elseif owner:GetRole() == ROLE_TRAITOR then
            -- If a traitor uses an upgraded player pinger, and CR isn't installed, all traitors get wall hacks
            for _, ply in player.Iterator() do
                if not UPGRADE:IsAlive(ply) then continue end
                if ply == owner then continue end

                if ply:GetRole() == ROLE_TRAITOR then
                    ply:PrintMessage(HUD_PRINTTALK, "A fellow traitor used an upgraded player pinger, you recieved temorary wall hacks!")
                    self:ActivatePing(ply)
                end
            end
        elseif owner.IsIndependentTeam and owner:IsIndependentTeam() then
            -- If an independent role uses an upgraded player pinger, all players with the same role as the owner get wall hacks
            for _, ply in player.Iterator() do
                if not UPGRADE:IsAlive(ply) then continue end
                if ply == owner then continue end

                if ply:GetRole() == owner:GetRole() then
                    ply:PrintMessage(HUD_PRINTTALK, "A teammate used an upgraded player pinger, you recieved temorary wall hacks!")
                    self:ActivatePing(ply)
                end
            end
        else
            -- Otherwise, all players get wall hacks
            for _, ply in player.Iterator() do
                if not UPGRADE:IsAlive(ply) then continue end
                if ply == owner then continue end
                ply:PrintMessage(HUD_PRINTTALK, "Someone used an upgraded player pinger, you recieved temorary wall hacks!")
                self:ActivatePing(ply)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)