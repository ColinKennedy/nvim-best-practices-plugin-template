local directory = os.getenv("MINI_DOC_DIRECTORY") or "/tmp/mini.doc"
local url = "https://github.com/echasnovski/mini.doc"

vim.fn.system({ "git", "clone", url, directory })

vim.opt.rtp:append(directory)
