local UPGRADE = {}
UPGRADE.id = "dewritos_hand"
UPGRADE.class = "weapon_gmr_cheeto_fingers"
UPGRADE.name = "Dewritos Hand"
UPGRADE.desc = "Unlimited ammo, transforms players into Dewritos!"

local playermodels = {
    ["models/player/coolranch.mdl"] = true,
    ["models/player/nachocheese.mdl"] = true,
    ["models/player/heatwave.mdl"] = true,
    ["models/player/customritos.mdl"] = true,
    ["models/player/blue_dew.mdl"] = true,
    ["models/player/dew.mdl"] = true,
    ["models/player/orange_dew.mdl"] = true,
    ["models/player/red_dew.mdl"] = true,
    ["models/player/big_dew.mdl"] = true,
    ["models/player/dewrito.mdl"] = true,
    ["models/player/dewrito_blue.mdl"] = true,
    ["models/player/dew_custom.mdl"] = true,
    ["models/player/dewrito_custom.mdl"] = true,
}

local playermodelList = table.GetKeys(playermodels)
local playermodelIndex = 1

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function()
        self:SetClip1(SWEP, SWEP.Primary.ClipSize)
        if not util.IsValidModel(playermodelList[1]) then return end

        if playermodelIndex > #playermodelList then
            table.Shuffle(playermodelList)
            playermodelIndex = 1
        end

        for _, ply in player.Iterator() do
            if ply:GetProperty("TTTGamerCheetoMarked") and not playermodels[ply:GetModel()] then
                local playermodel = playermodelList[playermodelIndex]
                playermodelIndex = playermodelIndex + 1
                self:SetModel(ply, playermodel)
                ply:ChatPrint("You have been marked by the gamer's Dewritos hand!")
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)