local UPGRADE = {}
UPGRADE.id = "barrel_converter"
UPGRADE.class = "fp"
UPGRADE.name = "Barrel Converter"
UPGRADE.desc = "Converts things into explosive barrels!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Damage = 0
    if CLIENT then return end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()

        if not self:CanPrimaryAttack() then
            owner:EmitSound("Weapon_AR2.Empty")

            return
        end

        local target = owner:GetEyeTrace().Entity

        if IsValid(target) and not target.TTTPAPBarrelConverter then
            local pos = target:GetPos()
            local ang = target:GetAngles()
            -- Turn entities into a barrel
            SafeRemoveEntity(target)
            local class = "prop_physics"

            if target:IsPlayer() then
                class = "prop_dynamic"
            end

            local barrel = ents.Create(class)
            barrel:SetPos(pos)
            barrel:SetAngles(ang)
            barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
            barrel:Spawn()
            barrel:PhysWake()
            barrel.TTTPAPBarrelConverter = barrel

            -- Including players...
            if target:IsPlayer() then
                target:SetNoDraw(true)
                target.TTTPAPBarrelConverter = barrel
            end

            owner:EmitSound(TTTPAP.shootSound)

            return self.BaseClass.PrimaryAttack(self)
        end
    end

    -- Make any player with this weapon used on them a barrel...
    self:AddHook("PlayerPostThink", function(ply)
        if not ply.TTTPAPBarrelConverter then return end
        local barrel = ply.TTTPAPBarrelConverter

        -- Remove the barrel and set the player to normal after they die, or the barrel is removed for whatever reason
        if not IsValid(barrel) or not ply:Alive() or ply:IsSpec() then
            ply:SetNoDraw(false)
            ply.TTTPAPBarrelConverter = nil

            if IsValid(barrel) then
                barrel:Remove()
            end

            return
        end

        -- Some barrels are in the ground for some reason...
        local pos = ply:GetPos()

        if barrel.AddZ then
            pos.z = pos.z + 25
        end

        barrel:SetPos(pos)
        -- Makes the barrel look the same direction as the player
        local angles = ply:GetAngles()
        angles.x = 0
        barrel:SetAngles(angles)
    end)

    local function ExplodePlayer(ply, pos)
        pos = pos or ply:GetPos()
        local explode = ents.Create("env_explosion")
        explode:SetPos(pos)
        explode:SetOwner(ply)
        explode:SetKeyValue("iMagnitude", 200)
        explode:SetKeyValue("iRadiusOverride", 200)
        explode:Spawn()
        explode:Fire("Explode", 0, 0)
    end

    -- If a barrel-player takes damage they explode
    self:AddHook("PlayerHurt", function(ply)
        if ply.TTTPAPBarrelConverter then
            ExplodePlayer(ply)
        end
    end)

    -- Replace the player's corpse with an explosion
    self:AddHook("TTTOnCorpseCreated", function(rag)
        local ply = CORPSE.GetPlayer(rag)

        if IsValid(ply) and ply.TTTPAPBarrelConverter then
            ExplodePlayer(ply, rag:GetPos())
            rag:Remove()
        end
    end)
end

-- Reset all players to not be a barrel any more at the end of the round
function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        if ply.TTTPAPBarrelConverter then
            ply:SetNoDraw(false)
            ply.TTTPAPBarrelConverter = nil
        end
    end
end

TTTPAP:Register(UPGRADE)