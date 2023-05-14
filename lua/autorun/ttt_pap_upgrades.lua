TTT_PAP_CAMO = "ttt_pack_a_punch/pap_camo"
local throwsound = Sound("Weapon_SLAM.SatchelThrow")

-- List of pre-defined pack a punch upgrades
-- If a weapon's upgrade is not defined, defaults to a 1.5x fire rate upgrade
TTT_PAP_UPGRADES = {
    weapon_ttt_binoculars = {
        name = "Eagle's Eye",
        func = function(SWEP)
            SWEP.ZoomLevels = {0, 15, 10, 5}

            SWEP.ProcessingDelay = 0.1
        end
    },
    weapon_ttt_confgrenade = {
        name = "The Bristol Pusher",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_confgrenade_proj_pap"
            end
        end
    },
    weapon_ttt_c4 = {
        name = "Mini-Nuke",
        func = function(SWEP)
            -- mostly replicating HL2DM slam throw here
            function SWEP:BombDrop()
                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end
                    if self.Planted then return end
                    local vsrc = ply:GetShootPos()
                    local vang = ply:GetAimVector()
                    local vvel = ply:GetVelocity()
                    local vthrow = vvel + vang * 200
                    local bomb = ents.Create("ttt_c4")

                    if IsValid(bomb) then
                        bomb:SetPos(vsrc + vang * 10)
                        bomb:SetOwner(ply)
                        bomb:SetThrower(ply)
                        bomb:Spawn()
                        bomb:PointAtEntity(ply)
                        bomb:SetMaterial(TTT_PAP_CAMO)
                        bomb:SetDmg(bomb:GetDmg() * 1.5)
                        bomb:SetRadius(bomb:GetRadius() * 1.5)

                        local ignore = {ply, self}

                        local spos = ply:GetShootPos()
                        local epos = spos + ply:GetAimVector() * 80

                        local tr = util.TraceLine({
                            start = spos,
                            endpos = epos,
                            filter = ignore,
                            mask = MASK_SOLID
                        })

                        timer.Simple(20, function()
                            StartFires(bomb:GetPos(), tr, 8, 10, true, ply)
                        end)

                        local ang = bomb:GetAngles()
                        ang:RotateAroundAxis(ang:Up(), 180)
                        bomb:SetAngles(ang)
                        bomb.fingerprints = self.fingerprints
                        bomb:PhysWake()
                        local phys = bomb:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:SetVelocity(vthrow)
                        end

                        self:Remove()
                        self.Planted = true
                    end

                    ply:SetAnimation(PLAYER_ATTACK1)
                end

                self:EmitSound(throwsound)
                self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
            end

            -- again replicating slam, now its attach fn
            function SWEP:BombStick()
                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end
                    if self.Planted then return end

                    local ignore = {ply, self}

                    local spos = ply:GetShootPos()
                    local epos = spos + ply:GetAimVector() * 80

                    local tr = util.TraceLine({
                        start = spos,
                        endpos = epos,
                        filter = ignore,
                        mask = MASK_SOLID
                    })

                    if tr.HitWorld then
                        local bomb = ents.Create("ttt_c4")

                        if IsValid(bomb) then
                            bomb:PointAtEntity(ply)

                            local tr_ent = util.TraceEntity({
                                start = spos,
                                endpos = epos,
                                filter = ignore,
                                mask = MASK_SOLID
                            }, bomb)

                            if tr_ent.HitWorld then
                                local ang = tr_ent.HitNormal:Angle()
                                ang:RotateAroundAxis(ang:Right(), -90)
                                ang:RotateAroundAxis(ang:Up(), 180)
                                bomb:SetPos(tr_ent.HitPos)
                                bomb:SetAngles(ang)
                                bomb:SetOwner(ply)
                                bomb:SetThrower(ply)
                                bomb:Spawn()
                                bomb:SetMaterial(TTT_PAP_CAMO)
                                bomb:SetDmg(bomb:GetDmg() * 1.5)
                                bomb:SetRadius(bomb:GetRadius() * 1.5)

                                timer.Simple(20, function()
                                    StartFires(bomb:GetPos(), tr, 8, 10, true, ply)
                                end)

                                bomb.fingerprints = self.fingerprints
                                local phys = bomb:GetPhysicsObject()

                                if IsValid(phys) then
                                    phys:EnableMotion(false)
                                end

                                bomb.IsOnWall = true
                                self:Remove()
                                self.Planted = true
                            end
                        end

                        ply:SetAnimation(PLAYER_ATTACK1)
                    end
                end
            end
        end
    },
    weapon_ttt_cse = {
        name = "Still Useless",
        func = function(SWEP)
            function SWEP:DropDevice()
                local cse = nil

                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end
                    if self.Planted then return end
                    local vsrc = ply:GetShootPos()
                    local vang = ply:GetAimVector()
                    local vvel = ply:GetVelocity()
                    local vthrow = vvel + vang * 200
                    cse = ents.Create("ttt_cse_proj")

                    if IsValid(cse) then
                        cse:SetPos(vsrc + vang * 10)
                        cse:SetOwner(ply)
                        cse:SetThrower(ply)
                        cse:Spawn()
                        cse:PhysWake()
                        cse:SetMaterial(TTT_PAP_CAMO)
                        cse.Range = 256
                        cse.MaxScenesPerPulse = 6
                        cse.SceneDuration = 20
                        cse.PulseDelay = 20
                        local phys = cse:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:SetVelocity(vthrow)
                        end

                        self:Remove()
                        self.Planted = true
                    end
                end

                self:EmitSound(throwsound)

                return cse
            end
        end
    },
    weapon_ttt_decoy = {
        name = "Does anyone use this?",
        func = function(SWEP)
            function SWEP:PlacedDecoy(decoy)
                decoy:SetMaterial(TTT_PAP_CAMO)
                self:GetOwner().decoy = decoy
                self:TakePrimaryAmmo(1)

                if not self:CanPrimaryAttack() then
                    self:Remove()
                    self.Planted = true
                end
            end
        end
    },
    weapon_ttt_defuser = {
        name = "Bomb Silencer",
        func = function(SWEP)
            local defuse = Sound("c4.disarmfinish")

            function SWEP:PrimaryAttack()
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                local spos = self:GetOwner():GetShootPos()
                local sdest = spos + (self:GetOwner():GetAimVector() * 80)

                local tr = util.TraceLine({
                    start = spos,
                    endpos = sdest,
                    filter = self:GetOwner(),
                    mask = MASK_SHOT
                })

                if IsValid(tr.Entity) and tr.Entity.Defusable then
                    local bomb = tr.Entity

                    if bomb.Defusable == true or bomb:Defusable() then
                        if SERVER and bomb.Disarm then
                            bomb:Disarm(self:GetOwner())
                            sound.Play(defuse, bomb:GetPos())
                        end

                        self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay * 2))
                    end
                end

                local c4Count = 0

                for _, ent in ipairs(ents.FindByClass("ttt_c4")) do
                    local bomb = ent

                    if bomb.Defusable == true or bomb:Defusable() then
                        if SERVER and bomb.Disarm then
                            bomb:Disarm(self:GetOwner())
                            sound.Play(defuse, bomb:GetPos())
                            c4Count = c4Count + 1
                        end

                        self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay * 2))
                    end
                end

                self:GetOwner():ChatPrint("Defused " .. c4Count .. " active bombs on the map")
            end
        end
    },
    weapon_ttt_flaregun = {
        name = "Everlasting Flame",
        firerateMult = 0.75,
        ammoMult = 0.75,
        func = function(SWEP)
            local function RunIgniteTimer(ent, timer_name)
                if IsValid(ent) and ent:IsOnFire() then
                    if ent:WaterLevel() > 0 then
                        ent:Extinguish()
                    elseif CurTime() > ent.burn_destroy then
                        ent:SetNotSolid(true)
                        ent:Remove()
                    else
                        -- keep on burning
                        return
                    end
                end

                timer.Remove(timer_name) -- stop running timer
            end

            local SendScorches = function(ent, tbl)
                net.Start("TTT_FlareScorch")
                net.WriteEntity(ent)
                net.WriteUInt(#tbl, 8)

                for _, p in ipairs(tbl) do
                    net.WriteVector(p)
                end

                net.Broadcast()
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

            local function IgniteTarget(att, path, dmginfo)
                local ent = path.Entity
                if not IsValid(ent) then return end

                if CLIENT and IsFirstTimePredicted() then
                    if ent:GetClass() == "prop_ragdoll" then
                        ScorchUnderRagdoll(ent)
                    end

                    return
                end

                if SERVER then
                    local dur = ent:IsPlayer() and 60 or 60
                    -- disallow if prep or post round
                    if ent:IsPlayer() and (not GAMEMODE:AllowPVP()) then return end
                    ent:Ignite(dur, 100)

                    ent.ignite_info = {
                        att = dmginfo:GetAttacker(),
                        infl = dmginfo:GetInflictor()
                    }

                    if ent:IsPlayer() then
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
    },
    weapon_ttt_glock = {
        name = "Mini-Glock",
        firerateMult = 1.5,
        spreadMult = 10,
        ammoMult = 2
    },
    weapon_ttt_health_station = {
        name = "Super Microwave",
        func = function(SWEP)
            function SWEP:HealthDrop()
                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end
                    if self.Planted then return end
                    local vsrc = ply:GetShootPos()
                    local vang = ply:GetAimVector()
                    local vvel = ply:GetVelocity()
                    local vthrow = vvel + vang * 200
                    local health = ents.Create("ttt_health_station")

                    if IsValid(health) then
                        health:SetPos(vsrc + vang * 10)
                        health:Spawn()
                        health:SetPlacer(ply)
                        health:PhysWake()
                        health:SetMaterial(TTT_PAP_CAMO)
                        health.MaxHeal = 50
                        health.MaxStored = 400
                        health.RechargeRate = 2
                        health.RechargeFreq = 1 -- in seconds
                        health.HealRate = 2
                        health.HealFreq = 0.1
                        health:SetStoredHealth(400)
                        local phys = health:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:SetVelocity(vthrow)
                        end

                        self:Remove()
                        self.Planted = true
                    end
                end

                self:EmitSound(throwsound)
            end
        end
    },
    weapon_ttt_knife = {
        name = "Double knife",
        func = function(SWEP)
            SWEP.KnifeCount = 0

            function SWEP:StabKill(tr, spos, sdest)
                local target = tr.Entity
                local dmg = DamageInfo()
                dmg:SetDamage(2000)
                dmg:SetAttacker(self:GetOwner())
                dmg:SetInflictor(self or self)
                dmg:SetDamageForce(self:GetOwner():GetAimVector())
                dmg:SetDamagePosition(self:GetOwner():GetPos())
                dmg:SetDamageType(DMG_SLASH)

                -- now that we use a hull trace, our hitpos is guaranteed to be
                -- terrible, so try to make something of it with a separate trace and
                -- hope our effect_fn trace has more luck
                -- first a straight up line trace to see if we aimed nicely
                local retr = util.TraceLine({
                    start = spos,
                    endpos = sdest,
                    filter = self:GetOwner(),
                    mask = MASK_SHOT_HULL
                })

                -- if that fails, just trace to worldcenter so we have SOMETHING
                if retr.Entity ~= target then
                    local center = target:LocalToWorld(target:OBBCenter())

                    retr = util.TraceLine({
                        start = spos,
                        endpos = center,
                        filter = self:GetOwner(),
                        mask = MASK_SHOT_HULL
                    })
                end

                -- create knife effect creation fn
                local bone = retr.PhysicsBone
                local pos = retr.HitPos
                local norm = tr.Normal
                local ang = Angle(-28, 0, 0) + norm:Angle()
                ang:RotateAroundAxis(ang:Right(), -90)
                pos = pos - (ang:Forward() * 7)
                local prints = self.fingerprints
                local ignore = self:GetOwner()

                target.effect_fn = function(rag)
                    -- we might find a better location
                    local rtr = util.TraceLine({
                        start = pos,
                        endpos = pos + norm * 40,
                        filter = ignore,
                        mask = MASK_SHOT_HULL
                    })

                    if IsValid(rtr.Entity) and rtr.Entity == rag then
                        bone = rtr.PhysicsBone
                        pos = rtr.HitPos
                        ang = Angle(-28, 0, 0) + rtr.Normal:Angle()
                        ang:RotateAroundAxis(ang:Right(), -90)
                        pos = pos - (ang:Forward() * 10)
                    end

                    local knife = ents.Create("prop_physics")
                    knife:SetModel("models/weapons/w_knife_t.mdl")
                    knife:SetPos(pos)
                    knife:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                    knife:SetAngles(ang)
                    knife.CanPickup = false
                    knife:Spawn()
                    local phys = knife:GetPhysicsObject()

                    if IsValid(phys) then
                        phys:EnableCollisions(false)
                    end

                    constraint.Weld(rag, knife, bone, 0, 0, true)

                    -- need to close over knife in order to keep a valid ref to it
                    rag:CallOnRemove("ttt_knife_cleanup", function()
                        SafeRemoveEntity(knife)
                    end)
                end

                -- seems the spos and sdest are purely for effects/forces?
                target:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)
                -- target appears to die right there, so we could theoretically get to
                -- the ragdoll in here...
                self.KnifeCount = self.KnifeCount + 1

                if self.KnifeCount >= 2 then
                    self:Remove()
                end
            end

            function SWEP:SecondaryAttack()
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
                self:SendWeaponAnim(ACT_VM_MISSCENTER)

                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end
                    ply:SetAnimation(PLAYER_ATTACK1)
                    local ang = ply:EyeAngles()

                    if ang.p < 90 then
                        ang.p = -10 + ang.p * ((90 + 10) / 90)
                    else
                        ang.p = 360 - ang.p
                        ang.p = -10 + ang.p * -((90 + 10) / 90)
                    end

                    local vel = math.Clamp((90 - ang.p) * 5.5, 550, 800)
                    local vfw = ang:Forward()
                    local vrt = ang:Right()
                    local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
                    src = src + (vfw * 1) + (vrt * 3)
                    local thr = vfw * vel + ply:GetVelocity()
                    local knife_ang = Angle(-28, 0, 0) + ang
                    knife_ang:RotateAroundAxis(knife_ang:Right(), -90)
                    local knife = ents.Create("ttt_knife_proj")
                    if not IsValid(knife) then return end
                    knife:SetPos(src)
                    knife:SetAngles(knife_ang)
                    knife:Spawn()
                    knife.Damage = self.Primary.Damage
                    knife:SetOwner(ply)
                    local phys = knife:GetPhysicsObject()

                    if IsValid(phys) then
                        phys:SetVelocity(thr)
                        phys:AddAngleVelocity(Vector(0, 1500, 0))
                        phys:Wake()
                    end

                    self.KnifeCount = self.KnifeCount + 1

                    if self.KnifeCount >= 2 then
                        self:Remove()
                    end
                end
            end
        end
    },
    weapon_ttt_m16 = {
        name = "Skullcrusher",
        ammoMult = 2,
        firerateMult = 1
    },
    weapon_ttt_phammer = {
        name = "The Ghost Ball",
        ammoMult = 1.5
    },
    weapon_ttt_radio = {
        name = "Quad Auto-Radio",
        func = function(SWEP)
            SWEP.RadioCount = 0

            local radioSounds = {"scream", "explosion", "footsteps", "burning", "beeps", "shotgun", "pistol", "mac10", "deagle", "m16", "rifle", "huge"}

            -- c4 plant but different
            function SWEP:RadioDrop()
                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end
                    -- if self.Planted then return end
                    local vsrc = ply:GetShootPos()
                    local vang = ply:GetAimVector()
                    local vvel = ply:GetVelocity()
                    local vthrow = vvel + vang * 200
                    local radio = ents.Create("ttt_radio")

                    if IsValid(radio) then
                        radio:SetPos(vsrc + vang * 10)
                        radio:SetOwner(ply)
                        radio:Spawn()
                        radio:PhysWake()
                        radio:SetMaterial(TTT_PAP_CAMO)
                        local timerName = radio:EntIndex() .. "TTTPAPRadio"

                        timer.Create(timerName, 20, 240, function()
                            if not IsValid(radio) then
                                timer.Remove(timerName)

                                return
                            end

                            if math.random() < 0.5 then return end
                            radio:PlaySound(radioSounds[math.random(#radioSounds)])
                        end)

                        local phys = radio:GetPhysicsObject()

                        if IsValid(phys) then
                            phys:SetVelocity(vthrow)
                        end

                        self.RadioCount = self.RadioCount + 1

                        if self.RadioCount >= 4 then
                            self:Remove()
                        end

                        self.Planted = true
                    end
                end

                self:EmitSound(throwsound)
            end

            -- hey look, more C4 code
            function SWEP:RadioStick()
                if SERVER then
                    local ply = self:GetOwner()
                    if not IsValid(ply) then return end

                    -- if self.Planted then return end
                    local ignore = {ply, self}

                    local spos = ply:GetShootPos()
                    local epos = spos + ply:GetAimVector() * 80

                    local tr = util.TraceLine({
                        start = spos,
                        endpos = epos,
                        filter = ignore,
                        mask = MASK_SOLID
                    })

                    if tr.HitWorld then
                        local radio = ents.Create("ttt_radio")

                        if IsValid(radio) then
                            radio:PointAtEntity(ply)

                            local tr_ent = util.TraceEntity({
                                start = spos,
                                endpos = epos,
                                filter = ignore,
                                mask = MASK_SOLID
                            }, radio)

                            if tr_ent.HitWorld then
                                local ang = tr_ent.HitNormal:Angle()
                                ang:RotateAroundAxis(ang:Up(), -180)
                                radio:SetPos(tr_ent.HitPos + ang:Forward() * -2.5)
                                radio:SetAngles(ang)
                                radio:SetOwner(ply)
                                radio:Spawn()
                                radio:SetMaterial(TTT_PAP_CAMO)
                                local timerName = radio:EntIndex() .. "TTTPAPRadio"

                                timer.Create(timerName, 20, 240, function()
                                    if not IsValid(radio) then
                                        timer.Remove(timerName)

                                        return
                                    end

                                    if math.random() < 0.5 then return end
                                    radio:PlaySound(radioSounds[math.random(#radioSounds)])
                                end)

                                local phys = radio:GetPhysicsObject()

                                if IsValid(phys) then
                                    phys:EnableMotion(false)
                                end

                                radio.IsOnWall = true
                                self.RadioCount = self.RadioCount + 1

                                if self.RadioCount >= 4 then
                                    self:Remove()
                                end

                                self.Planted = true
                            end
                        end
                    end
                end
            end
        end
    },
    weapon_ttt_sipistol = {
        name = "Unsilenced Pistol",
        damageMult = 1.5,
        firerateMult = 1.1
    },
    weapon_ttt_smokegrenade = {
        name = "Ninja bomb",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_smokegrenade_proj_pap"
            end
        end
    },
    weapon_ttt_stungun = {
        name = "Assault Taser",
        ammoMult = 1.5,
        func = function(SWEP)
            function SWEP:ShootBullet(dmg, recoil, numbul, cone)
                local sights = self:GetIronsights()
                numbul = numbul or 1
                cone = cone or 0.01
                -- 10% accuracy bonus when sighting
                cone = sights and (cone * 0.9) or cone
                local bullet = {}
                bullet.Num = numbul
                bullet.Src = self:GetOwner():GetShootPos()
                bullet.Dir = self:GetOwner():GetAimVector()
                bullet.Spread = Vector(cone, cone, 0)
                bullet.Tracer = 4
                bullet.Force = 5
                bullet.Damage = dmg

                bullet.Callback = function(att, tr, dmginfo)
                    if SERVER or (CLIENT and IsFirstTimePredicted()) then
                        local ent = tr.Entity

                        if (not tr.HitWorld) and IsValid(ent) then
                            local edata = EffectData()
                            edata:SetEntity(ent)
                            edata:SetMagnitude(3)
                            edata:SetScale(2)
                            util.Effect("TeslaHitBoxes", edata)

                            if SERVER and ent:IsPlayer() then
                                local eyeang = ent:EyeAngles()
                                local j = 15
                                eyeang.pitch = math.Clamp(eyeang.pitch + math.Rand(-j, j), -90, 90)
                                eyeang.yaw = math.Clamp(eyeang.yaw + math.Rand(-j, j), -90, 90)
                                ent:SetEyeAngles(eyeang)
                            end
                        end
                    end
                end

                self:GetOwner():FireBullets(bullet)
                self:SendWeaponAnim(self.PrimaryAnim)
                -- Owner can die after firebullets, giving an error at muzzleflash
                if not IsValid(self:GetOwner()) or not self:GetOwner():Alive() then return end
                self:GetOwner():MuzzleFlash()
                self:GetOwner():SetAnimation(PLAYER_ATTACK1)
                if self:GetOwner():IsNPC() then return end

                if ((game.SinglePlayer() and SERVER) or ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then
                    -- reduce recoil if ironsighting
                    recoil = sights and (recoil * 0.75) or recoil
                    local eyeang = self:GetOwner():EyeAngles()
                    eyeang.pitch = eyeang.pitch - recoil
                    self:GetOwner():SetEyeAngles(eyeang)
                end
            end
        end
    },
    weapon_ttt_teleport = {
        name = "Infini-porter",
        ammoMult = 40
    },
    weapon_ttt_unarmed = {
        name = "Perma-Holstered",
        func = function(SWEP)
            function SWEP:Think()
                local owner = self:GetOwner()
                if not IsValid(owner) then return end
                owner:SelectWeapon(self.ClassName)
                owner:SetActiveWeapon(self)
            end

            function SWEP:Holster()
                return false
            end
        end
    },
    weapon_ttt_wtester = {
        name = "Traitor Tester",
        func = function(SWEP)
            local beep_miss = Sound("player/suit_denydevice.wav")

            function SWEP:PrimaryAttack()
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                -- will be tracing against players
                self:GetOwner():LagCompensation(true)
                local spos = self:GetOwner():GetShootPos()
                local sdest = spos + (self:GetOwner():GetAimVector() * self.Range)

                local tr = util.TraceLine({
                    start = spos,
                    endpos = sdest,
                    filter = self:GetOwner(),
                    mask = MASK_SHOT
                })

                local ent = tr.Entity

                if IsValid(ent) and (not ent:IsPlayer()) then
                    if SERVER then
                        if ent:GetClass() == "prop_ragdoll" and ent.killer_sample then
                            if CORPSE.GetFound(ent, false) then
                                self:GatherRagdollSample(ent)
                            else
                                self:Report("dna_identify")
                            end
                        elseif ent.fingerprints and #ent.fingerprints > 0 then
                            self:GatherObjectSample(ent)
                        else
                            self:Report("dna_notfound")
                        end
                    end
                else
                    if ent:IsPlayer() and ent:Alive() and not ent:IsSpec() then
                        if self.DoneATraitorTest then
                            self:GetOwner():ChatPrint("You can only test 1 person")
                        else
                            self:GetOwner():ChatPrint("You will get the test result in 60 seconds")
                            ent:PrintMessage(HUD_PRINTCENTER, "You'll be traitor tested in 60 secs!")
                            ent:PrintMessage(HUD_PRINTTALK, "You'll be traitor tested in 60 secs!")
                            self.IsTraitorTest = ent:GetRole() == ROLE_TRAITOR or (ent.IsTraitorTeam and ent:IsTraitorTeam())
                            self.DoneATraitorTest = true

                            timer.Create("PAPDnaScannerTest", 1, 60, function()
                                if GetRoundState() ~= ROUND_ACTIVE then
                                    timer.Remove("PAPDnaScannerTest")

                                    return
                                end

                                if timer.RepsLeft("PAPDnaScannerTest") == 0 and IsValid(self) then
                                    local owner = self:GetOwner()

                                    if IsValid(owner) and self.IsTraitorTest then
                                        owner:ChatPrint("The player you tested is not an innocent!")
                                    elseif IsValid(owner) then
                                        owner:ChatPrint("The player you tested is innocent!")
                                    end

                                    self:GetOwner():EmitSound(beep_miss)
                                end
                            end)
                        end

                        if CLIENT then
                            self:GetOwner():EmitSound(beep_miss)
                        end
                    end

                    self:GetOwner():LagCompensation(false)
                end
            end
        end
    },
    weapon_zm_carry = {
        name = "Telekinesis Stick",
        func = function(SWEP)
            function SWEP:PrimaryAttack()
                local ply = self:GetOwner()
                if not IsValid(ply) then return end
                local trace = ply:GetEyeTrace(MASK_SHOT)
                local ent = trace.Entity

                if IsValid(ent) then
                    local phys = ent:GetPhysicsObject()
                    if not IsValid(phys) or not phys:IsMoveable() or phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then return end
                    local is_ragdoll = ent:GetClass() == "prop_ragdoll"
                    local pdir = trace.Normal
                    local is_player

                    if ent:IsPlayer() then
                        is_player = ent
                    end

                    if is_ragdoll then
                        phys = ent:GetPhysicsObjectNum(trace.PhysicsBone)
                    end

                    self:MoveObject(phys, pdir, 20000, is_ragdoll, is_player)
                end
            end

            function SWEP:SecondaryAttack()
                local ply = self:GetOwner()
                if not IsValid(ply) then return end
                local trace = ply:GetEyeTrace(MASK_SHOT)
                local ent = trace.Entity

                if IsValid(ent) then
                    local phys = ent:GetPhysicsObject()
                    if not IsValid(phys) or not phys:IsMoveable() or phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then return end
                    local is_ragdoll = ent:GetClass() == "prop_ragdoll"
                    local pdir = trace.Normal * -1
                    local is_player

                    if ent:IsPlayer() then
                        is_player = ent
                    end

                    if is_ragdoll then
                        phys = ent:GetPhysicsObjectNum(trace.PhysicsBone)
                    end

                    self:MoveObject(phys, pdir, 20000, is_ragdoll, is_player)
                end
            end

            function SWEP:MoveObject(phys, pdir, maxforce, is_ragdoll, is_player)
                if not IsValid(phys) then return end
                local speed = phys:GetVelocity():Length()
                -- remap speed from 0 -> 125 to force 1 -> 4000
                local force = maxforce + (1 - maxforce) * (speed / 125)

                if is_ragdoll then
                    force = force * 2
                end

                pdir = pdir * force
                local mass = phys:GetMass()

                -- scale more for light objects
                if mass < 50 then
                    pdir = pdir * (mass + 0.5) * (1 / 50)
                end

                if is_player then
                    is_player:SetVelocity(pdir / 200)
                else
                    phys:ApplyForceCenter(pdir)
                end
            end
        end
    },
    weapon_zm_improvised = {
        name = "The Freeman's Club",
        damageMult = 2,
        func = function(SWEP)
            local sound_single = Sound("Weapon_Crowbar.Single")

            function SWEP:SecondaryAttack()
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self:SetNextSecondaryFire(CurTime() + 0.1)

                if self:GetOwner().LagCompensation then
                    self:GetOwner():LagCompensation(true)
                end

                local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)

                if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and (self:GetOwner():EyePos() - tr.HitPos):Length() < 100 then
                    local ply = tr.Entity

                    if SERVER and (not ply:IsFrozen()) then
                        local pushvel = tr.Normal * GetConVar("ttt_crowbar_pushforce"):GetFloat() * 8
                        -- limit the upward force to prevent launching
                        pushvel.z = math.Clamp(pushvel.z, 50, 100)
                        ply:SetVelocity(ply:GetVelocity() + pushvel)
                        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

                        ply.was_pushed = {
                            att = self:GetOwner(),
                            t = CurTime(),
                            wep = self:GetClass()
                        }
                    end

                    self:EmitSound(sound_single)
                    self:SendWeaponAnim(ACT_VM_HITCENTER)
                    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
                end

                if self:GetOwner().LagCompensation then
                    self:GetOwner():LagCompensation(false)
                end
            end
        end
    },
    weapon_zm_mac10 = {
        name = "MAC100",
        firerateMult = 2,
        recoilMult = 2
    },
    weapon_zm_molotov = {
        name = "Firewall",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_firegrenade_proj_pap"
            end
        end
    },
    weapon_zm_pistol = {
        name = "4-Shot Mustang",
        damageMult = 0,
        ammoMult = 0.2,
        firerateMult = 1,
        automatic = false,
        func = function(SWEP)
            local owner = SWEP:GetOwner()

            if IsValid(owner) then
                owner:SetAmmo(0, SWEP:GetPrimaryAmmoType())
                SWEP.AmmoEnt = nil
                SWEP.Primary.Ammo = "AirboatGun"
            end

            -- Shooting functions largely copied from weapon_cs_base
            function SWEP:PrimaryAttack(worldsnd)
                self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                if not self:CanPrimaryAttack() then return end

                if not worldsnd then
                    self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
                elseif SERVER then
                    sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
                end

                self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
                -- Spawn some fire as well!
                local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)
                local pos = tr.HitPos

                if IsValid(tr.Entity) then
                    pos = tr.Entity:GetPos()
                end

                local fireNade = ents.Create("ttt_firegrenade_proj")
                fireNade:SetPos(pos)
                fireNade:Spawn()
                fireNade:SetDmg(20)
                fireNade:SetThrower(self:GetOwner())
                fireNade:Explode(tr)
                self:TakePrimaryAmmo(1)
                local owner = self:GetOwner()
                if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
                owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
            end

            function SWEP:DryFire(setnext)
                if CLIENT and LocalPlayer() == self:GetOwner() then
                    self:EmitSound("Weapon_Pistol.Empty")
                end

                setnext(self, CurTime() + 0.2)
            end
        end
    },
    weapon_zm_revolver = {
        name = "The Head Lifter",
        automatic = false,
        firerateMult = 0.5,
        recoilMult = 2,
        ammoMult = 1.5,
        damageMult = 1.5
    },
    weapon_zm_rifle = {
        name = "Arrhythmic Dirge",
        automatic = false,
        firerateMult = 1.2,
        damageMult = 1.5,
        func = function(SWEP)
            function SWEP:SetZoom(state)
                if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
                    if state then
                        self:GetOwner():SetFOV(10, 0.4)
                    else
                        self:GetOwner():SetFOV(0, 0.2)
                    end
                end
            end
        end
    },
    weapon_zm_shotgun = {
        name = "Dagon's Glare",
        firerateMult = 1.1,
        ammoMult = 1.5,
        func = function(SWEP)
            function SWEP:PerformReload()
                local ply = self:GetOwner()
                -- prevent normal shooting in between reloads
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
                if self:Clip1() >= self.Primary.ClipSize then return end
                self:GetOwner():RemoveAmmo(math.min(4, self.Primary.ClipSize - self:Clip1()), self.Primary.Ammo, false)
                self:SetClip1(math.min(self:Clip1() + 4, self.Primary.ClipSize))
                self:SendWeaponAnim(ACT_VM_RELOAD)
                self:SetReloadTimer(CurTime() + self:SequenceDuration())
            end
        end
    },
    weapon_zm_sledge = {
        name = "H.U.G.E. 9001",
        firerateMult = 1.3,
        recoilMult = 0.1
    }
}