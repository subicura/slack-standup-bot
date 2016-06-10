require_relative 'simple'

class IncomingMessage
  class Answer < Simple

    def execute
      super

      if @standup.active? && yes?
        @standup.start!

        channel.message(@standup.current_question)

      elsif @standup.answering?
        @standup.process_answer(@message['text'])

        if @standup.completed?
          channel.message('좋은 하루 되세요!')
        else
          channel.message(@standup.current_question)
        end
      end
    end

    def validate!
      if !@standup.in_progress?
        raise InvalidCommandError.new('You can not answer a question before your turn.')
      end

      super
    end

    private

    # @return [Boolean]
    def yes?
      MessageType.new(@message['text']).yes?
    end

  end
end
