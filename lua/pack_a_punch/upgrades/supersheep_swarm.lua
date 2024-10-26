local UPGRADE = {}
UPGRADE.id = "supersheep_swarm"
UPGRADE.class = "weapon_ttt_supersheep"
UPGRADE.name = "Supersheep Swarm"
UPGRADE.desc = "Sends out a swarm of supersheep,\nwith a much bigger explosion (+ a bonus sheep!)"

function UPGRADE:Apply(SWEP)
    function SWEP:PlaceSupersheep(ply)
        -- For some very annoying reason copying the base code was the only way I could avoid an occasional crash
        -- I have no idea what was causing it... It seemed to not like self:AddToHook() and similar ways of avoiding code-copying ¯\_(ツ)_/¯
        if CLIENT then return end
        local clearedEyeTrace = Vector(ply:GetEyeTrace().Normal.x, ply:GetEyeTrace().Normal.y, 0)
        local ent = ents.Create("ttt_pap_ent_supersheep")
        if not IsValid(ent) then return end
        clearedEyeTrace = Vector(ply:GetEyeTrace().Normal.x, ply:GetEyeTrace().Normal.y, 0)
        local perpEyeTrace = Vector(-clearedEyeTrace.y, clearedEyeTrace.x, 0)
        local eyeAngles = ply:EyeAngles()
        local duckOffset = Vector(0, 0, 0)

        if ply:Crouching() then
            duckOffset = ply:GetViewOffsetDucked()
        end

        ent:SetPos(ply:EyePos() + clearedEyeTrace * 80 + Vector(0, 0, -40) + perpEyeTrace * -10 + duckOffset)
        ent:SetAngles(Angle(0, eyeAngles.y, 0))
        ent.Owner = ply
        ent:Spawn()
        ent:Activate()
        ply:SetNWEntity("supersheep_entity", ent)
        local phys = ent:GetPhysicsObject()

        if not IsValid(phys) then
            ent:Remove()

            return
        else
            -- Give it the PaP camo
            ent:SetPAPCamo()
            ent.PAPSheepChildren = {}

            -- Spawn non-solid extra sheep models 
            for i = 1, 10 do
                local child = ents.Create("prop_dynamic")
                child:SetModel("models/weapons/ent_ttt_supersheep.mdl")
                -- Set all the child sheep at random positions
                local childPos = ent:GetPos() + VectorRand(-50, 50)
                child:SetPos(childPos)
                child:SetAngles(ent:GetAngles())
                child:SetModelScale(0.5)
                child:SetParent(ent)
                child:Spawn()
                local sequence = child:LookupSequence(ACT_VM_PRIMARYATTACK)
                child:ResetSequence(sequence)
                table.insert(ent.PAPSheepChildren, child)
            end
        end

        return ent
    end
end

TTTPAP:Register(UPGRADE)