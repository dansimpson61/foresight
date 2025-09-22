require 'sinatra'
require 'slim'
require 'open3'
require 'shellwords'

helpers do
  def find_tests
    # Search for spec files in the parent directory's spec folder
    Dir.glob(File.join(File.dirname(__FILE__), '..', 'spec', '**', '*_spec.rb'))
  end

  def get_git_info
    project_root = File.join(File.dirname(__FILE__), '..')

    branch, _, _ = Open3.capture3('git rev-parse --abbrev-ref HEAD', chdir: project_root)
    status_output, _, _ = Open3.capture3('git status --porcelain', chdir: project_root)
    log, _, _ = Open3.capture3("git log -n 5 --pretty=format:'%h - %an, %ar : %s'", chdir: project_root)

    changed_files = status_output.strip.split("\n").map { |line| line.split.last }

    {
      branch: branch.strip,
      status: status_output.strip,
      changed_files: changed_files,
      log: log.strip.split("\n")
    }
  end
end

get '/' do
  @test_files = find_tests
  @git_info = get_git_info
  slim :index
end

post '/git/add' do
  file_path = params[:file]

  # Security: Only allow adding files that are reported by git status
  valid_files = get_git_info[:changed_files]
  halt 400, "Invalid file specified" unless valid_files.include?(file_path)

  project_root = File.join(File.dirname(__FILE__), '..')
  Open3.capture3("git add #{file_path}", chdir: project_root)
  redirect '/'
end

post '/git/commit' do
  message = params[:message]
  project_root = File.join(File.dirname(__FILE__), '..')

  # Escape the message for security
  safe_message = Shellwords.escape(message)

  Open3.capture3("git commit -m #{safe_message}", chdir: project_root)
  redirect '/'
end

post '/run_test' do
  file_path = params[:file]

  # Security: Only allow running tests that are discovered in the spec folder
  valid_tests = find_tests
  halt 400, "Invalid test file specified" unless valid_tests.include?(file_path)

  # We need to run this from the parent directory
  project_root = File.join(File.dirname(__FILE__), '..')

  # Construct the command
  command = "bundle exec rspec #{file_path}"

  # Run the command and capture output
  stdout, stderr, status = Open3.capture3(command, chdir: project_root)

  @file = file_path
  @output = stdout + stderr
  @exit_status = status.exitstatus
  @status_class = @exit_status == 0 ? 'pass' : 'fail'

  slim :test_result
end
