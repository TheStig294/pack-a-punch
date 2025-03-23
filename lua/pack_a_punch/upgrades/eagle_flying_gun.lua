local UPGRADE = {}
UPGRADE.id = "eagle_flying_gun"
UPGRADE.class = "ttt_weapon_eagleflightgun"
UPGRADE.name = "Eagle Flying Gun"

UPGRADE.convars = {
    {
        name = "pap_eagle_flying_gun_ammo",
        type = "int"
    }
}

local ammoCvar = CreateConVar("pap_eagle_flying_gun_ammo", "2", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Amount of times you can ragdoll", 1, 10)

UPGRADE.desc = "Lets you ragdoll again " .. ammoCvar:GetInt() .. " times!"

function UPGRADE:Apply(SWEP)
    SWEP.TTTPAPRagdollCount = 0

    -- Compatibility with Custom Role's equipment table (rather than vanilla TTT's equipment bitmask)
    -- (The eagleflight gun doesn't give back equipment (passive items) by default...)
    local function GiveEquipment(ply, equipment)
        if isnumber(equipment) then
            ply:GiveEquipmentItem(equipment)
        elseif istable(equipment) then
            for _, item in ipairs(equipment) do
                ply:GiveEquipmentItem(item)
            end
        end
    end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if CLIENT or GetRoundState() ~= ROUND_ACTIVE or not self:CanPrimaryAttack() or not IsValid(owner) then return end
        owner:EmitSound("ambient/creatures/town_child_scream1.wav")
        owner:SelectWeapon("weapon_ttt_unarmed")
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll.vel = owner:GetAimVector() * -50
        ragdoll:SetSolid(SOLID_VPHYSICS)
        ragdoll:PhysicsInit(SOLID_VPHYSICS)
        ragdoll:SetPos(owner:GetPos())
        local velocity = owner:GetAimVector() * 100000000
        ragdoll:SetAngles(owner:GetAngles())
        ragdoll:SetModel(owner:GetModel())
        ragdoll:Spawn()
        ragdoll:Activate()
        owner:SetParent(ragdoll)
        local j = 1

        while true do
            local phys_obj = ragdoll:GetPhysicsObjectNum(j)

            if phys_obj then
                phys_obj:SetVelocity(velocity)
                phys_obj:SetMass(10)
                j = j + 1
            else
                break
            end
        end

        owner:Spectate(OBS_MODE_CHASE)
        owner:SpectateEntity(ragdoll)
        owner.ragdoll = ragdoll
        ragdoll.hp = owner:Health()
        ragdoll.c = owner:GetCredits()
        ragdoll.Owner = owner
        ragdoll.equipment = owner:GetEquipmentItems()

        ragdoll.explode = function()
            local own = ragdoll.Owner
            local pos = ragdoll:GetPos()
            local ent = ents.Create("env_explosion")
            ent:SetPos(ragdoll:GetPos())
            ent:SetOwner(own)
            ent:SetPhysicsAttacker(ragdoll)
            ent:Spawn()
            ent:SetKeyValue("iMagnitude", "0")
            ent:Fire("Explode", 0, 0)
            util.BlastDamage(ragdoll, own, ragdoll:GetPos(), 200, 200)
            own:SetPos(pos)
            ragdoll:unragdoll()
            own:SetHealth(ragdoll.hp)
            own:SetCredits(ragdoll.c)
            GiveEquipment(own, ragdoll.equipment)
        end

        ragdoll.unragdoll = function()
            local stepback = ragdoll.vel
            local own = ragdoll.Owner
            own:SetParent()
            own.ragdoll = nil
            local pos = ragdoll:GetPos()
            own:Spawn()
            own:SetPos(pos)
            local yaw = ragdoll:GetAngles().yaw
            own:SetAngles(Angle(0, yaw, 0))

            timer.Simple(0.01, function()
                noStuck(own, stepback)
            end)

            ragdoll:Remove()
        end

        table.insert(efrn, ragdoll)

        timer.Simple(15, function()
            if IsValid(ragdoll) then
                ragdoll.explode(ragdoll)
            end
        end)

        self.TTTPAPRagdollCount = self.TTTPAPRagdollCount + 1

        if self.TTTPAPRagdollCount >= ammoCvar:GetInt() then
            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)