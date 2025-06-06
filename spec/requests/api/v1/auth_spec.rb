require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let(:valid_google_payload) do
    {
      'sub' => '12345',
      'email' => 'user@example.com',
      'name' => 'Test User',
      'picture' => 'https://example.com/avatar.jpg',
      'email_verified' => true
    }
  end

  let(:google_validator) { instance_double(GoogleIDToken::Validator) }

  before do
    # Set up environment variables
    ENV['GOOGLE_CLIENT_ID'] = 'test_google_client_id'
    ENV['JWT_SECRET_KEY'] = 'test_jwt_secret_key'

    # Mock the GoogleIDToken::Validator
    allow(GoogleIDToken::Validator).to receive(:new).and_return(google_validator)
  end

  after do
    # Clean up environment variables
    ENV.delete('GOOGLE_CLIENT_ID')
    ENV.delete('JWT_SECRET_KEY')
  end

  describe 'POST /api/v1/auth/google' do
    let(:url) { '/api/v1/auth/google' }

    context 'with valid Google token' do
      before do
        allow(google_validator).to receive(:check)
          .with('valid_google_token', ENV['GOOGLE_CLIENT_ID'])
          .and_return(valid_google_payload)
      end

      it 'successfully authenticates and returns user data with JWT token' do
        post url, params: { auth: { id_token: 'valid_google_token' } }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)

        # Verify response structure
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('user')

        # Verify JWT token is valid
        token = json_response['token']
        expect(token).to be_present

        decoded = JWT.decode(token, ENV['JWT_SECRET_KEY'], true, { algorithm: 'HS256' })
        payload = decoded.first
        expect(payload['user_id']).to be_present
        expect(payload['email']).to eq('user@example.com')

        # Verify user data
        user_data = json_response['user']
        expect(user_data['id']).to be_present
        expect(user_data['email']).to eq('user@example.com')
        expect(user_data['name']).to eq('Test User')
        expect(user_data['avatar_url']).to eq('https://example.com/avatar.jpg')
      end

      it 'creates user record in database' do
        expect {
          post url, params: { auth: { id_token: 'valid_google_token' } }
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('user@example.com')
        expect(user.name).to eq('Test User')
        expect(user.provider).to eq('google')
        expect(user.provider_id).to eq('12345')
        expect(user.avatar_url).to eq('https://example.com/avatar.jpg')
      end

      it 'handles existing user correctly' do
        # Create existing user with same provider_id
        existing_user = create(:user)
        existing_user.update!(provider_id: '12345', email: 'old@example.com', name: 'Old Name')

        expect {
          post url, params: { auth: { id_token: 'valid_google_token' } }
        }.not_to change(User, :count)

        existing_user.reload
        expect(existing_user.email).to eq('user@example.com')
        expect(existing_user.name).to eq('Test User')
        expect(existing_user.avatar_url).to eq('https://example.com/avatar.jpg')

        # Verify response contains updated user data
        json_response = JSON.parse(response.body)
        user_data = json_response['user']
        expect(user_data['id']).to eq(existing_user.id)
        expect(user_data['email']).to eq('user@example.com')
        expect(user_data['name']).to eq('Test User')
      end
    end

    context 'with invalid request parameters' do
      it 'returns 400 when id_token is missing' do
        post url, params: { auth: {} }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing auth parameter')
      end

      it 'returns 400 when id_token is empty' do
        post url, params: { auth: { id_token: '' } }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing ID token')
      end

      it 'returns 400 when id_token is nil' do
        post url, params: { auth: { id_token: nil } }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing ID token')
      end

      it 'returns 400 when auth parameter is missing' do
        post url, params: {}

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing auth parameter')
      end
    end

    context 'with invalid Google token' do
      it 'returns 401 for invalid/expired Google token' do
        allow(google_validator).to receive(:check)
          .and_raise(GoogleIDToken::ValidationError.new('Invalid token'))

        post url, params: { auth: { id_token: 'invalid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid or expired token')
      end

      it 'returns 401 when Google token payload is incomplete' do
        incomplete_payload = valid_google_payload.except('email')
        allow(google_validator).to receive(:check).and_return(incomplete_payload)

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid token payload')
      end

      it 'returns 401 when email is not verified by Google' do
        unverified_payload = valid_google_payload.merge('email_verified' => false)
        allow(google_validator).to receive(:check).and_return(unverified_payload)

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Email not verified with Google')
      end
    end

    context 'with server configuration issues' do
      it 'returns 500 when Google Client ID is not configured' do
        ENV.delete('GOOGLE_CLIENT_ID')

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Authentication service unavailable')
      end

      it 'returns 500 when JWT secret is not configured' do
        ENV.delete('JWT_SECRET_KEY')
        allow(google_validator).to receive(:check).and_return(valid_google_payload)

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Token generation failed')
      end
    end

    context 'with database constraint violations' do
      it 'returns 409 for unique constraint violations' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        allow(User).to receive(:from_google_token!).and_raise(
          ActiveRecord::RecordNotUnique.new('Duplicate entry')
        )

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)['error']).to eq('User creation failed due to duplicate data')
      end

      it 'returns 422 for validation errors' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        invalid_user = User.new
        invalid_user.errors.add(:email, 'is invalid')
        invalid_user.errors.add(:name, 'is too short')

        allow(User).to receive(:from_google_token!).and_raise(
          ActiveRecord::RecordInvalid.new(invalid_user)
        )

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User validation failed')
        expect(json_response['details']).to include('Email is invalid')
        expect(json_response['details']).to include('Name is too short')
      end
    end

    context 'with unexpected server errors' do
      it 'returns 500 for unexpected exceptions' do
        allow(google_validator).to receive(:check).and_raise(StandardError.new('Unexpected error'))

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Authentication failed')
      end
    end

    context 'with different request formats' do
      it 'handles JSON request body' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)

        post url,
             params: { auth: { id_token: 'valid_token' } }.to_json,
             headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to have_key('token')
      end

      it 'handles form data request' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)

        post url,
             params: { auth: { id_token: 'valid_token' } },
             headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to have_key('token')
      end
    end

    context 'performance and security considerations' do
      it 'does not expose sensitive information in error responses' do
        allow(google_validator).to receive(:check).and_raise(StandardError.new('Sensitive database error'))

        post url, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Authentication failed')
        expect(json_response['error']).not_to include('Sensitive database error')
      end

      it 'returns response within reasonable time' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)

        start_time = Time.current
        post url, params: { auth: { id_token: 'valid_token' } }
        end_time = Time.current

        expect(response).to have_http_status(:ok)
        expect(end_time - start_time).to be < 5.seconds
      end
    end
  end

  describe 'Authentication flow integration' do
    it 'provides complete authentication flow' do
      # Mock Google token validation
      allow(google_validator).to receive(:check)
        .with('google_id_token', ENV['GOOGLE_CLIENT_ID'])
        .and_return(valid_google_payload)

      # Step 1: Sign in with Google
      post '/api/v1/auth/google', params: { auth: { id_token: 'google_id_token' } }

      expect(response).to have_http_status(:ok)
      auth_response = JSON.parse(response.body)
      jwt_token = auth_response['token']
      user_id = auth_response['user']['id']

      # Step 2: Verify the JWT token can be used for authentication
      controller = Api::V1::AuthController.new
      verification_result = controller.verify_jwt_token(jwt_token)

      expect(verification_result[:error]).to be_nil
      expect(verification_result[:user].id).to eq(user_id)
      expect(verification_result[:user].email).to eq('user@example.com')

      # Step 3: Verify user exists in database
      user = User.find(user_id)
      expect(user.email).to eq('user@example.com')
      expect(user.name).to eq('Test User')
      expect(user.provider).to eq('google')
      expect(user.provider_id).to eq('12345')
    end
  end
end
