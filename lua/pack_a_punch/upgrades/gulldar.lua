local UPGRADE = {}
UPGRADE.id = "gulldar"
UPGRADE.class = "weapon_ttt_seekgull"
UPGRADE.name = "Gull-dar"
UPGRADE.desc = "Keeps spawning Seekgulls intermittently from where it explodes"

UPGRADE.convars = {
    {
        name = "pap_gulldar_delay",
        type = "int"
    }
}

local delayCvar = CreateConVar("pap_gulldar_delay", "20", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds between spawning Seekgulls", 1, 60)

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "CreateGrenade", function(_, _, _, _, ply)
        ply.TTTPAPGulldar = true
    end)

    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) or ent:GetClass() ~= "ttt_seekgull_proj" then return end
            local owner = ent:GetOwner()
            if not IsValid(owner) or not owner.TTTPAPGulldar then return end
            ent:SetPAPCamo()
            ent.PAPUpgrade = self
            owner.TTTPAPGulldar = nil
        end)
    end)

    self:AddHook("EntityRemoved", function(oldGren, _)
        if not self:IsValidUpgrade(oldGren) or oldGren:GetClass() ~= "ttt_seekgull_proj" then return end
        local owner = oldGren:GetOwner()
        local gren = ents.Create("ttt_seekgull_proj")
        if not IsValid(gren) then return end
        gren:SetPos(oldGren:GetPos())
        gren:SetAngles(oldGren:GetAngles())
        gren:SetOwner(owner)
        gren:SetThrower(owner)
        gren:SetGravity(0.4)
        gren:SetFriction(0.2)
        gren:SetElasticity(0.45)
        gren:Spawn()
        gren:PhysWake()
        gren:SetPAPCamo()
        gren.PAPUpgrade = self
        local oldPhys = oldGren:GetPhysicsObject()
        local phys = gren:GetPhysicsObject()

        if IsValid(oldPhys) and IsValid(phys) then
            phys:SetVelocity(oldPhys:GetVelocity())
            phys:AddAngleVelocity(oldPhys:GetAngleVelocity())
        end

        gren:SetDetonateExact(CurTime() + delayCvar:GetInt())
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPGulldar = nil
    end
end

TTTPAP:Register(UPGRADE)