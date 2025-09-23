require_relative '../../spec_helper'
require_relative '../../../lib/test_runner'

RSpec.describe TestRunner do
  let(:project_root) { '/app' }
  let(:runner) { described_class.new(project_root) }

  describe '#run' do
    it 'runs the specified test file and captures the output' do
      file_path = 'spec/models/some_spec.rb'
      rspec_output = ".\n\nFinished in 0.001 seconds\n1 example, 0 failures\n"
      status = double(exitstatus: 0)

      expect(Open3).to receive(:capture3).with("bundle exec rspec #{file_path}", chdir: project_root).and_return([rspec_output, '', status])

      result = runner.run(file_path)

      expect(result[:output]).to eq(rspec_output)
      expect(result[:exit_status]).to eq(0)
    end

    context 'when the test run is successful' do
      it 'parses the summary' do
        rspec_output = ".\n\nFinished in 0.001 seconds\n1 example, 0 failures\n"
        status = double(exitstatus: 0)
        allow(Open3).to receive(:capture3).and_return([rspec_output, '', status])

        result = runner.run('spec/models/some_spec.rb')

        expect(result[:summary]).to eq({ examples: 1, failures: 0 })
      end
    end

    context 'when the test run has failures' do
      it 'parses the summary' do
        rspec_output = "F\n\nFailures:\n...\nFinished in 0.1 seconds\n2 examples, 1 failure\n"
        status = double(exitstatus: 1)
        allow(Open3).to receive(:capture3).and_return([rspec_output, '', status])

        result = runner.run('spec/models/another_spec.rb')

        expect(result[:summary]).to eq({ examples: 2, failures: 1 })
      end
    end

    context 'when the summary line is not found' do
      it 'returns an empty summary hash' do
        rspec_output = "Some unexpected output"
        status = double(exitstatus: 1)
        allow(Open3).to receive(:capture3).and_return([rspec_output, '', status])

        result = runner.run('spec/models/another_spec.rb')

        expect(result[:summary]).to eq({})
      end
    end
  end
end
