RailsUrlShortener::Engine.routes.draw do
  get '/', to: RailsUrlShortener::RootHandler if RailsUrlShortener.block_root
  get '/:key', to: 'urls#show'
end
