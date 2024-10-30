local function execute_commands(commands_str)
  for _, command in ipairs(vim.fn.split(commands_str, "\n")) do
    vim.fn.system(command)
  end
end

local function sleep(delay)
  -- Wrap the delay in a coroutine
  local co = coroutine.running()
  assert(co, "sleep must be called within a coroutine")

  vim.defer_fn(function()
    coroutine.resume(co) -- Resume the coroutine after delay
  end, delay)

  coroutine.yield() -- Pause coroutine here
end

local function setup()
  execute_commands([[
  mkdir TESTING_DIRECTORY
  cd TESTING_DIRECTORY
  ]])
  vim.cmd("cd TESTING_DIRECTORY")
  vim.cmd("messages clear")

  -- Open cmdline
  vim.api.nvim_feedkeys(":", "n", false)

  sleep(15)
end

local function cleanup()
  sleep(1000)
  vim.cmd("cd ..")
  execute_commands([[
  cd ..
  rm -rf TESTING_DIRECTORY
  ]])
  -- vim.fn.setcmdline("messages")
end

local function run_tests(tests)
  for _, test in ipairs(tests) do
    print("Test: " .. test[1])
    test[2]()
    sleep(15)
  end
end

local function cmdline_should_is(str)
  sleep(15)
  local cmdline = vim.fn.getcmdline()
  return cmdline == str
end

local function test_completion(command, expected_completion)
  vim.fn.setcmdline(command)
  if cmdline_should_is(command .. expected_completion) then
    print("Passed")
  else
    print("Failed")
  end
end

local co = coroutine.create(function()
  setup()

  local function test_file_display()
    for i = 1, 13 do
      execute_commands("touch f" .. i)
    end
    test_completion("e ", "[f]{f1 | f10 | f11 | f12 | f13 | f2 | f3 | f4 | f5 | f6 | f7 | f8 | ...}")
    execute_commands("rm *")
  end

  local function test_dotfiles()
    execute_commands("touch .test")
    test_completion("e ", " [No match]")
    test_completion("e .", "{./ | ../ | .test}")
    execute_commands("rm *")
  end

  local function test_substring_matching()
    execute_commands("touch some-1234 something-1234 something-4321")
    test_completion("e ", "[some]{some-1234 | something-1234 | something-4321}")
    test_completion("e some", "{some-1234 | something-1234 | something-4321}")
    test_completion("e somet", "[hing-]{something-1234 | something-4321}")
    test_completion("e something-1", "{something-1234 | something-4321}")
    test_completion("e something-12", "[something-1234] [Matched]")
    test_completion("e something-127", " [No match]")
    execute_commands("rm *")
  end

  local function test_file_paths()
    execute_commands("mkdir -p sub/some other")
    test_completion("e ", "{other/ | sub/}")
    test_completion("e s", "[sub/] [Matched]")
    test_completion("e sub/", "[some/] [Matched]")
    test_completion("e sub/../sub/", "[some/] [Matched]")
    execute_commands("rm -rf *")
  end

  local tests = {
    { "File display",       test_file_display },
    { "Test dotfiles",      test_dotfiles },
    { "Substring matching", test_substring_matching },
    { "Test file paths",    test_file_paths }
  }

  run_tests(tests)

  cleanup()
end)
coroutine.resume(co)
