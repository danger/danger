require 'spec_helper'
require 'danger/ci_source/local_git_repo'

def run_in_repo
  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      `git init`
      `touch file1`
      `git add .`
      `git commit -m "adding file1"`
      `git checkout -b new-branch`
      `touch file2`
      `git add .`
      `git commit -m "adding file2"`
      `git checkout master`
      `git merge new-branch --no-ff -m "Merge pull request #1234 from new-branch"`

      yield
    end
  end
end

describe Danger::CISource::LocalGitRepo do
  it 'validates when run by danger local' do
    env = { "DANGER_USE_LOCAL_GIT" => "true" }
    expect(Danger::CISource::LocalGitRepo.validates?(env)).to be true
  end

  it 'doesnt validate when the local git flag is missing' do
    env = { "HAS_ANDREW_W_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CISource::LocalGitRepo.validates?(env)).to be false
  end

  it 'gets the pull request ID' do
    run_in_repo do
      env = { "DANGER_USE_LOCAL_GIT" => "true" }
      t = Danger::CISource::LocalGitRepo.new(env)
      expect(t.pull_request_id).to eql("1234")
    end
  end

  describe 'github repos' do
    it 'gets the repo address when it uses https' do
      run_in_repo do
        `git remote add origin https://github.com/orta/danger.git`
        env = { "DANGER_USE_LOCAL_GIT" => "true" }
        t = Danger::CISource::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql("orta/danger")
      end
    end

    it 'gets the repo address when it uses git@' do
      run_in_repo do
        `git remote add origin git@github.com:orta/danger.git`
        env = { "DANGER_USE_LOCAL_GIT" => "true" }
        t = Danger::CISource::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql("orta/danger")
      end
    end

    it 'gets the repo address when it contains .git' do
      run_in_repo do
        `git remote add origin git@github.com:artsy/artsy.github.com.git`
        env = { "DANGER_USE_LOCAL_GIT" => "true" }
        t = Danger::CISource::LocalGitRepo.new(env)
        expect(t.repo_slug).to eql("artsy/artsy.github.com")
      end
    end
  end

  describe 'non-github repos' do
    it 'does not set a repo_slug' do
      run_in_repo do
        `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
        env = { "DANGER_USE_LOCAL_GIT" => "true" }
        t = Danger::CISource::LocalGitRepo.new(env)
        expect(t.repo_slug).to be_nil
      end
    end
  end
end
