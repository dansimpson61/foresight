require_relative '../spec_helper'
require_relative '../../lib/test_runner.rb'

RSpec.describe TestRunner do
  let(:project_root) { '/app' }
  let(:runner) { described_class.new(project_root) }

  describe '#run' do
    it 'runs the specified test file and returns a structured result' do
      file_path = 'spec/models/some_spec.rb'
      raw_output = ".\n\nFinished in 0.001 seconds\n1 example, 0 failures\n"
      json_output = {
        summary: { example_count: 1, failure_count: 0, summary_line: "1 example, 0 failures" },
        examples: [{ status: 'passed' }]
      }.to_json

      status = double(exitstatus: 0)

      # Mock the file read for the JSON result
      allow(File).to receive(:read).and_return(json_output)
      expect(Open3).to receive(:capture3).and_return([raw_output, '', status])

      result = runner.run(file_path)

      expect(result[:output]).to eq(raw_output)
      expect(result[:exit_status]).to eq(0)
      expect(result[:summary][:example_count]).to eq(1)
      expect(result[:summary][:failure_count]).to eq(0)
    end
  end
end
