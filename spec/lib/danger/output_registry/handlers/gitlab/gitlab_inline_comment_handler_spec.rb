# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::GitLab::GitLabInlineCommentHandler do
  let(:context) { instance_double(Danger::RequestSources::GitLab, supports_inline_comments: false) }
  let(:shared_state) { { out_of_range_violations: { warnings: [], errors: [], messages: [] }, out_of_range_markdowns: [] } }
  let(:inline_error) { Danger::Violation.new("boom", false, "a.rb", 1) }
  let(:inline_markdown) { Danger::Markdown.new("md", "a.rb", 1) }

  before do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitLab).and_return(true)
  end

  it "hands inline violations to the main comment when inline comments are unsupported" do
    handler = described_class.new(
      context, { warnings: [], errors: [inline_error], messages: [] },
      danger_id: "danger", markdowns: [inline_markdown], shared_state: shared_state
    )

    handler.execute

    expect(shared_state[:out_of_range_violations][:errors]).to eq([inline_error])
    expect(shared_state[:out_of_range_markdowns]).to eq([inline_markdown])
  end

  describe "#find_old_position" do
    let(:context) { instance_double(Danger::RequestSources::GitLab, mr_changes: double(changes: changes)) }
    let(:handler) { described_class.new(context, { warnings: [], errors: [], messages: [] }, danger_id: "danger") }

    let(:new_path) do
      "dummy"
    end

    let(:old_path) do
      "dummy"
    end

    let(:new_file) do
      false
    end

    let(:renamed_file) do
      false
    end

    let(:deleted_file) do
      false
    end

    let(:diff_lines) do
      ""
    end

    let(:changes) do
      [{
         "new_path" => new_path,
         "old_path" => old_path,
         "diff" => diff_lines,
         "new_file" => new_file,
         "renamed_file" => renamed_file,
         "deleted_file" => deleted_file
       }]
    end

    context "new file" do
      let(:diff_lines) do
        <<-DIFF
@@ -0,0 +1,3 @@
+foo
+bar
+baz
        DIFF
      end

      let(:new_file) do
        true
      end

      it "returns path only" do
        position = handler.send(:find_old_position, double(file: new_path, line: 1))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to be_nil
      end
    end

    context "slightly modified file" do
      let(:diff_lines) do
        <<-DIFF
@@ -1 +1,2 @@
-foo
+bar
+baz
        DIFF
      end

      it "returns path only" do
        position = handler.send(:find_old_position, double(file: new_path, line: 1))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to be_nil
      end
    end

    context "heavily modified files" do
      let(:diff_lines) do
        <<-DIFF
@@ -2,7 +2,8 @@
 a
 a
 a
-foo
+bar
+baz
 a
 a
 a
@@ -21,7 +22,8 @@
 a
 a
 a
-foo
+bar
+baz
 a
 a
 a
        DIFF
      end

      it "returns path only when message line is new" do
        position = handler.send(:find_old_position, double(file: new_path, line: 5))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to be_nil
      end

      it "returns path and correct line when message line isn't new" do
        position = handler.send(:find_old_position, double(file: new_path, line: 3))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to eq(3)
      end

      it "returns path and correct line when the line is before diffs" do
        position = handler.send(:find_old_position, double(file: new_path, line: 1))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to eq(1)
      end

      it "returns path and correct line when the line is between diffs" do
        position = handler.send(:find_old_position, double(file: new_path, line: 15))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to eq(14)
      end

      it "returns path and correct line when the line is after diffs" do
        position = handler.send(:find_old_position, double(file: new_path, line: 35))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to eq(33)
      end
    end

    context "deleted file" do
      let(:diff_lines) do
        <<-DIFF
@@ -1,3 +0,0 @@
-foo
-bar
-baz
        DIFF
      end

      let(:deleted_file) do
        true
      end

      it "returns nil" do
        position = handler.send(:find_old_position, double(file: new_path, line: 1))
        expect(position).to be_nil
      end
    end

    context "renamed only file" do
      let(:renamed_file) do
        true
      end

      let(:new_path) do
        "new_dummy"
      end

      it "returns nil" do
        position = handler.send(:find_old_position, double(file: new_path, line: 1))
        expect(position).to be_nil
      end
    end

    context "renamed and modified file" do
      let(:diff_lines) do
        <<-DIFF
@@ -1 +1,2 @@
@@ -2,7 +2,8 @@
 a
 a
 a
-foo
+bar
+baz
 a
 a
 a
        DIFF
      end

      let(:renamed_file) do
        true
      end

      let(:new_path) do
        "dummy_new"
      end

      it "returns old path only when message line is new" do
        position = handler.send(:find_old_position, double(file: new_path, line: 5))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to be_nil
      end

      it "returns old path and correct line when message line isn't new" do
        position = handler.send(:find_old_position, double(file: new_path, line: 3))
        expect(position[:path]).to eq(old_path)
        expect(position[:line]).to eq(3)
      end
    end

    context "unchanged file" do
      let(:diff_lines) do
        <<-DIFF
@@ -0,0 +1,3 @@
+foo
+bar
+baz
        DIFF
      end

      it "returns nil" do
        position = handler.send(:find_old_position, double(file: "dummy_unchanged", line: 5))
        expect(position).to be_nil
      end
    end
  end
end
