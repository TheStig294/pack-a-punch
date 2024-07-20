local UPGRADE = {}
UPGRADE.id = "super_sheep_swarm"
UPGRADE.class = "weapon_ttt_supersheep"
UPGRADE.name = "Super Sheep Swarm"
UPGRADE.desc = "Sends out a swarm of supersheep with a much larger explosion!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPlaceSupersheep = SWEP.PlaceSupersheep

    function SWEP:PlaceSupersheep(ply)
        local parent = self:PAPOldPlaceSupersheep(ply)
        -- Mark the supersheep as upgraded and give it the PaP camo
        parent.PAPSuperSheepSwarm = true
        parent:SetMaterial(TTTPAP.camo)

        -- Spawn non-solid extra sheep models 
        if SERVER then
            for i = 1, 10 do
                local child = ents.Create("prop_dynamic")
                child:SetModel("models/weapons/ent_ttt_supersheep.mdl")
                -- Set all the child sheep at random positions
                local childPos = parent:GetPos() + VectorRand(-50, 50)
                child:SetPos(childPos)
                child:SetAngles(parent:GetAngles())
                child:SetModelScale(0.5)
                child:SetMaterial(TTTPAP.camo)
                child:SetParent(parent)
                child:Spawn()
                local sequence = child:LookupSequence(ACT_VM_PRIMARYATTACK)
                child:ResetSequence(sequence)
                child.PAPSuperSheepSwarm = true
            end
        end

        -- Make sure all child sheep props are invisible when the main sheep goes invisible too!
        parent.PAPOldExplode = parent.Explode

        function parent:Explode()
            self:PAPOldExplode()

            if self:GetNWBool("exploded") then
                for _, child in ipairs(self:GetChildren()) do
                    child:SetNoDraw(true)
                end
            end

            for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 200)) do
                -- Don't damage other supersheep, as this causes an infinite loop and crash...
                if ent.PAPSuperSheepSwarm then continue end
                local dmg = DamageInfo()
                dmg:SetDamageType(DMG_BLAST)
                dmg:SetDamage(1000)
                dmg:SetAttacker(self.Owner)
                dmg:SetInflictor(self)
                ent:TakeDamageInfo(dmg)
            end
        end
        -- This function expects the supersheep entity to be returned

        return parent
    end
end

TTTPAP:Register(UPGRADE)