module Houston
  module SideProject
    class Base
      attr_reader :user, :conversation

      def initialize(attributes)
        @user = attributes.fetch :user
        @conversation = attributes.fetch :conversation
        @description = attributes.fetch :description
        @advisory = nil
        @on_complete_proc = nil
      end

      def start!
        raise NotImplementedError
      end

      def on_complete(&block)
        @on_complete_proc = block
      end

      def describe
        [description, advisory].compact.join(" ")
      end

      def cancel!
        end!
      end

    protected

      def end!(*messages)
        if conversation
          conversation.reply(*messages) if messages.any?
          conversation.end!
        end

        on_complete_proc.call(self) if on_complete_proc
        self
      end

      def advise(advisory)
        @advisory = advisory
      end

    private
      attr_reader :description, :advisory, :on_complete_proc

    end
  end
end
