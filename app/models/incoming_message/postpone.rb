require_relative 'simple'

class IncomingMessage
  class Postpone < Simple

    def execute
      super

      @standup.skip!

      channel.message(I18n.t('incoming_message.skip', user: @standup.user_slack_id))
    end

    def validate!
      if !@standup.active?
        raise InvalidCommandError.new("물어봤을때만 skip할 수 있어요.")
      elsif channel.today_standups.pending.empty?
        raise InvalidCommandError.new("마지막 사람은 skip할 수 없어요. 작성할게 없으면 -n/a를 입력하세요.")
      end

      super
    end

  end
end
