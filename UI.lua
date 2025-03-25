local addonName, RaidSurvey = ...
RaidSurvey.UI = {}
local UI = RaidSurvey.UI

function UI:Initialize()
    self:CreateSurveyFrame()
end

function UI:CreateSurveyFrame()
    local frame = CreateFrame("Frame", "RaidSurveyFrame", UIParent, "BackdropTemplate")
    frame:SetSize(600, 300)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(
        {
            bgFile = "Interface/ToolTips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        }
    )
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    self.surveyFrame = frame
    self.responsesLabel = ""

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Create a raid survey")

    local permissionText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    permissionText:SetPoint("TOP", title, "BOTTOM", 0, -5)
    permissionText:SetText("You need to be a Raid Leader, Assitant or a Group Leader to start a survey.")
    permissionText:SetTextColor(1, 0.8, 0)

    local questionLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    questionLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
    questionLabel:SetText("Question:")

    local questionBox = CreateFrame("EditBox", "QuestionDataBox", frame, "InputBoxTemplate")
    questionBox:SetSize(300, 20)
    questionBox:SetPoint("TOPLEFT", questionLabel, "BOTTOMLEFT", 5, -5)
    questionBox:SetAutoFocus(false)
    questionBox:SetScript(
        "OnEnterPressed",
        function(self)
            self:ClearFocus()
        end
    )
    self.questionBox = questionBox

    local optionsLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    optionsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -110)
    optionsLabel:SetText("Choices:")
    self.optionsBox = {}
    for i = 1, 2 do
        local choiceBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        choiceBox:SetSize(300, 20)
        choiceBox:SetPoint("TOPLEFT", optionsLabel, "BOTTOMLEFT", 5, -10 - ((i - 1) * 25))
        choiceBox:SetAutoFocus(false)
        choiceBox:SetScript(
            "OnEnterPressed",
            function(self)
                self:ClearFocus()
            end
        )
        table.insert(self.optionsBox, choiceBox)
    end

    local sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    sendButton:SetSize(120, 25)
    sendButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
    sendButton:SetText("Send to raid")

    sendButton:SetScript(
        "OnClick",
        function()
            -- local childs = {frame:GetChildren()}
            -- for _, child in pairs(childs) do
                
            --     if child:GetObjectType() == "EditBox" and child:GetName() ~= "QuestionDataBox" then
            --         -- self.responsesLabel = self.responsesLabel .. "|" .. child:GetName()
            --     end


            -- end
            self:OnSendSurveyClicked()
        end
    )

    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 25)
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript(
        "OnClick",
        function()
            frame:Hide()
        end
    )

    self:UpdatePermissionStatus()
end

function UI:UpdatePermissionStatus()
    if not self.surveyFrame then
        return
    end

    local permissionStatus = self.surveyFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    permissionStatus:SetPoint("BOTTOM", self.surveyFrame, "BOTTOM", 0, 50)

    if RaidSurvey.Utils:HasPermission() then
        permissionStatus:SetText("Authorized")
        permissionStatus:SetTextColor(0, 1, 0)
    else
        permissionStatus:SetText("Unauthorized")
        permissionStatus:SetTextColor(1, 0, 0)
    end

    self.permissionStatus = permissionStatus
end

function UI:OnSendSurveyClicked()
    if not RaidSurvey.Utils:HasPermission() then
        print("|cFFFF0000Error:|r Unauthorized.")
        return
    end

    local question = self.questionBox:GetText()
    if not question then
        print("|cFFFF0000Error:|r Missing question.")
    end

    local labels = ""
    for i = 1, #self.optionsBox do
        if labels == "" then
            labels = self.optionsBox[i]:GetText()
        else
            labels = labels .. "|" .. self.optionsBox[i]:GetText()
        end
    end
    -- TODO : Change magical number to a more upper one
    local numOptions = 2

    local surveyData = {
        question = question,
        numOptions = numOptions,
        labels = labels
    }
    if RaidSurvey.Communication:SendSurvey(surveyData) then
        print("|cFF00FF00Survey sended to raid members.|r")
        self.surveyFrame:Hide()
    end
end

