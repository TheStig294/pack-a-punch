local UPGRADE = {}
UPGRADE.id = "fire_spirit"
UPGRADE.class = "custom_firestarter"
UPGRADE.name = "Fire Spirit"
UPGRADE.desc = "Fires move and chase players down!"

UPGRADE.convars = {
    {
        name = "pap_fire_spirit_duration",
        type = "int"
    }
}

local durationCvar = CreateConVar("pap_fire_spirit_duration", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds fires last", 1, 60)

local fireEnts = {}

function UPGRADE:Apply(SWEP)
    timer.Simple(0, function()
        SWEP.Primary.ClipSize = 5
        SWEP.Primary.ClipMax = 5
        SWEP.Primary.DefaultClip = 5
        SWEP:SetClip1(5)
    end)

    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:EmitSound("ambient/fire/ignite.wav")
        owner:ViewPunch(AngleRand(1, 8))
        local eyetrace = owner:GetEyeTrace()

        if SERVER then
            local fire = ents.Create("env_fire")
            fire:SetPos(eyetrace.HitPos)
            fire:SetOwner(owner)
            fire:SetKeyValue("StartDisabled", "false")
            fire:SetKeyValue("spawnflags", "4")
            fire:SetKeyValue("health", "1000")
            fire:SetKeyValue("firesize", "100")
            fire:SetKeyValue("fireattack", "10")
            fire:SetKeyValue("damagescale", "20")
            fire:SetKeyValue("ignitionpoint", "20")
            fire:Spawn()
            fire:Fire("StartFire")

            timer.Simple(durationCvar:GetInt(), function()
                if IsValid(fire) then
                    fire:Remove()
                end
            end)

            table.insert(fireEnts, fire)
        end

        self:TakePrimaryAmmo(1)
        self:SetNextPrimaryFire(CurTime() + 0.3)
    end

    function SWEP:SecondaryAttack()
        return self.BaseClass.SecondaryAttack(self)
    end

    timer.Create("TTTPAPFireSpiritMove", 0.1, 0, function()
        for _, fire in ipairs(fireEnts) do
            if not IsValid(fire) then
                fire = nil
                continue
            end

            local firePos = fire:GetPos()
            local minDistance
            local closestPly

            for _, ply in player.Iterator() do
                if not self:IsAlive(ply) or (ply.IsJesterTeam and ply:IsJesterTeam()) then continue end
                local distance = firePos:DistToSqr(ply:GetPos())

                if not minDistance or minDistance > distance then
                    minDistance = distance
                    closestPly = ply
                end
            end

            -- Move the fire towards the closest player
            if IsValid(closestPly) then
                fire:PointAtEntity(closestPly)
                firePos:Add(fire:GetForward() * 20)
                fire:SetPos(firePos)
            end
        end
    end)
end

function UPGRADE:Reset()
    table.Empty(fireEnts)
    timer.Remove("TTTPAPFireSpiritMove")
end

TTTPAP:Register(UPGRADE)