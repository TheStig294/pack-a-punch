local UPGRADE = {}
UPGRADE.id = "mudifier"
UPGRADE.class = "weapon_ttt_mud_device_randomat"
UPGRADE.name = "Mudifier"
UPGRADE.desc = "Turns things into 'mud samples', invincible while holding this out!"

function UPGRADE:Apply(SWEP)
    -- Being invincible while held
    if SERVER then
        SWEP.PAPOwner = SWEP:GetOwner()

        if IsValid(SWEP.PAPOwner) then
            SWEP.PAPOwner:GodEnable()
        end

        function SWEP:Deploy()
            local owner = self.PAPOwner or self:GetOwner()
            if not IsValid(owner) then return end
            owner:GodEnable()
        end

        function SWEP:Holster()
            local owner = self.PAPOwner or self:GetOwner()
            if not IsValid(owner) then return end
            owner:GodDisable()

            return true
        end

        function SWEP:OwnerChanged()
            SWEP.PAPOwner = SWEP:GetOwner()
        end

        function SWEP:OnRemove()
            local owner = self.PAPOwner or self:GetOwner()
            if not IsValid(owner) then return end
            owner:GodDisable()
        end
    end

    -- Spawning 'mud samples'
    SWEP.PAPOldShowMessage = SWEP.ShowMessage
    SWEP.PAPMudColour = Color(100, 81, 43)

    SWEP.PAPMudSampleProps = {"models/props_lab/crematorcase.mdl", "models/props_lab/jar01a.mdl", "models/props_lab/jar01b.mdl", "models/props_gameplay/bottle001.mdl", "models/props_junk/garbage_glassbottle001a.mdl", "models/props_junk/garbage_glassbottle003a.mdl", "models/props_junk/Shoe001a.mdl", "models/props_c17/briefcase001a.mdl", "models/props_junk/watermelon01.mdl", "models/props_lab/cactus.mdl", "models/props_junk/glassjug01.mdl", "models/Roller.mdl", "models/Items/combine_rifle_ammo01.mdl"}

    SWEP.PAPMudSamplePropsPlusZ = {
        ["models/props_lab/jar01a.mdl"] = true,
        ["models/props_lab/jar01b.mdl"] = true,
        ["models/props_junk/watermelon01.mdl"] = true,
        ["models/props_junk/Shoe001a.mdl"] = true,
        ["models/props_c17/briefcase001a.mdl"] = true,
        ["models/props_junk/garbage_glassbottle001a.mdl"] = true,
        ["models/props_junk/models/props_gameplay/bottle001.mdl"] = true,
    }

    table.Shuffle(SWEP.PAPMudSampleProps)
    SWEP.PAPLastMudProp = 1

    function SWEP:ShowMessage()
        self:PAPOldShowMessage()
        local scannedObj = self.Target

        if IsValid(scannedObj) then
            scannedObj:SetColor(self.PAPMudColour)

            if SERVER then
                local sample = ents.Create("prop_physics")
                local model = self.PAPMudSampleProps[self.PAPLastMudProp]
                sample:SetModel(model)
                sample:SetColor(self.PAPMudColour)
                sample:SetPos(scannedObj:GetPos())
                sample:Spawn()
                SafeRemoveEntity(scannedObj)

                if scannedObj:IsPlayer() then
                    sample:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

                    if self.PAPMudSamplePropsPlusZ[model] then
                        sample.AddZ = true
                    end

                    scannedObj:SetNoDraw(true)
                    scannedObj.PAPIsMudSample = true
                    scannedObj.PAPMudSample = sample
                    scannedObj.PAPMudSampleModel = model
                end

                self.PAPLastMudProp = self.PAPLastMudProp + 1

                if self.PAPLastMudProp > #self.PAPMudSampleProps then
                    self.PAPLastMudProp = 1
                end
            end
        end
    end

    -- Turning players into 'mud samples'!
    -- Make any player with this weapon used on them a mud sample...
    self:AddHook("PlayerPostThink", function(ply)
        if not ply.PAPIsMudSample then return end
        -- Remove the sample and set the player to normal after they die
        local sample = ply.PAPMudSample

        if not IsValid(sample) or not ply:Alive() or ply:IsSpec() then
            ply:SetNoDraw(false)
            ply.PAPMudSample = nil
            ply.PAPIsMudSample = false

            if IsValid(sample) then
                sample:Remove()
            end

            return
        end

        -- Some samples are in the ground for some reason...
        local pos = ply:GetPos()

        if sample.AddZ then
            pos.z = pos.z + 10
        end

        sample:SetPos(pos)
        -- Makes the sample look the same direction as the player
        local angles = ply:GetAngles()
        angles.x = 0
        sample:SetAngles(angles)
    end)

    -- Replace the player's corpse with a sample
    self:AddHook("TTTOnCorpseCreated", function(rag)
        local ply = CORPSE.GetPlayer(rag)

        if IsValid(ply) and ply.PAPIsMudSample then
            local sample = ply.PAPMudSample
            if not IsValid(ply) or not IsValid(sample) then return end
            local model = CORPSE.GetPlayer(rag).PAPMudSampleModel
            local ragSample = ents.Create("prop_physics")
            local pos = rag:GetPos()
            local ang = rag:GetAngles()
            ragSample:SetParent(rag)
            ragSample:SetPos(pos)
            ragSample:SetAngles(ang)

            if model then
                rag:SetNoDraw(true)
                ragSample:SetModel(model)
            end

            ragSample:Spawn()
            ragSample:PhysWake()
            ragSample:SetColor(SWEP.PAPMudColour)
        end
    end)
end

-- Reset all players to not be a 'mud sample' anymore at the end of the round
function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if ply.PAPIsMudSample then
            ply:SetNoDraw(false)
            ply.PAPIsMudSample = false
            ply.PAPMudSample = nil
            ply.PAPMudSampleModel = nil
        end

        if SERVER then
            ply:GodDisable()
        end
    end
end

TTTPAP:Register(UPGRADE)