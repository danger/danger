require "danger/core_ext/file_list"

RSpec.describe Danger::FileList do
  describe "#include?" do
    before do
      paths = ["path1/file_name.txt", "path1/file_name1.txt", "path2/subfolder/example.json", "path1/file_name_with_[brackets].txt"]
      @filelist = Danger::FileList.new(paths)
    end

    it "supports exact matches" do
      expect(@filelist.include?("path1/file_name.txt")).to eq(true)
      expect(@filelist.include?("path1/file_name_with_[brackets].txt")).to eq(true)
    end

    it "supports * for wildcards" do
      expect(@filelist.include?("path1/*.txt")).to eq(true)
    end

    it "supports ? for single chars" do
      expect(@filelist.include?("path1/file_name.???")).to eq(true)
      expect(@filelist.include?("path1/file_name.?")).to eq(false)
    end

    it "returns false if nothing was found" do
      expect(@filelist.include?("notFound")).to eq(false)
    end

    it "returns false if file path is nil" do
      @filelist = Danger::FileList.new([nil])
      expect(@filelist.include?("pattern")).to eq(false)
    end

    it "supports {a,b} as union of multiple patterns" do
      expect(@filelist.include?("{path1/file_name.txt,path3/file_name.rb}")).to eq(true)
      expect(@filelist.include?("{path1/file_name.rb,path1/file_name.js}")).to eq(false)
      expect(@filelist.include?("{path1/file_name.rb,path1/file_name.js,path2/*}")).to eq(true)
    end
  end
end
