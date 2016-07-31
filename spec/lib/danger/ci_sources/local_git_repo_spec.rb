require 'spec_helper'
require 'danger/ci_source/local_git_repo'

def run_in_repo
  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      `git init`
      File.open(dir + '/file1', 'w') {}
      `git add .`
      `git commit -m "adding file1"`
      `git checkout -b new-branch`
      File.open(dir + '/file2', 'w') {}
      `git add .`
      `git commit -m "adding file2"`
      `git checkout master`
      `git merge new-branch --no-ff -m "Merge pull request #1234 from new-branch"`
      yield
    end
  end
end

describe Danger::LocalGitRepo do
  it 'validates when run by danger local' do
    env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
    expect(Danger::LocalGitRepo.validates_as_ci?(env)).to be true
  end

  it 'doesnt validate when the local git flag is missing' do
    env = { 'HAS_ANDREW_W_K_SEAL_OF_APPROVAL' => 'true' }
    expect(Danger::LocalGitRepo.validates_as_ci?(env)).to be false
  end

  it 'gets the pull request ID' do
    run_in_repo do
      env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
      t = Danger::LocalGitRepo.new(env)
      expect(t.pull_request_id).to eql('1234')
    end
  end

  describe 'github repos' do
    xit 'gets the repo address when it uses https' do
      run_in_repo do
        `git remote add origin https://github.com/orta/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql('orta/danger')
      end
    end

    it 'gets the repo address when it uses git@' do
      run_in_repo do
        `git remote add origin git@github.com:orta/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql('orta/danger')
      end
    end

    it 'gets the repo address when it contains .git' do
      run_in_repo do
        `git remote add origin git@github.com:artsy/artsy.github.com.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql('artsy/artsy.github.com')
      end
    end

    it 'gets the repo address when it starts with git://' do
      run_in_repo do
        `git remote add origin git://github.com:orta/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql('orta/danger')
      end
    end

    it 'gets the repo address when it starts with git://git@' do
      run_in_repo do
        `git remote add origin git://git@github.com:orta/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql('orta/danger')
      end
    end

    it 'does not set a repo_slug if the repo has a non-gh remote' do
      run_in_repo do
        `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to be_nil
      end
    end
  end

  describe 'enterprise github repos' do
    it 'does set a repo_slug if provided with a github_host' do
      run_in_repo do
        `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true', 'DANGER_GITHUB_HOST' => 'git.evilcorp.com' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql('tyrell/danger')
      end
    end

    it 'does not set a repo_slug if provided with a github_host that is different from the remote' do
      run_in_repo do
        `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
        env = { 'DANGER_USE_LOCAL_GIT' => 'true', 'DANGER_GITHUB_HOST' => 'git.robot.com' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.repo_slug).to be_nil
      end
    end
  end

  describe 'Support looking for a specific PR' do
    def add_another_pr
      # Add a new PR merge commit
      `git checkout -b new-branch2`
      File.open('file3', 'w') {}
      `git add .`
      `git commit -m "adding file2"`
      `git checkout master`
      `git merge new-branch2 --no-ff -m "Merge pull request #1235 from new-branch"`
    end

    it 'handles finding the resulting PR' do
      run_in_repo do
        add_another_pr

        env = { 'DANGER_USE_LOCAL_GIT' => 'true', 'LOCAL_GIT_PR_ID' => '1234' }
        t = Danger::LocalGitRepo.new(env)
        expect(t.pull_request_id).to eql('1234')
      end
    end

    it 'handles not finding the resulting PR' do
      run_in_repo do
        add_another_pr

        env = { 'DANGER_USE_LOCAL_GIT' => 'true', 'LOCAL_GIT_PR_ID' => '1238' }

        expect { Danger::LocalGitRepo.new(env) }.to raise_error RuntimeError
      end
    end
  end
end
