RailsUrlShortener::Engine.routes.draw do
  constraints RailsUrlShortener::HostConstraint do
    get '/', to: RailsUrlShortener::RootHandler, constraints: ->(req) { RailsUrlShortener.block_root }
    get '/:key', to: 'urls#show'
  end
end
