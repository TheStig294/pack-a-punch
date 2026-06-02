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
    self:SetClip(SWEP, 420)

    self:AddToHook(SWEP, "PrimaryAttack", function()
        self:SetClip(SWEP, 420)
        if not util.IsValidModel(playermodelList[1]) then return end

        if playermodelIndex > #playermodelList then
            table.Shuffle(playermodelList)
            playermodelIndex = 1
        end

        local owner = SWEP:GetOwner()

        for _, ply in player.Iterator() do
            if ply.TTTGamerCheetoMarked and not playermodels[ply:GetModel()] then
                local playermodel = playermodelList[playermodelIndex]
                playermodelIndex = playermodelIndex + 1
                self:SetModel(ply, playermodel)
                local mlgSound = "ttt_pack_a_punch/mlg_awp/mlg" .. math.random(10) .. ".mp3"
                ply:EmitSound(mlgSound)

                local plys = {ply}

                if IsValid(owner) then
                    table.insert(plys, owner)
                end

                if SERVER then
                    ply:ChatPrint("You have been transformed by the Gamer's Dewritos hand!")
                    -- Hijack an old weapon upgrade function for the No-Scope AWP
                    net.Start("TTTPAPMlgAwpDeathEffects")
                    net.Send(plys)
                end
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)