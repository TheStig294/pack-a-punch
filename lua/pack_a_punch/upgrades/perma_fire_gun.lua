local UPGRADE = {}
UPGRADE.id = "perma_fire_gun"
UPGRADE.class = "weapon_ttt_flaregun"
UPGRADE.name = "Perma-Fire Gun"
UPGRADE.desc = "Sets someone on fire that doesn't go out\n(Unless they go into water)"
UPGRADE.ammoMult = 0.5

function UPGRADE:Apply(SWEP)
    local function RunIgniteTimer(ent, timer_name)
        if IsValid(ent) and ent:IsOnFire() then
            if ent:WaterLevel() > 0 then
                ent:Extinguish()
            elseif CurTime() > ent.burn_destroy then
                ent:SetNotSolid(true)
                ent:Remove()
            else
                return
            end
            -- keep on burning
        end

        timer.Remove(timer_name) -- stop running timer
    end

    local SendScorches

    if CLIENT then
        local function ReceiveScorches()
            local ent = net.ReadEntity()
            local num = net.ReadUInt(8)

            for i = 1, num do
                util.PaintDown(net.ReadVector(), "FadingScorch", ent)
            end

            if IsValid(ent) then
                util.PaintDown(ent:LocalToWorld(ent:OBBCenter()), "Scorch", ent)
            end
        end

        net.Receive("TTT_FlareScorch", ReceiveScorches)
    else
        -- it's sad that decals are so unreliable when drawn serverside, failing to
        -- draw more often than they work, that I have to do this
        SendScorches = function(ent, tbl)
            net.Start("TTT_FlareScorch")
            net.WriteEntity(ent)
            net.WriteUInt(#tbl, 8)

            for _, p in ipairs(tbl) do
                net.WriteVector(p)
            end

            net.Broadcast()
        end
    end

    local function ScorchUnderRagdoll(ent)
        if SERVER then
            local postbl = {}

            -- small scorches under limbs
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                local subphys = ent:GetPhysicsObjectNum(i)

                if IsValid(subphys) then
                    local pos = subphys:GetPos()
                    util.PaintDown(pos, "FadingScorch", ent)
                    table.insert(postbl, pos)
                end
            end

            SendScorches(ent, postbl)
        end

        -- big scorch at center
        local mid = ent:LocalToWorld(ent:OBBCenter())
        mid.z = mid.z + 25
        util.PaintDown(mid, "Scorch", ent)
    end

    local function IgniteTarget(_, path, dmginfo)
        local ent = path.Entity
        if not IsValid(ent) then return end

        if CLIENT and IsFirstTimePredicted() then
            if ent:GetClass() == "prop_ragdoll" then
                ScorchUnderRagdoll(ent)
            end

            return
        end

        if SERVER then
            local dur = ent:IsPlayer() and 1000 or 1000
            -- disallow if prep or post round
            if ent:IsPlayer() and not GAMEMODE:AllowPVP() then return end
            ent:Ignite(dur, 100)

            ent.ignite_info = {
                att = dmginfo:GetAttacker(),
                infl = dmginfo:GetInflictor()
            }

            if ent:IsPlayer() then
                ent:ChatPrint("Hope there's some water, else you're not putting this fire out!")

                timer.Simple(dur + 0.1, function()
                    if IsValid(ent) then
                        ent.ignite_info = nil
                    end
                end)
            elseif ent:GetClass() == "prop_ragdoll" then
                ScorchUnderRagdoll(ent)
                local burn_time = 6
                local tname = Format("ragburn_%d_%d", ent:EntIndex(), math.ceil(CurTime()))
                ent.burn_destroy = CurTime() + burn_time

                timer.Create(tname, 0.1, math.ceil(1 + burn_time / 0.1), function()
                    -- upper limit, failsafe
                    RunIgniteTimer(ent, tname)
                end)
            end
        end
    end

    function SWEP:ShootFlare()
        local cone = self.Primary.Cone
        local bullet = {}
        bullet.Num = 1
        bullet.Src = self:GetOwner():GetShootPos()
        bullet.Dir = self:GetOwner():GetAimVector()
        bullet.Spread = Vector(cone, cone, 0)
        bullet.Tracer = 1
        bullet.Force = 2
        bullet.Damage = self.Primary.Damage
        bullet.TracerName = self.Tracer
        bullet.Callback = IgniteTarget
        self:GetOwner():FireBullets(bullet)
    end
end

TTTPAP:Register(UPGRADE)