local UPGRADE = {}
UPGRADE.id = "legendary_gatcha"
UPGRADE.class = "weapon_gmr_gacha"
UPGRADE.name = "Legendary Gatcha"
UPGRADE.desc = "Always gives legendary prizes, given to everyone!"

function UPGRADE:Apply(SWEP)
    -- Credit goes to Mal and Nick for originally creating these functions for the Gamer that have been modified
    function SWEP:PAPChooseRandomPrize(ply)
        local prizes = {}

        for _, prize in pairs(GAMER.Prizes) do
            if prize.IsUnique and ply.TTTGamerHasUniquePrize then continue end
            local plyPrizes = ply.TTTGamerPrizes or {}
            if table.HasValue(plyPrizes, prize.Id) then continue end
            if not prize:CanStart(ply) then continue end

            if prize.Rarity == GAMER.Rarities.Legendary then
                table.insert(prizes, prize)
            end
        end

        return prizes[math.random(#prizes)]
    end

    function SWEP:PAPGivePrize(ply, owner)
        if CLIENT then return end

        if ply ~= owner then
            ply:QueueMessage(MSG_PRINTCENTER, "You got a prize from the Gamer!")
        end

        local prize = self:PAPChooseRandomPrize(ply)
        net.Start("TTTGamerGachaStart")
        net.WriteString(prize.Id)
        net.Send(ply)

        timer.Create("TTTGmrGachaPrize_" .. ply:SteamID64(), GAMER.Config.Timing.Effect, 1, function()
            if not IsPlayer(ply) then return end
            prize:Start(ply)
            net.Start("TTTGachaPrizeStart")
            net.WriteString(prize.Id)
            net.Send(ply)

            if prize.IsUnique then
                ply.TTTGamerHasUniquePrize = true
            end

            local prizes = ply.TTTGamerPrizes or {}
            table.insert(prizes, prize.Id)
            ply.TTTGamerPrizes = prizes
        end)
    end

    function SWEP:PrimaryAttack()
        if self:GetNextPrimaryFire() > CurTime() then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        local ammo = self:Clip1()
        if ammo <= 0 then return end
        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end
        if owner:IsRoleAbilityDisabled() then return end
        owner:LagCompensation(true)
        self:SetClip1(ammo - 1)

        for _, ply in player.Iterator() do
            if not UPGRADE:IsAlive(ply) then continue end
            self:PAPGivePrize(ply, owner)
        end

        self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)
        owner:LagCompensation(false)

        if SERVER then
            timer.Simple(GAMER.Config.Timing.Effect, function()
                if IsValid(self) and ammo <= 1 then
                    self:Remove()
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)