require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :controller do
  let(:valid_google_payload) do
    {
      'sub' => '12345',
      'email' => 'user@example.com',
      'name' => 'Test User',
      'picture' => 'https://example.com/avatar.jpg',
      'email_verified' => true
    }
  end

  let(:valid_jwt_token) { controller.send(:generate_jwt_token, create(:user)) }
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

  describe 'POST #google_sign_in' do
    context 'with valid parameters' do
      before do
        allow(google_validator).to receive(:check)
          .with('valid_token', ENV['GOOGLE_CLIENT_ID'])
          .and_return(valid_google_payload)
      end

      it 'successfully authenticates user and returns JWT token' do
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('user')
        
        user_data = json_response['user']
        expect(user_data['email']).to eq('user@example.com')
        expect(user_data['name']).to eq('Test User')
      end

      it 'creates a new user when user does not exist' do
        expect {
          post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('user@example.com')
        expect(user.name).to eq('Test User')
        expect(user.provider).to eq('google')
        expect(user.provider_id).to eq('12345')
      end

      it 'updates existing user when user already exists' do
        existing_user = create(:user)
        existing_user.update!(provider_id: '12345', email: 'old@example.com', name: 'Old Name')

        expect {
          post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
        }.not_to change(User, :count)

        existing_user.reload
        expect(existing_user.email).to eq('user@example.com')
        expect(existing_user.name).to eq('Test User')
      end

      it 'logs successful authentication' do
        allow(Rails.logger).to receive(:info) # Allow other info messages
        expect(Rails.logger).to receive(:info).with(/Successful Google sign in for user/)
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end
    end

    context 'with invalid parameters' do
      it 'returns error when id_token is missing' do
        post :google_sign_in, params: { auth: {} }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing auth parameter')
      end

      it 'returns error when id_token is blank' do
        post :google_sign_in, params: { auth: { id_token: '' } }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing ID token')
      end

      it 'returns error when auth parameter is missing' do
        post :google_sign_in, params: {}

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing auth parameter')
      end
    end

    context 'when Google Client ID is not configured' do
      before do
        ENV.delete('GOOGLE_CLIENT_ID')
      end

      it 'returns internal server error' do
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Authentication service unavailable')
      end

      it 'logs the configuration error' do
        expect(Rails.logger).to receive(:error).with('Google Client ID not configured')
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end
    end

    context 'when Google token validation fails' do
      it 'returns unauthorized for invalid token' do
        allow(google_validator).to receive(:check)
          .and_raise(GoogleIDToken::ValidationError.new('Invalid token'))

        post :google_sign_in, params: { auth: { id_token: 'invalid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid or expired token')
      end

      it 'logs validation error' do
        allow(google_validator).to receive(:check)
          .and_raise(GoogleIDToken::ValidationError.new('Invalid token'))

        expect(Rails.logger).to receive(:error).with(/Google token validation failed/)
        
        post :google_sign_in, params: { auth: { id_token: 'invalid_token' } }
      end
    end

    context 'when token payload is invalid' do
      it 'returns unauthorized when sub is missing' do
        invalid_payload = valid_google_payload.except('sub')
        allow(google_validator).to receive(:check).and_return(invalid_payload)

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid token payload')
      end

      it 'returns unauthorized when email is missing' do
        invalid_payload = valid_google_payload.except('email')
        allow(google_validator).to receive(:check).and_return(invalid_payload)

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid token payload')
      end

      it 'returns unauthorized when name is missing' do
        invalid_payload = valid_google_payload.except('name')
        allow(google_validator).to receive(:check).and_return(invalid_payload)

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid token payload')
      end

      it 'returns unauthorized when email is not verified' do
        invalid_payload = valid_google_payload.merge('email_verified' => false)
        allow(google_validator).to receive(:check).and_return(invalid_payload)

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Email not verified with Google')
      end

      it 'logs invalid payload error' do
        invalid_payload = valid_google_payload.except('sub')
        allow(google_validator).to receive(:check).and_return(invalid_payload)

        expect(Rails.logger).to receive(:error).with(/Invalid Google token payload/)
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end

      it 'logs unverified email warning' do
        invalid_payload = valid_google_payload.merge('email_verified' => false)
        allow(google_validator).to receive(:check).and_return(invalid_payload)

        expect(Rails.logger).to receive(:warn).with(/Unverified email attempted sign in/)
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end
    end

    context 'when user creation/update fails' do
      it 'returns unprocessable entity for validation errors' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        allow(User).to receive(:from_google_token!).and_raise(
          ActiveRecord::RecordInvalid.new(User.new.tap { |u| u.errors.add(:email, 'is invalid') })
        )

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User validation failed')
        expect(json_response['details']).to include('Email is invalid')
      end

      it 'returns conflict for duplicate data' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        allow(User).to receive(:from_google_token!).and_raise(
          ActiveRecord::RecordNotUnique.new('Duplicate entry')
        )

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)['error']).to eq('User creation failed due to duplicate data')
      end

      it 'logs user creation errors' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        allow(User).to receive(:from_google_token!).and_raise(
          ActiveRecord::RecordInvalid.new(User.new.tap { |u| u.errors.add(:email, 'is invalid') })
        )

        expect(Rails.logger).to receive(:error).with(/User creation\/update failed/)
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end
    end

    context 'when JWT generation fails' do
      it 'returns internal server error for JWT encoding errors' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        allow(User).to receive(:from_google_token!).and_return(create(:user))
        allow(controller).to receive(:generate_jwt_token).and_raise(JWT::EncodeError.new('Invalid secret'))

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Token generation failed')
      end

      it 'logs JWT encoding errors' do
        allow(google_validator).to receive(:check).and_return(valid_google_payload)
        allow(User).to receive(:from_google_token!).and_return(create(:user))
        allow(controller).to receive(:generate_jwt_token).and_raise(JWT::EncodeError.new('Invalid secret'))

        expect(Rails.logger).to receive(:error).with(/JWT encoding failed/)
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end
    end

    context 'when unexpected error occurs' do
      it 'returns internal server error for unexpected exceptions' do
        allow(google_validator).to receive(:check).and_raise(StandardError.new('Unexpected error'))

        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Authentication failed')
      end

      it 'logs unexpected errors with backtrace' do
        allow(google_validator).to receive(:check).and_raise(StandardError.new('Unexpected error'))

        expect(Rails.logger).to receive(:error).with(/Unexpected error during Google sign in/)
        expect(Rails.logger).to receive(:error).with(anything) # backtrace
        
        post :google_sign_in, params: { auth: { id_token: 'valid_token' } }
      end
    end
  end

  describe '#verify_jwt_token' do
    let(:user) { create(:user) }
    let(:valid_token) { controller.send(:generate_jwt_token, user) }

    context 'with valid token' do
      it 'returns user for valid token' do
        result = controller.verify_jwt_token(valid_token)

        expect(result[:user]).to eq(user)
        expect(result[:error]).to be_nil
      end
    end

    context 'with invalid token' do
      it 'returns error for invalid token format' do
        result = controller.verify_jwt_token('invalid.token.format')

        expect(result[:error]).to eq('Invalid token')
        expect(result[:user]).to be_nil
      end

      it 'returns error for token with invalid signature' do
        # Create token with different secret
        invalid_token = JWT.encode({ user_id: user.id }, 'wrong_secret', 'HS256')

        result = controller.verify_jwt_token(invalid_token)

        expect(result[:error]).to eq('Invalid token')
        expect(result[:user]).to be_nil
      end

      it 'returns error for expired token' do
        # Create an actually expired token using JWT with past expiration
        expired_payload = {
          user_id: user.id,
          exp: 1.hour.ago.to_i,
          iat: 2.hours.ago.to_i
        }
        
        # Create token that will be expired when JWT tries to decode it
        # We need to bypass JWT's automatic expiration checking by using a different approach
        allow(JWT).to receive(:decode).and_call_original
        allow(JWT).to receive(:decode).with(anything, ENV['JWT_SECRET_KEY'], true, { algorithm: 'HS256' }) do |token, secret, verify, options|
          if token == 'expired_token'
            raise JWT::ExpiredSignature
          else
            JWT.decode(token, secret, verify, options)
          end
        end

        result = controller.verify_jwt_token('expired_token')

        expect(result[:error]).to eq('Token expired')
        expect(result[:user]).to be_nil
      end

      it 'returns error when user is not found' do
        non_existent_user_payload = {
          user_id: 99999,
          exp: 1.hour.from_now.to_i
        }
        token = JWT.encode(non_existent_user_payload, ENV['JWT_SECRET_KEY'], 'HS256')

        result = controller.verify_jwt_token(token)

        expect(result[:error]).to eq('User not found')
        expect(result[:user]).to be_nil
      end

      it 'logs decode errors' do
        expect(Rails.logger).to receive(:error).with(/JWT decode failed/)

        controller.verify_jwt_token('invalid.token.format')
      end

      it 'logs token verification errors' do
        allow(JWT).to receive(:decode).and_raise(StandardError.new('Unexpected error'))
        
        expect(Rails.logger).to receive(:error).with(/Token verification failed/)

        controller.verify_jwt_token(valid_token)
      end
    end

    context 'with manually expired token' do
      it 'returns error for manually expired token in payload' do
        # Test the manual expiration check by directly testing the controller logic
        # Create a valid user and mock the JWT decode to return an expired payload
        test_user = create(:user)
        
        # Stub the JWT.decode method to return an expired payload
        expired_payload = {
          'user_id' => test_user.id,
          'exp' => 1.hour.ago.to_i,
          'iat' => 2.hours.ago.to_i
        }
        
        allow(JWT).to receive(:decode).and_return([expired_payload, {}])

        result = controller.verify_jwt_token('any_token')

        expect(result[:error]).to eq('Token expired')
      end
    end
  end

  describe '#generate_jwt_token' do
    let(:user) { create(:user) }

    context 'with valid parameters' do
      it 'generates valid JWT token' do
        token = controller.send(:generate_jwt_token, user)

        expect(token).to be_present
        
        # Decode and verify token structure
        decoded = JWT.decode(token, ENV['JWT_SECRET_KEY'], true, { algorithm: 'HS256' })
        payload = decoded.first

        expect(payload['user_id']).to eq(user.id)
        expect(payload['email']).to eq(user.email)
        expect(payload['iat']).to be_present
        expect(payload['exp']).to be_present
        expect(payload['exp']).to be > Time.current.to_i
      end
    end

    context 'when JWT secret is not configured' do
      before { ENV.delete('JWT_SECRET_KEY') }

      it 'raises JWT::EncodeError' do
        expect {
          controller.send(:generate_jwt_token, user)
        }.to raise_error(JWT::EncodeError, 'JWT secret key not configured')
      end
    end

    context 'with invalid user object' do
      it 'raises ArgumentError for nil user' do
        expect {
          controller.send(:generate_jwt_token, nil)
        }.to raise_error(ArgumentError, 'Invalid user object for token generation')
      end

      it 'raises ArgumentError for unpersisted user' do
        unpersisted_user = build(:user)
        
        expect {
          controller.send(:generate_jwt_token, unpersisted_user)
        }.to raise_error(ArgumentError, 'Invalid user object for token generation')
      end

      it 'raises ArgumentError for user without id' do
        user_without_id = create(:user)
        allow(user_without_id).to receive(:id).and_return(nil)
        
        expect {
          controller.send(:generate_jwt_token, user_without_id)
        }.to raise_error(ArgumentError, 'Invalid user object for token generation')
      end
    end
  end
end 