local UPGRADE = {}
UPGRADE.id = "rezombificator"
UPGRADE.class = "weapon_mad_zombificator"
UPGRADE.name = "Re-Zombification Device"
UPGRADE.desc = "You can revive zombies!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:ValidateTarget(ply, body, bone)
            return true, ""
        end
    end
end

TTTPAP:Register(UPGRADE)