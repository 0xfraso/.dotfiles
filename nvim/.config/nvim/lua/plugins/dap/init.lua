return
{
    "mfussenegger/nvim-dap",
    dependencies = {
        "mfussenegger/nvim-jdtls",
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
        local dap = require("dap")
        vim.fn.sign_define('DapBreakpoint',
            { text = '', texthl = 'DiagnosticSignError', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapStopped',
            { text = '', texthl = 'DiagnosticInfo', linehl = 'DapStopped', numhl = 'DapStopped' })
        vim.fn.sign_define('DapBreakpointRejected',
            { text = '', texthl = 'DiagnosticSignHint', linehl = 'DapStopped', numhl = 'DapStopped' })

        dap.adapters.chrome = {
            type = "executable",
            command = "node",
            args = {
                vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js" }
        }
        dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
                command = "node",
                args = {
                    vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
                    "${port}" },
            }
        }

        for _, language in ipairs { "javascript", "typescript" } do
            dap.configurations[language] = {
                {
                    name = "Debug (Attach) - Remote",
                    type = "chrome",
                    request = "attach",
                    sourceMaps = true,
                    trace = true,
                    port = 9222,
                    webRoot = "${workspaceFolder}"
                },
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Launch file",
                    port = "${port}",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                },
            }
        end
    end,
    keys = {
        { "[t", ":lua require('dapui').toggle()<CR>",             desc = "Dapui toggle" },
        {
            "[b",
            ":DapToggleBreakpoint<CR>",
            desc = "DapToggleBreakpoint"
        },
        {
            "[B",
            ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
            desc = "Dap conditional breakpoint"
        },
        { "[n", ":DapStepOver<CR>",                               desc = "Dap step over" },
        { "[o", ":DapStepOut<CR>",                                desc = "Dap step out" },
        { "[i", ":DapStepInto<CR>",                               desc = "Dap step into" },
        { "[c", ":DapContinue<CR>",                               desc = "Dap continue" },
        { "[x", ":DapTerminate<CR>",                              desc = "Dap terminate" },
        { "[r", ":lua require('dapui').open({reset = true})<CR>", desc = "Dapui reset" },
        { "[l", ":lua require('dapui').clear_breakpoints()<CR>",  desc = "Dapui reset" },
    }
}
