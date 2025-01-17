local OLLAMA_URL = os.getenv("OLLAMA_URL")
if not OLLAMA_URL then
  OLLAMA_URL = "localhost:11434"
end

return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = "*",
    opts = function()
      return {
        ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
        provider = "ollama",
        vendors = {
          ollama = {
            __inherited_from = "openai",
            api_key_name = "",
            endpoint = string.format("%s/api", OLLAMA_URL),
            model = "llama3.1:8b",
            parse_curl_args = function(opts, code_opts)
              vim.notify(opts.endpoint)
              return {
                url = opts.endpoint .. "/chat",
                headers = {
                  ["Accept"] = "application/json",
                  ["Content-Type"] = "application/json",
                },
                body = {
                  model = opts.model,
                  options = {
                    num_ctx = 16384,
                  },
                  messages = require("avante.providers").copilot.parse_messages(code_opts), -- you can make your own message, but this is very advanced
                  stream = true,
                },
              }
            end,
            parse_stream_data = function(data, handler_opts)
              -- Parse the JSON data
              local json_data = vim.fn.json_decode(data)
              -- Check if the response contains a message
              if json_data and json_data.message and json_data.message.content then
                -- Extract the content from the message
                local content = json_data.message.content
                -- Call the handler with the content
                handler_opts.on_chunk(content)
              end
            end,
          }
        }, ---Specify the special dual_boost mode
        ---1. enabled: Whether to enable dual_boost mode. Default to false.
        ---2. first_provider: The first provider to generate response. Default to "openai".
        ---3. second_provider: The second provider to generate response. Default to "claude".
        ---4. prompt: The prompt to generate response based on the two reference outputs.
        ---5. timeout: Timeout in milliseconds. Default to 60000.
        ---How it works:
        --- When dual_boost is enabled, avante will generate two responses from the first_provider and second_provider respectively. Then use the response from the first_provider as provider1_output and the response from the second_provider as provider2_output. Finally, avante will generate a response based on the prompt and the two reference outputs, with the default Provider as normal.
        ---Note: This is an experimental feature and may not work as expected.
        dual_boost = {
          enabled = false,
          first_provider = "openai",
          second_provider = "claude",
          prompt =
          "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
          timeout = 60000, -- Timeout in milliseconds
        },
        behaviour = {
          auto_suggestions = false, -- Experimental stage
          auto_set_highlight_group = true,
          auto_set_keymaps = true,
          auto_apply_diff_after_generation = false,
          support_paste_from_clipboard = false,
          minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
        },
        file_selector = {
          --- @alias FileSelectorProvider "native" | "fzf" | "telescope" | string
          provider = "fzf",
          -- Options override for custom providers
          provider_opts = {},
        },
        mappings = {
          --- @class AvanteConflictMappings
          diff = {
            ours = "co",
            theirs = "ct",
            all_theirs = "ca",
            both = "cb",
            cursor = "cc",
            next = "]x",
            prev = "[x",
          },
          suggestion = {
            accept = "<M-l>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
          jump = {
            next = "]]",
            prev = "[[",
          },
          submit = {
            normal = "<CR>",
            insert = "<C-s>",
          },
          sidebar = {
            apply_all = "A",
            apply_cursor = "a",
            switch_windows = "<Tab>",
            reverse_switch_windows = "<S-Tab>",
          },
        },
        hints = { enabled = false },
        windows = {
          ---@type "right" | "left" | "top" | "bottom"
          position = "right", -- the position of the sidebar
          wrap = true,        -- similar to vim.o.wrap
          width = 30,         -- default % based on available width
          sidebar_header = {
            enabled = true,   -- true, false to enable/disable the header
            align = "center", -- left, center, right for title
            rounded = true,
          },
          input = {
            prefix = "> ",
            height = 8, -- Height of the input window in vertical layout
          },
          edit = {
            border = "rounded",
            start_insert = true, -- Start insert mode when opening the edit window
          },
          ask = {
            floating = false,    -- Open the 'AvanteAsk' prompt in a floating window
            start_insert = true, -- Start insert mode when opening the ask window
            border = "rounded",
            ---@type "ours" | "theirs"
            focus_on_apply = "ours", -- which diff to focus after applying
          },
        },
        highlights = {
          ---@type AvanteConflictHighlights
          diff = {
            current = "DiffText",
            incoming = "DiffAdd",
          },
        },
        --- @class AvanteConflictUserConfig
        diff = {
          autojump = true,
          ---@type string | fun(): any
          list_opener = "copen",
          --- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
          --- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
          --- Disable by setting to -1.
          override_timeoutlen = 500,
        },
      }
    end,
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {},
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    config = function()
      vim.notify(vim.print(OLLAMA_URL), vim.log.levels.WARN)

      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "ollama",
          },
          inline = {
            adapter = "ollama"
          },
        },
        adapters = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              env = {
                url = OLLAMA_URL,
              },
              headers = {
                ["Content-Type"] = "application/json",
              },
              parameters = {
                sync = true,
              },
            })
          end,
        },
      })
    end,
    keys = {
      { "<leader>cl", ":CodeCompanionActions<cr>", desc = "CodeCompanionActions", },
      { "<leader>cp", ":CodeCompanionChat<cr>",    desc = "CodeCompanionChat", },
    }
  }
}
