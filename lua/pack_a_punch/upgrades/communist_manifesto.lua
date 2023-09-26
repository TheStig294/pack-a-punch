local UPGRADE = {}
UPGRADE.id = "communist_manifesto"
UPGRADE.class = "weapon_ttt_comrade_bomb"
UPGRADE.name = "Communist Manifesto"
UPGRADE.desc = "Hold left-click next to someone\nto convert them into a traitor!"
UPGRADE.newClass = "weapon_com_manifesto"

UPGRADE.convars = {
    {
        name = "pap_communist_manifesto_convert_secs",
        type = "int"
    }
}

local convertSecsConvar = CreateConVar("pap_communist_manifesto_convert_secs", 8, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to convert a player", 0, 30)

function UPGRADE:Condition()
    return weapons.Get("weapon_com_manifesto") ~= nil
end

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldConvert = SWEP.Convert

    if SWEP.SetDeviceDuration then
        SWEP:SetDeviceDuration(convertSecsConvar:GetInt())
    end

    function SWEP:Convert(entity)
        self:PAPOldConvert(entity)

        -- Create red smoke effect
        timer.Simple(math.max(0, convertSecsConvar:GetInt() - 3), function()
            net.Start("explosionSmokeComradeBomb")
            net.WriteEntity(entity)
            net.Broadcast()
        end)
    end

    function SWEP:DoConvert()
        local ply = self.TargetEntity
        ply:StripRoleWeapons()
        ply:SetRole(ROLE_TRAITOR)
        ply:PrintMessage(HUD_PRINTCENTER, "Welcome to the traitor team, comrade")
        ply:PrintMessage(HUD_PRINTTALK, "Welcome to the traitor team, comrade")
        net.Start("TTT_Communism_Converted")
        net.WriteString(ply:Nick())
        net.Broadcast()
        -- Not actually an error, but it resets the things we want
        self:FireError()
        self:DoUnfreeze()
        SendFullStateUpdate()
        -- Reset the victim's max health
        SetRoleMaxHealth(ply)

        timer.Simple(0.1, function()
            self:Remove()
        end)
    end
end

TTTPAP:Register(UPGRADE)