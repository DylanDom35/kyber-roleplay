-- kyber/gamemode/modules/ui/components/form.lua
-- Form component implementation

local KYBER = KYBER or {}

-- Form component
KYBER.UI.Form = KYBER.UI.Form or {}

-- Form styles
KYBER.UI.Form.Styles = {
    Default = {
        label = {
            text = Color(255, 255, 255),
            font = "DermaDefault"
        },
        input = {
            bg = Color(60, 60, 60),
            text = Color(255, 255, 255),
            border = Color(80, 80, 80),
            placeholder = Color(150, 150, 150)
        },
        error = {
            text = Color(255, 50, 50)
        }
    },
    Dark = {
        label = {
            text = Color(255, 255, 255),
            font = "DermaDefault"
        },
        input = {
            bg = Color(40, 40, 40),
            text = Color(255, 255, 255),
            border = Color(60, 60, 60),
            placeholder = Color(120, 120, 120)
        },
        error = {
            text = Color(255, 50, 50)
        }
    },
    Light = {
        label = {
            text = Color(0, 0, 0),
            font = "DermaDefault"
        },
        input = {
            bg = Color(240, 240, 240),
            text = Color(0, 0, 0),
            border = Color(200, 200, 200),
            placeholder = Color(150, 150, 150)
        },
        error = {
            text = Color(255, 50, 50)
        }
    }
}

