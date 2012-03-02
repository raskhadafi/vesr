Rails.application.routes.draw do
  resources :esr_files
  resources :esr_records do
    member do
      post :write_off, :book_extra_earning, :resolve
    end
  end
end
