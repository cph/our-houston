Houston::Engine.routes.draw do


  # Activity Feed

  get "activity" => "activity_feed#index", as: :activity_feed



   # Conversation Tester

  get "conversation", to: "conversations#new"
  get "conversation/recognize", to: "conversations#recognize"
  get "conversation/entities", to: "conversations#entities"



  # Misc

  get "colors", to: "colors#index"

end
