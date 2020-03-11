class MessageAggregator
  def self.aggregate(*args)
    new(*args).aggregate
  end

  def initialize(warnings: [],
                 errors: [],
                 messages: [],
                 markdowns: [],
                 danger_id: "danger")
  end
end
