require 'standupbot/client'
require 'standupbot/slack/channel'

class Api::StandupsController < Api::BaseController

  before_filter :populate_channel_id_if_given_channel_name

  respond_to :html, :text, only: :start

  # GET /api/standups/start
  def start
    @client = Standupbot::Client.new(params[:channel_id])

    if @client.valid?
      @client.delay.start!
    else
      @errors = @client.errors
    end

    respond_with(@errors)
  end

  private

  # If the API receives the channel name instead of the channel slack id,
  #   we need to get the slack id before starting a new session.
  #
  def populate_channel_id_if_given_channel_name
    if params[:channel_id].blank? && params[:channel_name].present?
      channel = Standupbot::Slack::Channel.by_name(params[:channel_name])

      params[:channel_id] = channel.try(:[], 'id')
    end
  end

end
