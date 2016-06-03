Rails.application.routes.draw do

  get "conversation", to: "conversations#new"
  get "conversation/recognize", to: "conversations#recognize"
  get "conversation/entities", to: "conversations#entities"

  get "colors", to: "colors#index"

end
