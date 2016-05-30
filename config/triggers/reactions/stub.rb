Houston.observer.on "slack:reaction:added" do |reaction, message|
  puts "\e[35mAdded #{reaction} to #{message["text"].inspect}\e[0m"
end

Houston.observer.on "slack:reaction:removed" do |reaction, message|
  puts "\e[35mRemoved #{reaction} from #{message["text"].inspect}\e[0m"
end
