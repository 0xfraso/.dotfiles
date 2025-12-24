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
      if os.getenv("WSL_DISTRO_NAME") then
          dap.defaults.fallback.external_terminal = {
            command = 'wezterm.exe',
            args = {'start', '--cwd', '.', '--'},
          }
      end

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
            port = 9222,
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

      local resolve_main_class = function()
        local lsp_utils = require('java-core.utils.lsp')

        local client = lsp_utils.get_jdtls()
        if not client then
          error('JDTLS client not found. Make sure JDTLS is running.')
        end

        local result = nil
        local done = false
        local error_msg = nil

        client:request('workspace/executeCommand', {
          command = 'vscode.java.resolveMainClass',
          arguments = {},
        }, function(err, result_)
            if err then
              error_msg = err.message or tostring(err)
            else
              result = result_
            end
            done = true
          end)

        -- Wait for the response
        while not done do
          vim.wait(10)  -- wait 10ms
        end

        if error_msg then
          error('Failed to resolve main class: ' .. error_msg)
        end

        return result
      end

      dap.configurations.java = {
        {
          type = 'java',
          request = 'attach',
          name = 'Debug (Attach) - Remote',
          hostName = '127.0.0.1',
          port = 5005,
          projectName = function()
            local co = coroutine.running()
            local mains = resolve_main_class()
            local items = vim.tbl_map(function(m)
              return string.format('%s', m.projectName)
            end, mains)

            return coroutine.create(function()
              vim.ui.select(items, {
                prompt = "Select project name: "
              }, function(choice, idx)
                  if choice and idx then
                    coroutine.resume(co, mains[idx].projectName)
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
  },
  {
    "igorlfs/nvim-dap-view",
    ---@module 'dap-view'
    ---@type dapview.Config
    opts = {
      winbar = {
        show = true,
        -- You can add a "console" section to merge the terminal with the other views
        sections = { "console", "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
        -- Must be one of the sections declared above
        default_section = "console",
        -- Configure each section individually
        base_sections = {
          breakpoints = {
            keymap = "B",
            label = "Breakpoints [B]",
            short_label = " [B]",
          },
          scopes = {
            keymap = "S",
            label = "Scopes [S]",
            short_label = "󰂥 [S]",
          },
          exceptions = {
            keymap = "E",
            label = "Exceptions [E]",
            short_label = "󰢃 [E]",
          },
          watches = {
            keymap = "W",
            label = "Watches [W]",
            short_label = "󰛐 [W]",
          },
          threads = {
            keymap = "T",
            label = "Threads [T]",
            short_label = "󱉯 [T]",
          },
          repl = {
            keymap = "R",
            label = "REPL [R]",
            short_label = "󰯃 [R]",
          },
          sessions = {
            keymap = "K", -- I ran out of mnemonics
            label = "Sessions [K]",
            short_label = " [K]",
          },
          console = {
            keymap = "C",
            label = "Console [C]",
            short_label = "󰆍 [C]",
          },
        },
        -- Add your own sections
        custom_sections = {},
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
        },
      },
      windows = {
        height = 0.25,
        position = "below",
        terminal = {
          width = 0.5,
          position = "left",
          -- List of debug adapters for which the terminal should be ALWAYS hidden
          hide = {},
          -- Hide the terminal when starting a new session
          start_hidden = true,
        },
      },
      icons = {
        disabled = "",
        disconnect = "",
        enabled = "",
        filter = "󰈲",
        negate = " ",
        pause = "",
        play = "",
        run_last = "",
        step_back = "",
        step_into = "",
        step_out = "",
        step_over = "",
        terminate = "",
      },
      help = {
        border = nil,
      },
      render = {
        -- Optionally a function that takes two `dap.Variable`'s as arguments
        -- and is forwarded to a `table.sort` when rendering variables in the scopes view
        sort_variables = nil,
      },
      -- Controls how to jump when selecting a breakpoint or navigating the stack
      -- Comma separated list, like the built-in 'switchbuf'. See :help 'switchbuf'
      -- Only a subset of the options is available: newtab, useopen, usetab and uselast
      -- Can also be a function that takes the current winnr and the bufnr that will jumped to
      -- If a function, should return the winnr of the destination window
      switchbuf = "usetab,uselast",
      -- Auto open when a session is started and auto close when all sessions finish
      auto_toggle = false,
      -- Reopen dapview when switching to a different tab
      -- Can also be a function to dynamically choose when to follow, by returning a boolean
      -- If a function, receives the name of the adapter for the current session as an argument
      follow_tab = false,
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
