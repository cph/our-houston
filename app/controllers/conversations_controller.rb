class ConversationsController < ApplicationController

  def new
    render layout: "naked"
  end

  def recognize
    phrases = Array(params[:examples]).map(&Attentive.method(:abstract)).uniq
    render json: { phrases: phrases }
  end

  def entities
    render json: { entities: Attentive::Entity.entities.map(&:token_name).sort }
  end

end
