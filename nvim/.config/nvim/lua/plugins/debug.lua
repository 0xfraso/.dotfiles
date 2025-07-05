local js_based_languages = {
  "typescript",
  "javascript",
  "typescriptreact",
  "javascriptreact",
}

local pick_url = function()
  local co = coroutine.running()
  return coroutine.create(function()
    vim.ui.input({
      prompt = "Enter URL: ",
      default = "http://localhost:4200",
    }, function(url)
      if url == nil or url == "" then
        return
      else
        coroutine.resume(co, url)
      end
    end)
  end)
end

return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      local dapIcons = {
        Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
        Breakpoint          = " ",
        BreakpointCondition = " ",
        BreakpointRejected  = { " ", "DiagnosticError" },
        LogPoint            = ".>",
      }
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(dapIcons) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end
      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          -- Debug nodejs processes (make sure to add --inspect when you run the process)
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to Node app',
            address = 'localhost',
            port = 9229,
            cwd = '${workspaceFolder}',
            restart = true,
          },
          -- Debug web applications (client side)
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch & Debug Chrome",
            url = pick_url,
            webRoot = vim.fn.getcwd(),
            protocol = "inspector",
            sourceMaps = true,
            userDataDir = false,
          },
          -- Divider for the launch.json derived configs
          {
            name = "----- ↓ launch.json configs ↓ -----",
            type = "",
            request = "launch",
          },
        }
      end

      dap.configurations.java = {
        {
          type = 'java',
          request = 'attach',
          name = 'Debug (Attach) - Remote',
          hostName = '127.0.0.1',
          port = 10000,
          projectName = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({
                prompt = "Enter module: ",
                default = "ac-rest",
              }, function(url)
                if url == nil or url == "" then
                  return
                else
                  coroutine.resume(co, url)
                end
              end)
            end)
          end,
          mainClass = ''
        },
      }
    end,
    keys = {
      { "<leader>du", ":DapStepOut<cr>",          desc = "Dap Step Out", },
      { "<leader>dx", ":DapContinue<cr>",         desc = "Dap Continue", },
      { "<leader>do", ":DapStepOver<cr>",         desc = "Dap Step Over", },
      { "<leader>di", ":DapStepInto<cr>",         desc = "Dap Step Into", },
      { "<leader>dd", ":DapToggleBreakpoint<cr>", desc = "Dap Toggle Breakpoint", },
      {
        "<leader>da",
        function()
          if vim.fn.filereadable(".vscode/launch.json") then
            local dap_vscode = require("dap.ext.vscode")
            dap_vscode.load_launchjs(nil, {
              ["pwa-node"] = js_based_languages,
              ["chrome"] = js_based_languages,
              ["pwa-chrome"] = js_based_languages,
            })
          end
          require("dap").continue()
        end,
        desc = "Run with Args",
      },
    },
    dependencies = {
      -- Install the vscode-js-debug adapter
      {
        "microsoft/vscode-js-debug",
        -- After install, build it and rename the dist directory to out
        build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
        version = "1.*",
      },
      {
        "mxsdev/nvim-dap-vscode-js",
        config = function()
          ---@diagnostic disable-next-line: missing-fields
          require("dap-vscode-js").setup({
            -- Path of node executable. Defaults to $NODE_PATH, and then "node"
            -- node_path = "node",

            -- Path to vscode-js-debug installation.
            debugger_path = vim.fn.resolve(vim.fn.stdpath("data") .. "/lazy/vscode-js-debug"),

            -- Command to use to launch the debug server. Takes precedence over "node_path" and "debugger_path"
            -- debugger_cmd = { "js-debug-adapter" },

            -- which adapters to register in nvim-dap
            adapters = {
              "chrome",
              "pwa-node",
              "pwa-chrome",
              "pwa-msedge",
              "pwa-extensionHost",
              "node-terminal",
            },

            -- Path for file logging
            -- log_file_path = "(stdpath cache)/dap_vscode_js.log",

            -- Logging level for output to file. Set to false to disable logging.
            -- log_file_level = false,

            -- Logging level for output to console. Set to false to disable console output.
            -- log_console_level = vim.log.levels.ERROR,
          })
        end,
      },
      {
        "Joakker/lua-json5",
        build = "./install.sh",
      },
    },
  },
  {
    "igorlfs/nvim-dap-view",
    ---@module 'dap-view'
    ---@type dapview.Config
    opts = {
      winbar = {
        show = true,
        sections = {
          "repl",
          "watches",
          "scopes",
          "exceptions",
          "breakpoints",
          "threads",
          "console"
        },
        -- Must be one of the sections declared above
        default_section = "repl",
        headers = {
          breakpoints = "Breakpoints [B]",
          scopes = "Scopes [S]",
          exceptions = "Exceptions [E]",
          watches = "Watches [W]",
          threads = "Threads [T]",
          repl = "REPL [R]",
          console = "Console [C]",
        },
        controls = {
          enabled = true,
          position = "left",
          buttons = {
            "play",
            "step_into",
            "step_over",
            "step_out",
            "step_back",
            "run_last",
            "terminate",
            "disconnect",
          },
          custom_buttons = {},
          icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "",
            terminate = "",
            disconnect = "",
          },
        },
      },
      windows = {
        height = 12,
        position = "below",
        terminal = {
          start_hidden = true,
        },
      },
      help = {
        border = nil,
      },
      -- Controls how to jump when selecting a breakpoint or navigating the stack
      switchbuf = "usetab,newtab",
    },
    keys = {
      { "<leader>dp", function() require("dap-view").toggle() end,   desc = "Dap UI toggle", },
      { "<leader>dw", function() require("dap-view").add_expr() end, desc = "Dap add expr to watchlist", },
    }
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {},
    keys = {
      { "<leader>dv", ":DapVirtualTextRefresh<CR>", desc = "DapVirtualTextRefresh" }
    }
  }
}
