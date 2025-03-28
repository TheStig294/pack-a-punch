local UPGRADE = {}
UPGRADE.id = "jester_converter"
UPGRADE.class = "shared"
UPGRADE.name = "Jester Converter"
UPGRADE.desc = "Converts you into a jester while held,\nand back to your original role while not held!"

-- Should account for town of terror, custom roles, and TTT2 all in one (Well... who knows with TTT2 lol) 
function UPGRADE:Condition()
    local SWEP = weapons.Get("shared")
    -- Because of the terribly generic classname, we have to perform extra checks to actually make sure this is the jester emulator...

    return ROLE_JESTER ~= nil and SWEP.Contact and SWEP.Contact == "https://steamcommunity.com/profiles/76561198032985687/" and SWEP.WorldModel and SWEP.WorldModel == "models/weapons/w_rif_m4a1.mdl"
end

function UPGRADE:Apply(SWEP)
    local function ToggleJester(ply, toJester)
        -- Add this delay so that the round end window displays the killed jester player as a jester and not their original role
        timer.Simple(0.1, function()
            if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end

            if toJester then
                if not ply.TTTPAPJesterConverterRole then
                    ply.TTTPAPJesterConverterRole = ply:GetRole()
                end

                ply:SetRole(ROLE_JESTER)

                if SERVER then
                    timer.Simple(0.1, SendFullStateUpdate)
                end
            elseif ply.TTTPAPJesterConverterRole then
                ply:SetRole(ply.TTTPAPJesterConverterRole)

                if SERVER then
                    timer.Simple(0.1, SendFullStateUpdate)
                end
            end
        end)
    end

    ToggleJester(SWEP:GetOwner(), true)

    function SWEP:Deploy()
        ToggleJester(self:GetOwner(), true)

        return true
    end

    function SWEP:Holster()
        ToggleJester(self:GetOwner(), false)

        return true
    end

    function SWEP:PreDrop()
        ToggleJester(self:GetOwner(), false)
    end

    function SWEP:OnRemove()
        ToggleJester(self:GetOwner(), false)
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPJesterConverterRole = nil
    end
end

TTTPAP:Register(UPGRADE)