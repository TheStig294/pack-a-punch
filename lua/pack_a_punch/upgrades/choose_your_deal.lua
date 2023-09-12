local UPGRADE = {}
UPGRADE.id = "choose_your_deal"
UPGRADE.class = "ttt_deal_with_the_devil"
UPGRADE.name = "Choose Your Deal"
UPGRADE.desc = "You can now choose the upgrade!"

function UPGRADE:Apply(SWEP)
    local DealUpgrades = {
        Damage = function(owner)
            BroadcastMsg(Color(255, 0, 0), owner:Nick() .. " has sold their soul to Belial, gaining immense power!")
            owner:ChatPrint("Belial has increased your damage is amplified by 50%, but your intense power makes you visible to all")

            hook.Add("EntityTakeDamage", "Belial", function(_, dmg)
                if dmg:GetAttacker() == owner then
                    dmg:ScaleDamage(1.5)
                end
            end)

            hook.Add("PlayerDeath", "Belial2", function(victim)
                if victim == owner then
                    hook.Remove("EntityTakeDamage", "Belial")
                end
            end)

            if IsValid(SWEP) then
                SWEP:Remove()
            end
        end,
        Health = function(owner)
            BroadcastMsg(Color(235, 10, 0), owner:Nick() .. " has sold their soul to Belphegor, succumbing to gluttony!")
            owner:ChatPrint("Belphegor has made you fat increased your health to 450, but as a result you are slower")
            owner:SetHealth(450)
            owner:SetMaxHealth(450)
            owner:SetWalkSpeed(150)
            owner:SetRunSpeed(150)

            hook.Add("PlayerDeath", "Belphegor", function(victim, _, _)
                if victim == owner then
                    owner:SetWalkSpeed(250)
                end
            end)

            if IsValid(SWEP) then
                SWEP:Remove()
            end
        end,
        Speed = function(owner)
            BroadcastMsg(Color(215, 20, 0), owner:Nick() .. " has sold their soul to Abaddon, creating chaos!")
            owner:ChatPrint("Abaddon has multipled your walk speed by 160% and made your model smaller, as a result you are weaker and deal 20% less damage")
            owner:SetWalkSpeed(400)
            owner:SetRunSpeed(400)
            owner:SetModelScale(0.7, 1)

            hook.Add("EntityTakeDamage", "Abaddon", function(_, dmg)
                if dmg:GetAttacker() == owner then
                    dmg:ScaleDamage(0.8)
                end
            end)

            hook.Add("PlayerDeath", "Abaddon2", function(victim)
                if victim == owner then
                    hook.Remove("EntityTakeDamage", "Abaddon")
                end
            end)

            hook.Add("PlayerDeath", "soulclaimeddead", function(victim, _, _)
                if victim == owner then
                    owner:SetWalkSpeed(250)
                    owner:SetModelScale(1, 1)
                end
            end)

            if IsValid(SWEP) then
                SWEP:Remove()
            end
        end,
        Invisibility = function(owner)
            BroadcastMsg(Color(195, 30, 0), owner:Nick() .. " has sold their soul to Bael, causing deception!")
            owner:ChatPrint("Bael has made you invisible, but your health is massively lowered, but whatever your holding is not invisible")
            owner:SetBloodColor(DONT_BLEED)
            owner:SetHealth(20)
            owner:SetMaxHealth(20)
            owner:DrawShadow(false)
            owner:Flashlight(false)
            owner:AllowFlashlight(false)
            owner:SetFOV(0, 0.2)
            owner:SetNoDraw(true)

            if IsValid(SWEP) then
                SWEP:Remove()
            end
        end,
        Credits = function(owner)
            BroadcastMsg(Color(175, 40, 0), owner:Nick() .. " has sold their soul to Mammon, and is consumed by greed")
            owner:ChatPrint("Mammon has granted you 3 credits")
            owner:AddCredits(owner:GetCredits() + 3)

            if IsValid(SWEP) then
                SWEP:Remove()
            end
        end,
        Lifesteal = function(owner)
            BroadcastMsg(Color(155, 30, 0), owner:Nick() .. " has sold their soul to Beelzebub, and will devour your life!")
            owner.beelzebub3 = true

            timer.Create("beelzebubdmg", 0.9, 0, function()
                if owner:Alive() and owner.beelzebub3 == true then
                    owner:TakeDamage(1)
                else
                    timer.Remove("beelzebubdmg")
                end
            end)

            owner:ChatPrint("Beelzebub has granted you the ability to consume others lives, at the cost of slowly losing your own life")
            owner:ChatPrint("")

            hook.Add("PlayerDeath", "beelzebub", function(_, _, attacker)
                if attacker == owner then
                    attacker:SetHealth(attacker:Health() + 65)
                end
            end)

            hook.Add("PlayerDeath", "beelzebub2", function(victim, _, attacker)
                if victim == owner then
                    hook.Remove("PlayerDeath", "beelzebub")
                    attacker.beelzebub3 = false
                end
            end)

            if IsValid(SWEP) then
                SWEP:Remove()
            end
        end
    }

    if SERVER then
        util.AddNetworkString("TTTPAPChooseYourDeal")

        net.Receive("TTTPAPChooseYourDeal", function(_, ply)
            local upg = net.ReadString()
            ply:EmitSound("laugh/evilaff.wav")
            local UpgradeFunction = DealUpgrades[upg]
            UpgradeFunction(ply)
        end)
    end

    function SWEP:PrimaryAttack()
        if self.PAPWindowOpened or SERVER or not IsFirstTimePredicted() then return end
        self.PAPWindowOpened = true
        -- Upgrade choose window
        local frame = vgui.Create("DFrame")
        frame:SetPos(10, ScrH() - 500)
        frame:SetSize(200, 17 * table.Count(DealUpgrades) + 51)
        frame:SetTitle("Choose an upgrade!")
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame:SetVisible(true)
        frame:SetDeleteOnClose(true)
        frame:MakePopup()
        SWEP.PAPFrame = frame
        -- Upgrade names
        local list = vgui.Create("DListView", frame)
        list:Dock(FILL)
        list:SetMultiSelect(false)
        list:AddColumn("Devil Deals")
        local upgradeNames = table.GetKeys(DealUpgrades)

        for _, upg in pairs(upgradeNames) do
            list:AddLine(upg)
        end

        list.OnRowSelected = function(_, _, pnl)
            net.Start("TTTPAPChooseYourDeal")
            net.WriteString(pnl:GetColumnText(1))
            net.SendToServer()
        end
    end

    if CLIENT then
        function SWEP:OnRemove()
            if IsValid(self.PAPFrame) then
                self.PAPFrame:Remove()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)