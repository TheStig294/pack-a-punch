TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_gue_guesser = {
    name = "Fruit Guesser",
    desc = "Guess someone's favourite fruit instead!",
    func = function(SWEP)
        SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

        function SWEP:PrimaryAttack()
            local owner = self:GetOwner()
            if not IsValid(owner) then return end

            if not self.PAPHasGuessed then
                if SERVER then
                    owner:QueueMessage(MSG_PRINTCENTER, "Guess a fruit first!", 1)
                end

                return
            else
                local trace = util.GetPlayerTrace(owner)
                local tr = util.TraceLine(trace)
                local role
                local ply = tr.Entity

                if IsPlayer(ply) then
                    role = ply:GetRole()
                end

                if not role then return end

                if SERVER then
                    owner:QueueMessage(MSG_PRINTCENTER, "Ehh... Let's just say you're right ¯\\_(ツ)_/¯")
                    owner:AddCredits(2)
                end

                owner:SetNWInt("TTTGuesserSelection", role)
                SWEP.PAPOldPrimaryAttack(self)
            end
        end

        function SWEP:SecondaryAttack()
            if self.PAPHasGuessed then return end
            self.PAPHasGuessed = true
            if SERVER or not IsFirstTimePredicted() then return end
            -- Create basic frame
            local Frame = vgui.Create("DFrame")
            local width = 500
            local height = 100
            Frame:SetPos(ScrW() / 2 - width / 2, ScrH() / 2 - height / 2)
            Frame:SetSize(width, height)
            Frame:SetTitle("Guess a player's favourite fruit!")
            Frame:SetVisible(true)
            Frame:MakePopup()
            Frame:SetDraggable(false)
            Frame:ShowCloseButton(false)
            Frame:MakePopup()
            Frame:SetBackgroundBlur(true)
            -- Create the fruit input
            local FruitEntry = vgui.Create("DTextEntry", Frame)
            local fruitWidth = 450
            local fruitHeight = 25
            FruitEntry:SetPos(width / 2 - fruitWidth / 2, height / 2 - fruitHeight / 2)
            FruitEntry:SetSize(fruitWidth, fruitHeight)
            FruitEntry:SetText("(Enter fruit name here)")

            -- Make the text field clear when you click into it.
            FruitEntry.OnGetFocus = function(panel)
                panel:SetText("")
            end

            FruitEntry.OnEnter = function(panel)
                local inputText = panel:GetValue()
                self:GetOwner():QueueMessage(MSG_PRINTCENTER, "You guessed: " .. inputText, 2)
                Frame:Close()
            end
        end
    end
}