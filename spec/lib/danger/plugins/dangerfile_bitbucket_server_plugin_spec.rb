# coding: utf-8

module Danger
  describe DangerfileBitbucketServerPlugin do
    describe "dsl" do
      before do
        bs_env = {
          "DANGER_BITBUCKETSERVER_HOST" => "stash.example.com",
          "DANGER_BITBUCKETSERVER_USERNAME" => "a.name",
          "DANGER_BITBUCKETSERVER_PASSWORD" => "a_password",
          "JENKINS_URL" => "http://jenkins.example.com/job/ios-check-pullrequest/",
          "GIT_URL" => "ssh://git@stash.example.com:7999/ios/fancyapp.git",
          "ghprbPullId" => "2080"
        }
        env = Danger::EnvironmentManager.new(bs_env)
        dm = Danger::Dangerfile.new(env, testing_ui)
        @dsl = DangerfileBitbucketServerPlugin.new dm
        pr_response = JSON.parse(fixture("bitbucket_server_api/pr_response"), symbolize_names: true)
        allow(env.request_source).to receive(:pr_json).and_return(pr_response)
      end

      it "it has the pr_json" do
        expect(@dsl.pr_json).to be_truthy
      end

      it "it has a title" do
        expect(@dsl.pr_title).to eql("This is a danger test")
      end

      it "it has a author slug" do
        expect(@dsl.pr_author).to eql("a.user")
      end
    end
  end
end
