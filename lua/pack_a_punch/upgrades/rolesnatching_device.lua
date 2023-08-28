local UPGRADE = {}
UPGRADE.id = "rolesnatching_device"
UPGRADE.class = "weapon_bod_bodysnatch"
UPGRADE.name = "Rolesnatching Device"
UPGRADE.desc = "Works on living players instead!"

function UPGRADE:Apply(SWEP)
    SWEP.DeadTarget = false

    function SWEP:OnSuccess(ply)
        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, owner, self)
        net.Start("TTT_Bodysnatched")
        net.Send(ply)
        local role = ply:GetRole()
        net.Start("TTT_ScoreBodysnatch")
        net.WriteString(ply:Nick())
        net.WriteString(owner:Nick())
        net.WriteString(ROLE_STRINGS_EXT[role])
        net.WriteString(owner:SteamID64())
        net.Broadcast()
        owner:SetRole(role)
        ply:MoveRoleState(owner, true)
        owner:SelectWeapon("weapon_zm_carry")
        owner:SetNWBool("WasBodysnatcher", true)
        SetRoleMaxHealth(owner)
        SendFullStateUpdate()
    end
    
    function SWEP:GetProgressMessage(ply, body, bone)
        return "ROLESNATCHING " .. string.upper(ply:Nick())
    end
end

TTTPAP:Register(UPGRADE)