-- Create a form
function KYBER.UI.Form.Create(parent, style, size)
    local form = vgui.Create("DPanel", parent)
    form:SetSize(size.w, size.h)
    
    -- Set style
    form.style = style or KYBER.UI.Form.Styles.Default
    
    -- Form data
    form.fields = {}
    form.values = {}
    form.errors = {}
    
    -- Paint function
    function form:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0))
    end
    
    -- Add field
    function form:AddField(name, label, type, options)
        local field = {
            name = name,
            label = label,
            type = type or "text",
            options = options or {},
            y = #self.fields * 60
        }
        
        -- Create label
        local label = vgui.Create("DLabel", self)
        label:SetPos(10, field.y)
        label:SetSize(self:GetWide() - 20, 20)
        label:SetText(field.label)
        label:SetTextColor(self.style.label.text)
        label:SetFont(self.style.label.font)
        
        -- Create input based on type
        local input
        if field.type == "text" then
            input = vgui.Create("DTextEntry", self)
            input:SetPos(10, field.y + 25)
            input:SetSize(self:GetWide() - 20, 30)
            input:SetTextColor(self.style.input.text)
            input:SetPlaceholderText(options.placeholder or "")
            
            function input:Paint(w, h)
                draw.RoundedBox(4, 0, 0, w, h, self:IsEditing() and Color(80, 80, 80) or self:GetParent().style.input.bg)
                draw.RoundedBox(4, 0, 0, w, h, self:GetParent().style.input.border)
                
                self:DrawTextEntryText(
                    self:GetTextColor(),
                    self:GetHighlightColor(),
                    self:GetCursorColor()
                )
            end
            
            function input:OnChange()
                self:GetParent().values[self:GetParent().fields[#self:GetParent().fields].name] = self:GetValue()
            end
        elseif field.type == "number" then
            input = vgui.Create("DNumberWang", self)
            input:SetPos(10, field.y + 25)
            input:SetSize(self:GetWide() - 20, 30)
            input:SetMinMax(options.min or 0, options.max or 100)
            input:SetValue(options.default or 0)
            
            function input:OnValueChanged(value)
                self:GetParent().values[self:GetParent().fields[#self:GetParent().fields].name] = value
            end
        elseif field.type == "select" then
            input = vgui.Create("DComboBox", self)
            input:SetPos(10, field.y + 25)
            input:SetSize(self:GetWide() - 20, 30)
            
            for _, option in ipairs(options.options or {}) do
                input:AddChoice(option.label, option.value)
            end
            
            function input:OnSelect(index, value, data)
                self:GetParent().values[self:GetParent().fields[#self:GetParent().fields].name] = data
            end
        elseif field.type == "checkbox" then
            input = vgui.Create("DCheckBox", self)
            input:SetPos(10, field.y + 25)
            input:SetSize(30, 30)
            
            function input:OnChange(value)
                self:GetParent().values[self:GetParent().fields[#self:GetParent().fields].name] = value
            end
        end
        
        -- Add error label
        local error = vgui.Create("DLabel", self)
        error:SetPos(10, field.y + 55)
        error:SetSize(self:GetWide() - 20, 20)
        error:SetText("")
        error:SetTextColor(self.style.error.text)
        error:SetFont(self.style.label.font)
        
        field.input = input
        field.error = error
        table.insert(self.fields, field)
        
        return field
    end
    
    -- Validate form
    function form:Validate()
        local valid = true
        self.errors = {}
        
        for _, field in ipairs(self.fields) do
            local value = self.values[field.name]
            local error = nil
            
            -- Required validation
            if field.options.required and (value == nil or value == "") then
                error = "This field is required"
            end
            
            -- Min length validation
            if field.options.minLength and value and #value < field.options.minLength then
                error = "Minimum length is " .. field.options.minLength
            end
            
            -- Max length validation
            if field.options.maxLength and value and #value > field.options.maxLength then
                error = "Maximum length is " .. field.options.maxLength
            end
            
            -- Pattern validation
            if field.options.pattern and value and not string.match(value, field.options.pattern) then
                error = field.options.patternError or "Invalid format"
            end
            
            -- Custom validation
            if field.options.validate then
                local customError = field.options.validate(value, self.values)
                if customError then
                    error = customError
                end
            end
            
            -- Set error
            if error then
                valid = false
                self.errors[field.name] = error
                field.error:SetText(error)
            else
                field.error:SetText("")
            end
        end
        
        return valid
    end
    
    -- Get form values
    function form:GetValues()
        return self.values
    end
    
    -- Set form values
    function form:SetValues(values)
        self.values = values or {}
        
        for _, field in ipairs(self.fields) do
            if field.input then
                if field.type == "text" then
                    field.input:SetValue(self.values[field.name] or "")
                elseif field.type == "number" then
                    field.input:SetValue(self.values[field.name] or 0)
                elseif field.type == "select" then
                    field.input:SetValue(self.values[field.name] or "")
                elseif field.type == "checkbox" then
                    field.input:SetChecked(self.values[field.name] or false)
                end
            end
        end
    end
    
    -- Reset form
    function form:Reset()
        self.values = {}
        self.errors = {}
        
        for _, field in ipairs(self.fields) do
            if field.input then
                if field.type == "text" then
                    field.input:SetValue("")
                elseif field.type == "number" then
                    field.input:SetValue(0)
                elseif field.type == "select" then
                    field.input:SetValue("")
                elseif field.type == "checkbox" then
                    field.input:SetChecked(false)
                end
            end
            field.error:SetText("")
        end
    end
    
    return form
end

-- Create a form with submit button
function KYBER.UI.Form.CreateWithSubmit(parent, style, size, onSubmit)
    local form = KYBER.UI.Form.Create(parent, style, size)
    
    -- Add submit button
    local submitButton = KYBER.UI.Button.Create(
        form,
        "Submit",
        KYBER.UI.Button.Styles.Primary,
        {w = 100, h = 30},
        function()
            if form:Validate() then
                if onSubmit then
                    onSubmit(form:GetValues())
                end
            end
        end
    )
    submitButton:SetPos(form:GetWide() - 110, form:GetTall() - 40)
    
    return form
end

-- Create a form with cancel button
function KYBER.UI.Form.CreateWithCancel(parent, style, size, onSubmit, onCancel)
    local form = KYBER.UI.Form.CreateWithSubmit(parent, style, size, onSubmit)
    
    -- Add cancel button
    local cancelButton = KYBER.UI.Button.Create(
        form,
        "Cancel",
        KYBER.UI.Button.Styles.Secondary,
        {w = 100, h = 30},
        function()
            if onCancel then
                onCancel()
            end
        end
    )
    cancelButton:SetPos(form:GetWide() - 220, form:GetTall() - 40)
    
    return form
end 