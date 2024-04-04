local UPGRADE = {}
UPGRADE.id = "passive_ghoster"
UPGRADE.class = "weapon_ttt_gwh_ghosting"
UPGRADE.name = "Passive Ghoster"
UPGRADE.desc = "You automatically see all dead players' messages!"

function UPGRADE:Apply(SWEP)
    timer.Create("TTTPAPPassiveGhoster", 1, 0, function()
        for _, ply in player.Iterator() do
            ply:SetNWBool("TTTIsGhosting", true)
        end
    end)
end

function UPGRADE:Reset()
    timer.Remove("TTTPAPPassiveGhoster")

    for _, ply in player.Iterator() do
        ply:SetNWBool("TTTIsGhosting", false)
    end
end

TTTPAP:Register(UPGRADE)