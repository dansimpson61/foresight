require_relative '../spec_helper'

RSpec.describe "Dashboard UI Flow", type: :feature, js: true do
  let(:mock_repo) { instance_double(GitRepository) }
  let(:mock_runner) { instance_double(TestRunner) }

  before do
    allow(GitRepository).to receive(:new).and_return(mock_repo)
    allow(TestRunner).to receive(:new).and_return(mock_runner)
    allow_any_instance_of(Sinatra::Application).to receive(:find_tests).and_return(['spec/models/example_spec.rb'])

    allow(mock_repo).to receive(:current_branch).and_return('main')
    allow(mock_repo).to receive(:parsed_status).and_return({ 'Modified' => [{ status: 'M', file: 'lib/some_file.rb' }]})
    allow(mock_repo).to receive(:changed_files).and_return(['lib/some_file.rb'])
    allow(mock_repo).to receive(:recent_log).and_return(['abc123 - Test User - feat: new feature'])
  end

  it "allows running a test and displays the results asynchronously" do
    mock_summary = {
      summary_line: "1 example, 0 failures",
      pass_percentage: 100,
      failure_count: 0
    }
    mock_examples = [
      { status: 'passed', full_description: 'it does something', run_time: 0.1 }
    ]
    allow(mock_runner).to receive(:run).with('spec/models/example_spec.rb').and_return({
      exit_status: 0,
      summary: mock_summary,
      examples: mock_examples
    })

    visit '/'

    expect(page).to have_content('Test Dashboard')
    expect(page).to have_content('Branch: main')
    expect(page).to have_content('example_spec.rb')

    find('.test-card').click_button('▶')

    within '.card-body' do
      expect(page).to have_content('1 example, 0 failures')
      expect(page).to have_content('✓ it does something')
    end
  end
end
