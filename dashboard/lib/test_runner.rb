require 'open3'

class TestRunner
  attr_reader :project_root

  def initialize(project_root)
    @project_root = project_root
  end

  def run(file_path)
    # Security: This assumes file_path has been validated by the caller
    command = "bundle exec rspec #{file_path}"
    stdout, stderr, status = Open3.capture3(command, chdir: project_root)

    output = stdout + stderr
    summary = parse_output(output)

    {
      output: output,
      exit_status: status.exitstatus,
      summary: summary
    }
  end

  private

  def parse_output(output)
    summary_line = output.lines.find { |line| line.match?(/\d+ examples?, \d+ failures?/) }
    return {} unless summary_line

    match = summary_line.match(/(\d+) examples?, (\d+) failures?/)
    {
      examples: match[1].to_i,
      failures: match[2].to_i
    }
  end
end
