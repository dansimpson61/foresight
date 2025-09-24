require_relative '../spec_helper'
require_relative '../../lib/git_repository.rb'

RSpec.describe GitRepository do
  let(:project_root) { '/app' }
  let(:repo) { described_class.new(project_root) }

  describe '#current_branch' do
    it 'returns the current git branch' do
      expect(Open3).to receive(:capture3).with('git branch --show-current', chdir: project_root).and_return(['main', '', double(success?: true)])
      expect(repo.current_branch).to eq('main')
    end
  end

  describe '#parsed_status' do
    it 'parses the status output into a grouped hash' do
      raw_status = "M  lib/a.rb\n?? new.rb\n"
      allow(repo).to receive(:status).and_return(raw_status)
      expect(repo.parsed_status).to eq({
        'Modified' => [{ status: 'M', file: 'lib/a.rb' }],
        'Untracked' => [{ status: '??', file: 'new.rb' }]
      })
    end
  end

  describe '#changed_files' do
    it 'returns a simple list of changed files' do
      raw_status = "M  lib/a.rb\n?? new.rb\n"
      allow(repo).to receive(:status).and_return(raw_status)
      expect(repo.changed_files).to eq(['lib/a.rb', 'new.rb'])
    end
  end

  describe '#recent_log' do
    it 'returns a formatted log of recent commits' do
      log_output = "abc123 - Jules, 1 day ago : feat: add dashboard\ndef456 - Jules, 2 days ago : fix: bug"
      expect(Open3).to receive(:capture3).with("git log -n 5 --pretty=format:'%h - %an, %ar : %s'", chdir: project_root).and_return([log_output, '', double(success?: true)])
      expect(repo.recent_log).to eq(["abc123 - Jules, 1 day ago : feat: add dashboard", "def456 - Jules, 2 days ago : fix: bug"])
    end
  end

  describe '#add' do
    it 'calls git add with the specified file' do
      file_path = 'dashboard/dashboard.rb'
      safe_path = Shellwords.escape(file_path)
      expect(Open3).to receive(:capture3).with("git add #{safe_path}", chdir: project_root)
      repo.add(file_path)
    end
  end

  describe '#commit' do
    it 'calls git commit with the given message' do
      message = 'A test commit message'
      safe_message = Shellwords.escape(message)
      expect(Open3).to receive(:capture3).with("git commit -m #{safe_message}", chdir: project_root)
      repo.commit(message)
    end
  end
end
