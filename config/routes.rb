RailsUrlShortener::Engine.routes.draw do
  constraints RailsUrlShortener::HostConstraint do
    get '/:key', to: 'urls#show'
  end
end
