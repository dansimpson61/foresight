require 'open3'
require 'json'
require 'tempfile'

class TestRunner
  attr_reader :project_root

  def initialize(project_root)
    @project_root = project_root
  end

  def run(file_path)
    tempfile = Tempfile.new('rspec_results')
    json_path = tempfile.path

    begin
      command = "bundle exec rspec #{file_path} --format progress --format json --out #{json_path}"
      stdout, stderr, status = Open3.capture3(command, chdir: project_root)

      raw_output = stdout + stderr

      json_results = File.read(json_path)
      parsed_data = json_results.empty? ? {} : JSON.parse(json_results, symbolize_names: true)

      summary = parsed_data.fetch(:summary, {})
      examples = parsed_data.fetch(:examples, [])

      total = summary.fetch(:example_count, 0)
      failures = summary.fetch(:failure_count, 0)
      passed = total > 0 ? total - failures : 0
      pass_percentage = total > 0 ? (passed.to_f / total * 100).round : 0

      summary_with_percentage = summary.merge(pass_percentage: pass_percentage)

      {
        output: raw_output,
        exit_status: status.exitstatus,
        summary: summary_with_percentage,
        examples: examples
      }
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
end
