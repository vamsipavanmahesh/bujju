Rails.application.configure do
  # Security headers for API responses
  config.force_ssl = true if Rails.env.production?

  # Add security headers middleware

  # Set secure headers
  config.middleware.insert_before 0, Rack::CommonLogger
end

# Add security headers to all responses
class SecurityHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Add security headers for API endpoints
    if env["PATH_INFO"].start_with?("/api")
      headers["X-Content-Type-Options"] = "nosniff"
      headers["X-Frame-Options"] = "DENY"
      headers["X-XSS-Protection"] = "1; mode=block"
      headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
      headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    end

    [ status, headers, response ]
  end
end

Rails.application.config.middleware.use SecurityHeadersMiddleware
