Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from specific origins (configure based on your mobile app/frontend)
    origins ENV.fetch("ALLOWED_ORIGINS", "localhost:3000,localhost:3001").split(",")

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :patch, :put, :delete, :options ],
      credentials: false,
      max_age: 86400 # Cache preflight requests for 24 hours
  end
end
