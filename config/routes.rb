Rails.application.routes.draw do
  root to: redirect('/a/')
  
  get 'download_sample', to: 'auth/users_admin/admin#download_sample'
  get 'download_tickets', to: 'auth/users_admin/admin#download_tickets'
end
