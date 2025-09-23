require 'open3'
require 'shellwords'

class GitRepository
  attr_reader :project_root

  def initialize(project_root)
    @project_root = project_root
  end

  def current_branch
    stdout, _, _ = Open3.capture3('git branch --show-current', chdir: project_root)
    stdout.strip
  end

  def parsed_status
    files = status.lines.map do |line|
      parts = line.strip.split(" ", 2)
      { status: parts[0], file: parts[1] }
    end
    files.group_by { |f| status_to_label(f[:status]) }
  end

  def changed_files
    status.lines.map { |line| line.strip.split(" ", 2)[1] }
  end

  def recent_log(count: 5)
private

  def status
    stdout, _, _ = Open3.capture3('git status --porcelain', chdir: project_root)
    stdout
  end

  def status_to_label(status_code)
    case status_code
    when 'M' then 'Modified'
    when 'A' then 'Added'
    when 'D' then 'Deleted'
    when 'R' then 'Renamed'
    when 'C' then 'Copied'
    when 'U' then 'Unmerged'
    when '??' then 'Untracked'
    else 'Other'
    end
  end
    stdout, _, _ = Open3.capture3("git log -n #{count} --pretty=format:'%h - %an, %ar : %s'", chdir: project_root)
    stdout.strip.split("\n")
  end

  def add(file_path)
    # Security: This assumes file_path has been validated by the caller,
    # but we escape it anyway for extra safety.
    safe_path = Shellwords.escape(file_path)
    Open3.capture3("git add #{safe_path}", chdir: project_root)
  end

  def commit(message)
    safe_message = Shellwords.escape(message)
    Open3.capture3("git commit -m #{safe_message}", chdir: project_root)
  end
end
