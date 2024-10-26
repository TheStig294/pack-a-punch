local UPGRADE = {}
UPGRADE.id = "horny_jailer"
UPGRADE.class = "weapon_ttt_bonk_bat"
UPGRADE.name = "Horny Jailer"
UPGRADE.desc = "Jail lasts a very long time\n or until you release them!"
UPGRADE.ammoMult = 0.5

UPGRADE.convars = {
    {
        name = "pap_horny_jailer_secs",
        type = "int"
    }
}

local secsCvar = CreateConVar("pap_horny_jailer_secs", 120, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds jail lasts", 10, 180)

function UPGRADE:Apply(SWEP)
    -- Locally override the jail wall function to apply the PaP camo
    local function JailWall(pos, angle)
        wall = ents.Create("prop_physics")
        wall:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl")
        wall:SetPos(pos)
        wall:SetAngles(angle)
        wall:Spawn()
        wall:SetPAPCamo()
        wall.PAPHornyJailerWall = true
        local physobj = wall:GetPhysicsObject()

        if physobj:IsValid() then
            physobj:EnableMotion(false)
            physobj:Sleep(false)
        end

        return wall
    end

    function SWEP:PrimaryAttack()
        local ply = self:GetOwner()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        if not IsValid(ply) then return end
        ply:SetAnimation(PLAYER_ATTACK1)
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        self:EmitSound("Bat.Swing")
        local av, spos = ply:GetAimVector(), ply:GetShootPos()
        local epos = spos + av * self.Range
        local kmins = Vector(1, 1, 1) * 7
        local kmaxs = Vector(1, 1, 1) * 7
        ply:LagCompensation(true)

        local tr = util.TraceHull({
            start = spos,
            endpos = epos,
            filter = ply,
            mask = MASK_SHOT_HULL,
            mins = kmins,
            maxs = kmaxs
        })

        -- Hull might hit environment stuff that line does not hit
        if not IsValid(tr.Entity) then
            tr = util.TraceLine({
                start = spos,
                endpos = epos,
                filter = ply,
                mask = MASK_SHOT_HULL
            })
        end

        ply:LagCompensation(false)
        local ent = tr.Entity
        if not tr.Hit or not IsValid(ent) then return end

        if ent:GetClass() == "prop_ragdoll" then
            ply:FireBullets{
                Src = spos,
                Dir = av,
                Tracer = 0,
                Damage = 0
            }
        end

        -- Jail-releasing stuff
        if ent.PAPHornyJailerWall then
            if SERVER then
                ent:EmitSound("phx/hmetal" .. math.random(3) .. ".wav")
                ent:Remove()
            end

            return
        end

        -- Jail-spawning stuff
        if self:Clip1() <= 0 or not ent:IsPlayer() then return end
        if CLIENT then return end
        net.Start("Bonk Bat Primary Hit")
        net.WriteTable(tr)
        net.WriteEntity(self)
        net.Broadcast()
        local dmg = DamageInfo()
        dmg:SetDamage(self.Primary.Damage or self.Primary.Damage * 0.5)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(av * 2000)
        dmg:SetDamagePosition(ply:GetPos())
        dmg:SetDamageType(DMG_CLUB)
        ent:DispatchTraceAttack(dmg, tr)
        self:TakePrimaryAmmo(1)
        -- grenade to stop detective getting stuck in jail
        local gren = ents.Create("jail_discombob")
        gren:SetPos(ent:GetPos())
        gren:SetOwner(ent)
        gren:SetThrower(ent)
        gren:Spawn()
        gren:SetDetonateExact(CurTime())
        local name = ent:Nick()
        local jail = {}

        -- making the jail
        timer.Create("jaildiscombob", 0.7, 1, function()
            -- far side
            jail[0] = JailWall(ent:GetPos() + Vector(0, -25, 50), Angle(0, 275, 0))
            -- close side
            jail[1] = JailWall(ent:GetPos() + Vector(0, 25, 50), Angle(0, 275, 0))
            -- left side
            jail[2] = JailWall(ent:GetPos() + Vector(-25, 0, 50), Angle(0, 180, 0))
            -- right side
            jail[3] = JailWall(ent:GetPos() + Vector(25, 0, 50), Angle(0, 180, 0))
            -- ceiling side
            jail[4] = JailWall(ent:GetPos() + Vector(0, 0, 100), Angle(90, 0, 0))
            -- floor side
            jail[5] = JailWall(ent:GetPos() + Vector(0, 0, -5), Angle(90, 0, 0))

            for _, v in pairs(player.GetAll()) do
                v:ChatPrint(name .. " has been sent to *super* horny jail!\nHit the jail with the upgraded bat to release them!")
            end
        end)

        timer.Simple(secsCvar:GetInt(), function()
            -- remove the jail
            for _, jailWall in pairs(jail) do
                if IsValid(jailWall) then
                    jailWall:Remove()
                end
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)