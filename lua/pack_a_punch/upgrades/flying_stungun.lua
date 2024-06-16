local UPGRADE = {}
UPGRADE.id = "flying_stungun"
UPGRADE.class = "stungun"
UPGRADE.name = "Flying Stungun"
UPGRADE.desc = "More ammo, infinite range, instant recharge, much more taser power!"

function UPGRADE:Apply(SWEP)
    SWEP.Range = 10000

    if SERVER then
        local owner = SWEP:GetOwner()

        if IsValid(owner) then
            owner:GiveAmmo(2, SWEP:GetPrimaryAmmoType())
        end
    end

    function STUNGUN.ElectrolutePAP(ply, pushdir)
        if ply.tazeimmune then return end
        STUNGUN.Electrolute(ply, pushdir)
        -- Now let's do our extra PAP logic here...
        -- Need to:
        -- 1. Get the player's ragdoll if valid
        local rag = ply.tazeragdoll
        -- 2. Get the ragdoll's physics object if valid
        local phys

        if IsValid(rag) then
            phys = rag:GetPhysicsObject()
        end

        if not IsValid(phys) then return end
        -- 3. Apply a push force upwards, that causes the ragdoll to fly upwards
        local timerName = "TTTPAPFlyingStungunPush" .. rag:EntIndex()

        timer.Create(timerName, 0.01, 0, function()
            if not IsValid(phys) then
                timer.Remove(timerName)

                return
            end

            phys:AddVelocity(Vector(math.random(-100, 100), math.random(-100, 100), 65))
        end)

        -- 4. Ensure all models are affected equally
        phys:SetMass(3)
    end

    -- Overriding the stungun to use the PAP version of the electrocute function
    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        if self.Charge < 100 then return end

        if not self.InfiniteAmmo then
            if self:Clip1() <= 0 then return end
            self:TakePrimaryAmmo(1)

            timer.Simple(1, function()
                if IsValid(self) then
                    self.Charge = 90
                end
            end)
        end

        self.Uncharging = true
        owner:LagCompensation(true)
        local tr = util.TraceLine(util.GetPlayerTrace(owner))
        owner:LagCompensation(false)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        owner:SetAnimation(PLAYER_ATTACK1)
        local effectdata = EffectData()
        effectdata:SetOrigin(tr.HitPos)
        effectdata:SetStart(owner:GetShootPos())
        effectdata:SetAttachment(1)
        effectdata:SetEntity(self)
        util.Effect("ToolTracer", effectdata)

        if SERVER then
            owner:EmitSound("npc/turret_floor/shoot1.wav", 100, 100)
        end

        local ent = tr.Entity
        if CLIENT then return end
        if not IsValid(ent) or not ent:IsPlayer() then return end
        if ent == owner then return end
        if owner:GetShootPos():Distance(tr.HitPos) > self.Range then return end

        if not STUNGUN.IsPlayerImmune(ent) and (STUNGUN.AllowFriendlyFire or not STUNGUN.SameTeam(owner, ent)) then
            STUNGUN.ElectrolutePAP(ent, (ent:GetPos() - owner:GetPos()):GetNormal())
        end
    end

    -- Making the stungun check for below to get players unstuck from ceilings, and increase the unstuck check search area
    local directions = {Vector(0, 0, 0), Vector(0, 0, 1), Vector(0, 0, -1), Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0)}

    for deg = 45, 315, 90 do
        local r = math.rad(deg)
        table.insert(directions, Vector(math.Round(math.cos(r)), math.Round(math.sin(r)), 0))
    end

    local magn = 60
    local iterations = 4

    function STUNGUN.PlayerSetPosNoBlock(ply, pos, filter)
        local tr
        local dirvec
        local m = magn
        local i = 1
        local its = 1
        repeat
            dirvec = directions[i] * m
            i = i + 1

            if i > #directions then
                its = its + 1
                i = 1
                m = m + magn

                if its > iterations then
                    ply:SetPos(pos)

                    return false
                end
            end

            tr = STUNGUN.PlayerHullTrace(dirvec + pos, ply, filter)
        until tr.Hit == false
        ply:SetPos(pos + dirvec)

        return true
    end
end

TTTPAP:Register(UPGRADE)