require 'sinatra'
require 'slim'
require 'open3'
require 'shellwords'
require_relative 'lib/git_repository'
require_relative 'lib/test_runner'

helpers do
  def find_tests
    # Search for spec files in the parent directory's spec folder
    Dir.glob(File.join(File.dirname(__FILE__), '..', 'spec', '**', '*_spec.rb'))
  end

  def repo
    @repo ||= GitRepository.new(File.join(File.dirname(__FILE__), '..'))
  end

  def test_runner
    @test_runner ||= TestRunner.new(File.join(File.dirname(__FILE__), '..'))
  end
end

get '/' do
  @test_files = find_tests
  @git_info = {
    branch: repo.current_branch,
    parsed_status: repo.parsed_status,
    changed_files: repo.changed_files,
    log: repo.recent_log
  }
  slim :index, layout: :layout
end

get '/git/status_panel' do
  @git_info = {
    branch: repo.current_branch,
    parsed_status: repo.parsed_status,
    changed_files: repo.changed_files,
    log: repo.recent_log
  }
  slim :_git_status, layout: false
end

post '/git/add' do
  content_type :json
  file_path = params[:file]

  # Security: Only allow adding files that are reported by git status
  halt 400, { success: false, error: "Invalid file specified" }.to_json unless repo.changed_files.include?(file_path)

  repo.add(file_path)
  { success: true }.to_json
end

post '/git/commit' do
  content_type :json
  message = params[:message]
  repo.commit(message)
  { success: true }.to_json
end

post '/tests/*' do
  file_path = params[:splat].first

  # Security: Only allow running tests that are discovered in the spec folder
  valid_tests = find_tests
  halt 400, "Invalid test file specified" unless valid_tests.include?(file_path)

  result = test_runner.run(file_path)

  @file = file_path
  @summary = result[:summary]
  @examples = result[:examples]

  slim :_spec_details, layout: false
end
