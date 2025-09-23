require 'open3'
require 'shellwords'

class GitRepository
  attr_reader :project_root

  def initialize(project_root)
    @project_root = project_root
  end

  def current_branch
    stdout, _, _ = Open3.capture3('git rev-parse --abbrev-ref HEAD', chdir: project_root)
    stdout.strip
  end

  def status
    stdout, _, _ = Open3.capture3('git status --porcelain', chdir: project_root)
    stdout.strip
  end

  def changed_files
    status.split("\n").map { |line| line.split.last }
  end

  def recent_log(count: 5)
    stdout, _, _ = Open3.capture3("git log -n #{count} --pretty=format:'%h - %an, %ar : %s'", chdir: project_root)
    stdout.strip.split("\n")
  end

  def add(file_path)
    # Security: This assumes file_path has been validated by the caller
    Open3.capture3("git add #{file_path}", chdir: project_root)
  end

  def commit(message)
    safe_message = Shellwords.escape(message)
    Open3.capture3("git commit -m #{safe_message}", chdir: project_root)
  end
end
