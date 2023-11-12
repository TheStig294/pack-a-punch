local UPGRADE = {}
UPGRADE.id = "barrel_launcher"
UPGRADE.class = "weapon_randomlauncher"
UPGRADE.name = "Barrel Launcher"
UPGRADE.desc = "No horse prop! Only launches barrels\nHave a chance to be explosive!"

function UPGRADE:Apply(SWEP)
    local props = {"models/props_borealis/bluebarrel001.mdl", "models/props_c17/oildrum001_explosive.mdl", "models/props_phx/facepunch_barrel.mdl"}

    function SWEP:ThrowChair()
        self:EmitSound("Metal.SawbladeStick")
        if CLIENT then return end
        local ent = ents.Create("prop_physics")
        if not IsValid(ent) then return end
        ent:SetModel(props[math.random(#props)])
        local owner = self:GetOwner()
        ent:SetPos(owner:EyePos() + (owner:GetAimVector() * 16))
        ent:SetAngles(owner:EyeAngles())
        ent:Spawn()
        ent:SetMaterial(TTTPAP.camo)
        local phys = ent:GetPhysicsObject()

        if not IsValid(phys) then
            ent:Remove()

            return
        end

        local velocity = owner:GetAimVector()
        velocity = velocity * 1000000
        velocity = velocity + (VectorRand() * 10) -- a random element
        phys:ApplyForceCenter(velocity)
        cleanup.Add(owner, "props", ent)
        undo.Create("Thrown_Chair")
        undo.AddEntity(ent)
        undo.SetPlayer(owner)
        undo.Finish()
    end
end

TTTPAP:Register(UPGRADE)