function UI:ShowSurvey(surveyData, sender)
    local frame = CreateFrame("Frame", "RaidSurveyResponseFrame", UIParent, "BackdropTemplate")
    frame:SetSize(350, 200 + (surveyData.numOptions * 25))
    frame:SetPoint("CENTER")
    frame:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        }
    )
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Raid Survey")

    local creator = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    creator:SetPoint("TOP", title, "BOTTOM", 0, -5)
    creator:SetText("By: " .. sender)

    local questionBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    questionBg:SetSize(frame:GetWidth() - 40, 40)
    questionBg:SetPoint("TOP", creator, "BOTTOM", 0, -10)
    questionBg:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        }
    )
    questionBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local question = questionBg:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    question:SetPoint("CENTER", questionBg, "CENTER", 0, 0)
    question:SetText(surveyData.question)
    question:SetWidth(questionBg:GetWidth() - 20)
    question:SetJustifyH("CENTER")

    local buttonGroup = {}
    local firstLabel, secondLabel = strsplit("|", self.responsesLabel)
    local labels = {
        firstLabel,
        secondLabel
    }

    for i = 1, surveyData.numOptions do
        local radioButton = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
        radioButton:SetSize(20, 20)
        radioButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -120 - ((i - 1) * 25))
        radioButton:SetScript(
            "OnClick",
            function()
                for j, button in ipairs(buttonGroup) do
                    if j ~= i then
                        button:SetChecked(false)
                    end
                end
            end
        )

        local optionLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        optionLabel:SetPoint("LEFT", radioButton, "RIGHT", 5, 0)
        optionLabel:SetText(labels[i])

        table.insert(buttonGroup, radioButton)
    end

    local submitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    submitButton:SetSize(100, 25)
    submitButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
    submitButton:SetText("Répondre")
    submitButton:SetScript(
        "OnClick",
        function()
            -- Trouver l'option sélectionnée
            local selectedOption = nil
            for i, btn in ipairs(buttonGroup) do
                if btn:GetChecked() then
                    selectedOption = i
                    break
                end
            end

            if not selectedOption then
                print("|cFFFF0000Erreur:|r Veuillez sélectionner une option.")
                return
            end

            RaidSurvey.Utils:SubmitResponse(surveyData.id, selectedOption)
            print("|cFF00FF00Réponse envoyée.|r")
            frame:Hide()
        end
    )

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
    closeButton:SetText("Fermer")
    closeButton:SetScript(
        "OnClick",
        function()
            frame:Hide()
        end
    )
end

function UI:ShowResults(resultsData)
    -- Créer la frame des résultats
    local frame = CreateFrame("Frame", "RaidSurveyResultsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 250 + (#resultsData.results * 25))
    frame:SetPoint("CENTER")
    frame:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        }
    )
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- En-tête
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Résultats du sondage")

    -- Question
    local questionBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    questionBg:SetSize(frame:GetWidth() - 40, 40)
    questionBg:SetPoint("TOP", title, "BOTTOM", 0, -10)
    questionBg:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        }
    )
    questionBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local question = questionBg:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    question:SetPoint("CENTER", questionBg, "CENTER", 0, 0)
    question:SetText(resultsData.question)
    question:SetWidth(questionBg:GetWidth() - 20)
    question:SetJustifyH("CENTER")

    -- Total des votes
    local totalVotes = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    totalVotes:SetPoint("TOP", questionBg, "BOTTOM", 0, -10)
    totalVotes:SetText("Results from " .. resultsData.totalVotes .. " votes.")

    -- Afficher les résultats
    local maxVotes = 0
    for _, count in ipairs(resultsData.results) do
        maxVotes = math.max(maxVotes, count)
    end

    for i, count in ipairs(resultsData.results) do
        -- Label de l'option
        local optionLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        optionLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -120 - ((i - 1) * 30))
        -- optionLabel:SetText(resultsData.labels[i + 1])

        -- Barre de progression
        local progressBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        progressBg:SetSize(200, 16)
        progressBg:SetPoint("LEFT", optionLabel, "RIGHT", 20, 0)
        progressBg:SetBackdrop(
            {
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = {left = 2, right = 2, top = 2, bottom = 2}
            }
        )
        progressBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

        local percentage = maxVotes > 0 and (count / maxVotes) or 0
        local progressFill = CreateFrame("Frame", nil, progressBg, "BackdropTemplate")
        progressFill:SetSize(math.max(1, progressBg:GetWidth() * percentage), progressBg:GetHeight())
        progressFill:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
        progressFill:SetBackdrop(
            {
                bgFile = "Interface/Buttons/WHITE8X8",
                tile = true,
                tileSize = 16
            }
        )

        if count == maxVotes and maxVotes > 0 then
            progressFill:SetBackdropColor(0, 0.8, 0, 0.8)
        else
            progressFill:SetBackdropColor(0.4, 0.4, 0.8, 0.8)
        end

        local voteCount = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        voteCount:SetPoint("LEFT", progressBg, "RIGHT", 5, 0)
        local percent = resultsData.totalVotes > 0 and ((count / resultsData.totalVotes) * 100) or 0
        voteCount:SetText(count .. " (" .. string.format("%.1f", percent) .. "%)")
    end

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    closeButton:SetText("Close")
    closeButton:SetScript(
        "OnClick",
        function()
            frame:Hide()
        end
    )
end
