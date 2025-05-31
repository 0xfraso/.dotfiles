local OLLAMA_URL = os.getenv("OLLAMA_URL")
if not OLLAMA_URL then
  OLLAMA_URL = "localhost:11434"
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "ravitemer/codecompanion-history.nvim"
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "anthropic",
          },
          inline = {
            adapter = "anthropic"
          },
        },
        adapters = {
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              schema = {
                model = {
                  default = "claude-3-7-sonnet-20250219",
                },
              },
              env = {
                api_key = "ANTHROPIC_API_KEY",
              },
            })
          end,
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
        extensions = {
          history = {
            enabled = true,
            opts = {
              -- Keymap to open history from chat buffer (default: gh)
              keymap = "gh",
              -- Automatically generate titles for new chats
              auto_generate_title = true,
              ---On exiting and entering neovim, loads the last chat on opening chat
              continue_last_chat = false,
              ---When chat is cleared with `gx` delete the chat from history
              delete_on_clearing_chat = false,
              -- Picker interface ("telescope" or "default")
              picker = "default",
              ---Enable detailed logging for history extension
              enable_logging = false,
              ---Directory path to save the chats
              dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            }
          }
        }
      })
    end,
    keys = {
      { "<leader>cl", ":CodeCompanionActions<cr>", desc = "CodeCompanionActions", },
      { "<leader>cp", ":CodeCompanionChat<cr>",    desc = "CodeCompanionChat", },
    }
  }
}
