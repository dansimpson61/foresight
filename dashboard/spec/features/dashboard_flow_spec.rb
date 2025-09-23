require_relative '../spec_helper'

RSpec.describe "Dashboard UI Flow", type: :feature, js: true do
  let(:mock_repo) { instance_double(GitRepository) }
  let(:mock_runner) { instance_double(TestRunner) }

  before do
    # Stub the classes directly for more robust feature spec mocking
    allow(GitRepository).to receive(:new).and_return(mock_repo)
    allow(TestRunner).to receive(:new).and_return(mock_runner)
    allow_any_instance_of(Sinatra::Application).to receive(:find_tests).and_return(['spec/models/example_spec.rb'])

    # Stub the git repository methods
    allow(mock_repo).to receive(:current_branch).and_return('main')
    allow(mock_repo).to receive(:status).and_return(' M lib/some_file.rb')
    allow(mock_repo).to receive(:changed_files).and_return(['lib/some_file.rb'])
    allow(mock_repo).to receive(:recent_log).and_return(['abc123 - Test User - feat: new feature'])
  end

  it "allows running a test and displays the results asynchronously" do
    # Stub the test runner `run` method
    test_output = "1 example, 0 failures"
    test_summary = { examples: 1, failures: 0 }
    allow(mock_runner).to receive(:run).with('spec/models/example_spec.rb').and_return({
      output: test_output,
      exit_status: 0,
      summary: test_summary
    })

    visit '/'

    # Check for initial page content
    expect(page).to have_content('Test Dashboard')
    expect(page).to have_content('Branch: main')
    expect(page).to have_content('example_spec.rb')

    # Click the "Run Test" button
    click_button 'Run Test'

    # Wait for the async request to finish and check for the result
    within '#test-results' do
      expect(page).to have_content('Status: Pass')
      expect(page).to have_content('Examples: 1')
      expect(page).to have_content('Failures: 0')
      expect(page).to have_content(test_output)
    end
  end
end
