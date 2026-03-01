require "danger/commands/local_helpers/http_cache"

TEST_CACHE_FILE = File.join(Dir.tmpdir, "http_cache_spec")

RSpec.describe Danger::HTTPCache do
  after do
    File.delete TEST_CACHE_FILE if File.exist? TEST_CACHE_FILE
  end

  it "will default to a 300 second cache expiry" do
    cache = described_class.new(TEST_CACHE_FILE)
    expect(cache.expires_in).to eq(300)
  end

  it "will allow setting a custom cache expiry" do
    cache = described_class.new(TEST_CACHE_FILE, expires_in: 1234)
    expect(cache.expires_in).to eq(1234)
  end

  it "will open a previous file by default" do
    store = PStore.new(TEST_CACHE_FILE)
    store.transaction { store["testing"] = { value: "pants", updated_at: Time.now } }

    result = described_class.new(TEST_CACHE_FILE).read("testing")

    expect(result).to eq("pants")
  end

  it "will delete a previous file if told to" do
    store = PStore.new(TEST_CACHE_FILE)
    store.transaction { store["testing"] = "pants" }

    result = described_class.new(TEST_CACHE_FILE, clear_cache: true).read("testing")

    expect(result).to be_nil
  end

  it "will honor the TTL when a read attempt is made" do
    now = Time.now.to_i
    store = PStore.new(TEST_CACHE_FILE)
    store.transaction do
      store["testing_valid_ttl"] = { value: "pants", updated_at: now - 280 }
      store["testing_invalid_ttl"] = { value: "pants", updated_at: now - 301 }
    end

    cache = described_class.new(TEST_CACHE_FILE)

    expect(cache.read("testing_valid_ttl")).to eq("pants")
    expect(cache.read("testing_invalid_ttl")).to be_nil
  end

  it "will delete a key" do
    cache = described_class.new(TEST_CACHE_FILE)

    cache.write("testing_delete", "pants")
    cache.delete("testing_delete")

    expect(cache.read("testing_delete")).to be_nil
  end

  it "will write a key and timestamp" do
    cache = described_class.new(TEST_CACHE_FILE)
    cache.write("testing_write", "pants")
    store = PStore.new(TEST_CACHE_FILE)
    store.transaction do
      expect(store["testing_write"]).to_not be_nil
      expect(store["testing_write"][:value]).to eq("pants")
      expect(store["testing_write"][:updated_at]).to be_within(1).of(Time.now.to_i)
    end
  end
end
