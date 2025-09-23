require 'open3'
require 'json'
require 'tempfile'

class TestRunner
  attr_reader :project_root

  def initialize(project_root)
    @project_root = project_root
  end

  def run(file_path)
    # Security: This assumes file_path has been validated by the caller

    # Use a temporary file for the JSON output
    tempfile = Tempfile.new('rspec_results')
    json_path = tempfile.path

    begin
      command = "bundle exec rspec #{file_path} --format progress --format json --out #{json_path}"
      stdout, stderr, status = Open3.capture3(command, chdir: project_root)

      raw_output = stdout + stderr
      json_results = File.read(json_path)
      parsed_summary = JSON.parse(json_results, symbolize_names: true)

      {
        output: raw_output,
        exit_status: status.exitstatus,
        summary: parsed_summary[:summary],
        examples: parsed_summary[:examples]
      }
    ensure
      # Clean up the temporary file
      tempfile.close
      tempfile.unlink
    end
  end
end
