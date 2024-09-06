local UPGRADE = {}
UPGRADE.id = "portal_placer"
UPGRADE.class = "weapon_portalgun"
UPGRADE.name = "Portal Placer"
UPGRADE.desc = "Places portals mid-air!"

function UPGRADE:Apply(SWEP)
    function SWEP:CanPlacePortal()
        return true
    end

    function SWEP:FirePortal(ptype)
        local ent
        local owner = (self:GetOwner() ~= NULL) and self:GetOwner() or Entity(1)

        if SERVER then
            local tr = util.QuickTrace(owner:GetShootPos(), owner:GetForward() * 20, owner)
            local pos = tr.HitPos
            local hitAng = tr.HitNormal:Angle()
            local right = hitAng:Right() * 30
            local up = hitAng:Up() * 50

            -- Prevent portals from spawning inside each other
            for i, v in pairs(ents.FindInBox(pos + (right + up + hitAng:Forward()), pos - (right + up))) do
                if IsValid(v) and v ~= self and v ~= self.ParentEntity and v:GetClass() == "portalgun_portal" then
                    -- Another portal blocks except when it's being replaced by this new one
                    local getsReplaced = v.RealOwner == owner and v:GetNWBool("PORTALTYPE") == ptype

                    if not getsReplaced then
                        self:DispatchSparkEffect()

                        return
                    end
                end
            end

            local portalpos = pos
            local portalang
            local ownerent = tr.Entity

            if tr.HitNormal == Vector(0, 0, 1) then
                portalang = tr.HitNormal:Angle() + Angle(180, owner:GetAngles().y, 180)
            elseif tr.HitNormal == Vector(0, 0, -1) then
                portalang = tr.HitNormal:Angle() + Angle(180, owner:GetAngles().y, 180)
            else
                portalang = tr.HitNormal:Angle() - Angle(180, 0, 0)
            end

            -- Traces a line from the hit position to a relative offset
            local function TraceRelative(off)
                return util.TraceLine({
                    start = pos,
                    endpos = pos + off
                })
            end

            local tr_up = TraceRelative(up)
            local tr_down = TraceRelative(-up)
            local tr_left = TraceRelative(right)
            local tr_right = TraceRelative(-right)
            ent = ents.Create("portalgun_portal")
            ent:SetNWBool("PORTALTYPE", ptype)
            local ang = tr.HitNormal:Angle() - Angle(90, 0, 0)
            local coords = Vector(35, 35, 25)
            coords:Rotate(ang)
            up = tr.HitNormal:Angle():Up() * 50
            local lr_fract = Vector(0, 0, 0)
            local ud_fract = Vector(0, 0, 0)

            if tr_left.Hit then
                lr_fract = right * (1 - tr_left.Fraction)
            elseif tr_right.Hit then
                lr_fract = -right * (1 - tr_right.Fraction)
            end

            if tr_up.Hit then
                ud_fract = up * (1 - tr_up.Fraction)
            elseif tr_down.Hit then
                ud_fract = -up * (1 - tr_down.Fraction)
            end

            ent:SetPos(portalpos - lr_fract - ud_fract)

            for i, v in pairs(ents.FindInBox(pos + coords, pos - coords)) do
                if table.HasValue(self.BumpProps, v:GetModel()) then
                    ent:SetPos(v:GetPos())
                    ownerent = v
                    portalang = v:GetAngles() - Angle(180, 0, 0)

                    if ptype then
                        v:SetSkin(2)
                    else
                        v:SetSkin(1)
                    end
                end
            end

            ent:SetAngles(portalang + Angle(-90, 0, 0))
            ent.RealOwner = owner
            ent.ParentEntity = ownerent
            ent.AllowedEntities = self.TPEnts
            ent:Spawn()

            if tr.HitNormal == Vector(0, 0, 1) then
                ent.PlacedOnGround = true
            elseif tr.HitNormal == Vector(0, 0, -1) then
                ent.PlacedOnCeiling = true
            end

            if not ownerent:IsWorld() then
                ent:SetParent(ownerent)
            end

            ent:SetNWEntity("portalowner", owner)
            self:RemoveSelectedPortal(ptype) -- remove old portal

            if ptype then
                owner:SetNWEntity("PORTALGUN_PORTALS_RED", ent)
            else
                owner:SetNWEntity("PORTALGUN_PORTALS_BLUE", ent)
            end

            net.Start("PORTALGUN_SHOOT_PORTAL")
            net.WriteEntity(owner)
            net.WriteEntity(ent)
            net.WriteFloat((ptype == true) and 1 or 0)
            net.Send(player.GetAll())
        end

        if CLIENT then
            if ptype then
                local p1 = owner:GetNWEntity("PORTALGUN_PORTALS_RED", ent)

                if IsValid(p1) then
                    p1.RealOwner = owner
                end
            else
                local p1 = owner:GetNWEntity("PORTALGUN_PORTALS_BLUE", ent)

                if IsValid(p1) then
                    p1.RealOwner = owner
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)