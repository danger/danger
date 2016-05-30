require 'ostruct'

module Danger
  describe DangerfileGitPlugin do
    it "fails init if the dangerfile's request source is not a GitRepo" do
      dm = testing_dangerfile
      dm.env.scm = []
      expect { DangerfileGitPlugin.new dm }.to raise_error RuntimeError
    end

    describe "dsl" do
      before do
        dm = testing_dangerfile
        @dsl = DangerfileGitPlugin.new dm
        @repo = dm.env.scm
      end

      it "gets added_files " do
        diff = [OpenStruct.new(type: "new", path: "added")]
        allow(@repo).to receive(:diff).and_return(diff)

        expect(@dsl.added_files).to eq(["added"])
      end

      it "gets deleted_files " do
        diff = [OpenStruct.new(type: "deleted", path: "deleted")]
        allow(@repo).to receive(:diff).and_return(diff)

        expect(@dsl.deleted_files).to eq(["deleted"])
      end

      it "gets modified_files " do
        stats = { files: { "my/path/file_name" => "thing" } }
        diff = OpenStruct.new(stats: stats)
        allow(@repo).to receive(:diff).and_return(diff)

        expect(@dsl.modified_files).to eq(["my/path/file_name"])
      end

      it "gets lines_of_code" do
        diff = OpenStruct.new(lines: 2)
        allow(@repo).to receive(:diff).and_return(diff)

        expect(@dsl.lines_of_code).to eq(2)
      end

      it "gets deletions" do
        diff = OpenStruct.new(deletions: 4)
        allow(@repo).to receive(:diff).and_return(diff)

        expect(@dsl.deletions).to eq(4)
      end

      it "gets insertions" do
        diff = OpenStruct.new(insertions: 6)
        allow(@repo).to receive(:diff).and_return(diff)

        expect(@dsl.insertions).to eq(6)
      end

      it "gets commits" do
        log = ["hi"]
        allow(@repo).to receive(:log).and_return(log)

        expect(@dsl.commits).to eq(log)
      end
    end
  end
end
