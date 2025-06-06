-- kyber/gamemode/modules/ui/templates/chat.lua
-- Chat UI template

local KYBER = KYBER or {}

-- Chat UI
KYBER.UI.Chat = KYBER.UI.Chat or {}

-- Create chat UI
function KYBER.UI.Chat.Create(parent)
    local panel = KYBER.UI.Panel.CreateModal(parent, "Chat", KYBER.UI.Panel.Styles.Default, {w = 800, h = 600})
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", panel.content)
    tabs:SetSize(panel.content:GetWide(), panel.content:GetTall())
    tabs:SetPos(0, 0)
    
    -- Local tab
    local localTab = vgui.Create("DPanel")
    tabs:AddSheet("Local", localTab)
    
    -- Create chat box
    local chatBox = vgui.Create("DTextEntry", localTab)
    chatBox:SetPos(10, 10)
    chatBox:SetSize(780, 30)
    chatBox:SetPlaceholderText("Type a message...")
    chatBox:SetMultiline(false)
    chatBox:SetEnterAllowed(true)
    chatBox.OnEnter = function()
        KYBER.UI.Chat.SendMessage(chatBox:GetValue(), "local")
        chatBox:SetValue("")
    end
    
    -- Create chat log
    local chatLog = vgui.Create("DTextEntry", localTab)
    chatLog:SetPos(10, 50)
    chatLog:SetSize(780, 500)
    chatLog:SetMultiline(true)
    chatLog:SetEditable(false)
    chatLog:SetVerticalScrollbarEnabled(true)
    
    -- Load local chat
    KYBER.SQL.Query(
        "SELECT * FROM chat WHERE character_id = ? AND type = 'local' ORDER BY created_at DESC LIMIT 100",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add messages
            for _, row in ipairs(rows) do
                chatLog:SetValue(chatLog:GetValue() .. row.message .. "\n")
            end
        end
    )
    
    -- Global tab
    local globalTab = vgui.Create("DPanel")
    tabs:AddSheet("Global", globalTab)
    
    -- Create chat box
    local chatBox = vgui.Create("DTextEntry", globalTab)
    chatBox:SetPos(10, 10)
    chatBox:SetSize(780, 30)
    chatBox:SetPlaceholderText("Type a message...")
    chatBox:SetMultiline(false)
    chatBox:SetEnterAllowed(true)
    chatBox.OnEnter = function()
        KYBER.UI.Chat.SendMessage(chatBox:GetValue(), "global")
        chatBox:SetValue("")
    end
    
    -- Create chat log
    local chatLog = vgui.Create("DTextEntry", globalTab)
    chatLog:SetPos(10, 50)
    chatLog:SetSize(780, 500)
    chatLog:SetMultiline(true)
    chatLog:SetEditable(false)
    chatLog:SetVerticalScrollbarEnabled(true)
    
    -- Load global chat
    KYBER.SQL.Query(
        "SELECT * FROM chat WHERE type = 'global' ORDER BY created_at DESC LIMIT 100",
        {},
        function(rows)
            if not rows then return end
            
            -- Add messages
            for _, row in ipairs(rows) do
                chatLog:SetValue(chatLog:GetValue() .. row.message .. "\n")
            end
        end
    )
    
    -- Private tab
    local privateTab = vgui.Create("DPanel")
    tabs:AddSheet("Private", privateTab)
    
    -- Create chat box
    local chatBox = vgui.Create("DTextEntry", privateTab)
    chatBox:SetPos(10, 10)
    chatBox:SetSize(780, 30)
    chatBox:SetPlaceholderText("Type a message...")
    chatBox:SetMultiline(false)
    chatBox:SetEnterAllowed(true)
    chatBox.OnEnter = function()
        KYBER.UI.Chat.SendMessage(chatBox:GetValue(), "private")
        chatBox:SetValue("")
    end
    
    -- Create chat log
    local chatLog = vgui.Create("DTextEntry", privateTab)
    chatLog:SetPos(10, 50)
    chatLog:SetSize(780, 500)
    chatLog:SetMultiline(true)
    chatLog:SetEditable(false)
    chatLog:SetVerticalScrollbarEnabled(true)
    
    -- Load private chat
    KYBER.SQL.Query(
        "SELECT * FROM chat WHERE character_id = ? AND type = 'private' ORDER BY created_at DESC LIMIT 100",
        {KYBER.Character.selected.id},
        function(rows)
            if not rows then return end
            
            -- Add messages
            for _, row in ipairs(rows) do
                chatLog:SetValue(chatLog:GetValue() .. row.message .. "\n")
            end
        end
    )
    
    return panel
end

-- Send message
function KYBER.UI.Chat.SendMessage(message, type)
    if not message or message == "" then
        KYBER.UI.Notification.Create("Please enter a message.", KYBER.UI.Notification.Styles.Error)
        return
    end
    
    -- Send message
    KYBER.SQL.Query(
        "INSERT INTO chat (character_id, type, message) VALUES (?, ?, ?)",
        {KYBER.Character.selected.id, type, message},
        function()
            -- Show success message
            KYBER.UI.Notification.Create("Message sent successfully.", KYBER.UI.Notification.Styles.Success)
            
            -- Refresh chat
            KYBER.UI.Chat.Create(nil)
        end
    )
end 