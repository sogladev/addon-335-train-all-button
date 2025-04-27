local TrainButton = {}
local button, locked
local skillsToLearn, skillsLearned
local process

local function Automate_TrainReset()
    button:SetScript("OnUpdate", nil)
    locked = nil
    skillsLearned = nil
    skillsToLearn = nil
    process = nil
    button.delay = nil
end

local function Automate_TrainAll_OnUpdate(self, elapsed)
    self.delay = self.delay - elapsed
    if self.delay <= 0 then
        Automate_TrainReset()
    end
end

local function Automate_TrainAll()
    locked = true
    button:Disable()

    local j = 0
    local cost = 0
    local money = GetMoney()

    for i = 1, GetNumTrainerServices() do
        if select(3, GetTrainerServiceInfo(i)) == "available" then
            j = j + 1
            cost = GetTrainerServiceCost(i)
            if money >= cost then
                money = money - cost
                BuyTrainerService(i)
            else
                Automate_TrainReset()
                return
            end
        end
    end

    if j > 0 then
        skillsToLearn = j
        skillsLearned = 0

        process = true
        button.delay = 1
        button:SetScript("OnUpdate", Automate_TrainAll_OnUpdate)
    else
        Automate_TrainReset()
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("TRAINER_UPDATE")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRAINER_UPDATE" then
        if not process then
            return
        end

        skillsLearned = skillsLearned + 1

        if skillsLearned >= skillsToLearn then
            Automate_TrainReset()
            Automate_TrainAll()
        else
            button.delay = 1
        end
    elseif event == "ADDON_LOADED" then
        local name = ...
        if name == "Blizzard_TrainerUI" then
            TrainButton:TrainButtonCreate()
            hooksecurefunc("ClassTrainerFrame_Update", TrainButton:TrainButtonUpdate())
        end
    end
end)

function TrainButton:TrainButtonCreate()
    if button then
        return
    end
    button = CreateFrame("Button", "TrainerButton", ClassTrainerFrame, "UIPanelButtonTemplate")
    button:SetSize(80, 18)
    button:SetFormattedText("%s %s", TRAIN, ALL)
    button:SetPoint("RIGHT", ClassTrainerFrameCloseButton, "LEFT", 1, 0)
    button:SetScript("OnClick", function()
        Automate_TrainAll()
    end)
end

function TrainButton:TrainButtonUpdate()
    if locked then
        return
    end

    for i = 1, GetNumTrainerServices() do
        if select(3, GetTrainerServiceInfo(i)) == "available" then
            button:Enable()
            return
        end
    end

    button:Disable()
end