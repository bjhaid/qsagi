require "spec_helper"

describe Qsagi::Queue do
  it "and push and pop from a queue" do
    ExampleQueue.connect do |queue|
      queue.push(:payload => "message")
      result = queue.pop
      result.payload.should == "message"
    end
  end

  it "allows passing message headers" do
    ExampleQueue.connect do |queue|
      queue.push(:payload => "message", :headers => {"id" => "12345", "name" => "foo"})
      result = queue.pop
      result.payload.should == "message"
      result.headers.should == {"id" => "12345", "name" => "foo"}
    end
  end

  describe "self.exchange" do
    it "configures the exchange" do
      queue_on_exchange1 = Class.new(ExampleQueue) do
        exchange "exchange1", :type => :direct
      end
      queue_on_exchange2 = Class.new(ExampleQueue) do
        exchange "exchange2"
      end
      queue_on_exchange1.connect do |queue|
        queue.push :payload => "message1"
      end
      queue_on_exchange1.connect do |queue|
        message = queue.pop
        message.payload.should == "message1"
        message.exchange.should == "exchange1"
      end
      queue_on_exchange2.connect do |queue|
        queue.pop.should be_nil
      end
    end
  end

  describe "clear" do
    it "clears the queue" do
      ExampleQueue.connect do |queue|
        queue.push(:payload => "message")
        queue.clear
        queue.pop.should == nil
      end
    end
  end

  describe "length" do
    it "returns the number of messages in the queue" do
      ExampleQueue.connect do |queue|
        queue.push(:payload => "message")
        queue.length.should == 1
        queue.push(:payload => "message")
        queue.length.should == 2
        queue.pop
        queue.length.should == 1
      end
    end
  end

  describe "reject" do
    it "rejects the message and places it back on the queue" do
      ExampleQueue.connect do |queue|
        queue.push(:payload => "message")
        message = queue.pop(:auto_ack => false)
        queue.reject(message, :requeue => true)
      end
      ExampleQueue.connect do |queue|
        queue.length.should == 1
      end
    end

    it "rejects and discards the message" do
      ExampleQueue.connect do |queue|
        queue.push(:payload => "message")
        message = queue.pop(:auto_ack => false)
        queue.reject(message, :requeue => false)
      end
      ExampleQueue.connect do |queue|
        queue.length.should == 0
      end
    end
  end

  describe "pop" do
    it "automatically acks if :auto_ack is not passed in" do
      ExampleQueue.connect do |queue|
        queue.push(:payload => "message")
        message = queue.pop
        message.payload.should == "message"
      end
      ExampleQueue.connect do |queue|
        message = queue.pop
        message.should == nil
      end
    end

    it "will not automatically ack if :auto_ack is set to false" do
      ExampleQueue.connect do |queue|
        queue.push(:payload => "message")
        message = queue.pop(:auto_ack => false)
        message.payload.should == "message"
      end
      ExampleQueue.connect do |queue|
        message = queue.pop(:auto_ack => false)
        message.payload.should == "message"
        queue.ack(message)
      end
      ExampleQueue.connect do |queue|
        message = queue.pop(:auto_ack => false)
        message.should == nil
      end
    end
  end

  describe "queue_type confirmed" do
    it "should use a ConfirmedQueue" do
      ExampleQueue.connect(:queue_type => :confirmed) do |queue|
        queue.push(:payload => "message")
        queue.wait_for_confirms
        queue.nacked_messages.size.should == 0
      end
    end
  end
end
