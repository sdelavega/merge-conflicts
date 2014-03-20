GitBridge = require '../lib/git-bridge'
{BufferedProcess} = require 'atom'

describe 'GitBridge', ->

  repoBase = -> atom.project.getRepo().getWorkingDirectory()

  beforeEach ->
    GitBridge._gitCommand = -> '/usr/bin/git'

  it 'checks git status for merge conflicts', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, stdout, stderr, exit}) ->
      [c, a, o] = [command, args, options]
      stdout('UU lib/file0.rb')
      stdout('UU lib/file1.rb')
      stdout('M  lib/file2.rb')
      exit(0)

    conflicts = []
    GitBridge.withConflicts (cs) -> conflicts = cs

    expect(conflicts).toEqual(['lib/file0.rb', 'lib/file1.rb'])
    expect(c).toBe('/usr/bin/git')
    expect(a).toEqual(['status', '--porcelain'])
    expect(o).toEqual({ cwd: repoBase() })

  describe 'isStaged', ->

    statusMeansStaged = (status, checkPath = 'lib/file2.txt') ->
      GitBridge.process = ({stdout, exit}) ->
        stdout("#{status} lib/file2.txt")
        exit(0)
      staged = null
      GitBridge.isStaged checkPath, (b) -> staged = b
      staged

    it 'is true if already resolved', ->
      expect(statusMeansStaged 'M ').toBe(true)

    it 'is true if resolved as ours', ->
      expect(statusMeansStaged ' M', 'lib/file1.txt').toBe(true)

    it 'is false if still in conflict', ->
      expect(statusMeansStaged 'UU').toBe(false)

    it 'is false if resolved, but then modified', ->
      expect(statusMeansStaged 'MM').toBe(false)

  it 'checks out "our" version of a file from the index', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, exit}) ->
      [c, a, o] = [command, args, options]
      exit(0)

    called = false
    GitBridge.checkoutSide 'ours', 'lib/file1.txt', -> called = true

    expect(called).toBe(true)
    expect(c).toBe('/usr/bin/git')
    expect(a).toEqual(['checkout', '--ours', 'lib/file1.txt'])
    expect(o).toEqual({ cwd: repoBase() })

  it 'stages changes to a file', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, exit}) ->
      [c, a, o] = [command, args, options]
      exit(0)

    called = false
    GitBridge.add 'lib/file1.txt', -> called = true

    expect(called).toBe(true)
    expect(c).toBe('/usr/bin/git')
    expect(a).toEqual(['add', 'lib/file1.txt'])
    expect(o).toEqual({ cwd: repoBase() })
