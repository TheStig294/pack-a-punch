local UPGRADE = {}
UPGRADE.id = "prop_sprayer"
UPGRADE.class = "weapon_ttt_propexploder"
UPGRADE.name = "Prop Sprayer"
UPGRADE.desc = "Exploded props spray more props everywhere!"

function UPGRADE:Apply(SWEP)
    -- Modified from the prop blaster by Vantensman: https://steamcommunity.com/sharedfiles/filedetails/?id=2085047179
    local models = {"models/props_c17/oildrum001.mdl", "models/props_interiors/vendingmachinesoda01a.mdl", "models/props_wasteland/laundry_cart001.mdl", "models/props_wasteland/controlroom_filecabinet002a.mdl", "models/props_junk/wood_crate001a_damaged.mdl", "models/props_interiors/Furniture_Couch01a.mdl", "models/props_interiors/refrigerator01a.mdl", "models/props_interiors/Radiator01a.mdl", "models/props_wasteland/kitchen_shelf002a.mdl", "models/props_wasteland/kitchen_shelf001a.mdl", "models/props_wasteland/laundry_dryer002.mdl", "models/props_c17/oildrum001_explosive.mdl", "models/props_interiors/BathTub01a.mdl", "models/props_junk/TrashDumpster01a.mdl", "models/props_wasteland/prison_bedframe001b.mdl", "models/props_c17/Lockers001a.mdl", "models/props_c17/furnitureStove001a.mdl", "models/props_c17/shelfunit01a.mdl", "models/props_junk/TrafficCone001a.mdl", "models/props_wasteland/cafeteria_table001a.mdl", "models/props_c17/bench01a.mdl", "models/props_c17/FurnitureRadiator001a.mdl", "models/props_interiors/Furniture_Couch02a.mdl", "models/props_vehicles/car001b_phy.mdl", "models/props_c17/FurnitureFridge001a.mdl", "models/props_borealis/bluebarrel001.mdl", "models/props_wasteland/controlroom_chair001a.mdl", "models/props_debris/metal_panel02a.mdl", "models/props_vehicles/tire001a_tractor.mdl", "models/props_interiors/Furniture_Lamp01a.mdl", "models/props_c17/FurnitureSink001a.mdl", "models/props_trainstation/trashcan_indoor001a.mdl", "models/props_wasteland/prison_heater001a.mdl", "models/props_junk/CinderBlock01a.mdl", "models/props_vehicles/generatortrailer01.mdl", "models/props_vehicles/wagon001a_phy.mdl", "models/props_lab/partsbin01.mdl", "models/props_junk/bicycle01a.mdl", "models/props_lab/monitor02.mdl", "models/props_lab/monitor01b.mdl", "models/props_lab/monitor01a.mdl", "models/props_c17/chair_office01a.mdl"}

    local forceDirs = {-26000, 26000}

    SWEP.PAPOldSecondaryAttack = SWEP.SecondaryAttack

    function SWEP:SecondaryAttack()
        if not IsValid(self) then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local prop = owner.PEProp

        timer.Simple(0.5, function()
            if not IsValid(prop) then return end

            for i = 1, 30 do
                local newProp = ents.Create("prop_physics")
                newProp:SetModel(models[math.random(#models)])
                newProp:SetPos(prop:LocalToWorld(prop:OBBCenter()) + Vector(math.random(-200, 200), math.random(-200, 200), math.random(25, 75)))
                newProp:Spawn()
                local phys = newProp:GetPhysicsObject()
                if not IsValid(phys) then return end
                phys:AddAngleVelocity(VectorRand(-155, 155) * phys:GetMass())
                phys:ApplyForceCenter(Vector(forceDirs[math.random(#forceDirs)], forceDirs[math.random(#forceDirs)], 0) * phys:GetMass())
            end
        end)

        return self:PAPOldSecondaryAttack()
    end
end

TTTPAP:Register(UPGRADE)