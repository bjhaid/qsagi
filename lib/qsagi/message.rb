module Qsagi
  class Message
    attr_reader :payload, :headers

    def initialize(delivery_details, payload, properties = {})
      @delivery_details = delivery_details
      @payload = payload
      @headers = properties[:headers]
    end

    def delivery_tag
      @delivery_details.delivery_tag
    end

    def exchange
      @delivery_details.exchange
    end
  end
end
