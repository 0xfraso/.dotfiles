local M = {}

function M.setup()
    local groups = {
        NormalFloat = { bg = "none" },
        TelescopeBorder = { link = "LineNr" },
        FloatBorder = { link = "TelescopeBorder" },
        SagaBorder = { link = "FloatBorder" },
        SagaNormal = { link = "Normal" },
    }

    for group, settings in pairs(groups) do
        vim.api.nvim_set_hl(0, group, settings)
    end
end

return M
