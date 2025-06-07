require 'rails_helper'

RSpec.describe 'Api::V1::UserPreferences', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:user_preference) { create(:user_preference, user: user) }
  let(:valid_token) do
    JWT.encode({ user_id: user.id }, ENV["JWT_SECRET_KEY"], 'HS256')
  end
  let(:invalid_token) { 'invalid_token' }
  let(:headers) { { 'Authorization' => "Bearer #{valid_token}" } }
  let(:invalid_headers) { { 'Authorization' => "Bearer #{invalid_token}" } }

  before do
    # Set up JWT secret for test environment
    ENV["JWT_SECRET_KEY"] = 'test_jwt_secret_key'
  end

  after do
    # Clean up environment variables
    ENV.delete("JWT_SECRET_KEY")
  end

  describe 'GET /api/v1/user_preferences' do
    context 'with valid authentication and existing preferences' do
      before { user_preference } # Create the user preference

      it 'returns the user preferences' do
        get '/api/v1/user_preferences', headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['id']).to eq(user_preference.id)
        expect(json_response['data']['notification_time']).to eq('14:30')
        expect(json_response['data']['timezone']).to eq('Asia/Kolkata')
        expect(json_response['data']).to have_key('created_at')
        expect(json_response['data']).to have_key('updated_at')
      end
    end

    context 'with valid authentication but no preferences' do
      it 'creates and returns new user preferences' do
        expect {
          get '/api/v1/user_preferences', headers: headers
        }.to change(UserPreference, :count).by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']).to have_key('id')
        expect(json_response['data']['notification_time']).to be_nil
        expect(json_response['data']['timezone']).to be_nil
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/user_preferences'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing authorization token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        get '/api/v1/user_preferences', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid token')
      end
    end
  end

  describe 'PUT /api/v1/user_preferences' do
    let(:valid_update_params) do
      {
        user_preference: {
          notification_time: '09:00:00',
          timezone: 'America/New_York'
        }
      }
    end

    let(:invalid_update_params) do
      {
        user_preference: {
          notification_time: '',
          timezone: ''
        }
      }
    end

    context 'with valid authentication and existing preferences' do
      before { user_preference } # Create the user preference

      it 'updates the user preferences with valid data' do
        put '/api/v1/user_preferences', params: valid_update_params, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['notification_time']).to eq('09:00')
        expect(json_response['data']['timezone']).to eq('America/New_York')
        expect(json_response['message']).to eq('User preferences updated successfully')

        # Verify the database was updated
        user_preference.reload
        expect(user_preference.notification_time.strftime('%H:%M')).to eq('09:00')
        expect(user_preference.timezone).to eq('America/New_York')
      end

      it 'updates the onboarding notification time when preferences are updated' do
        # Ensure there's no existing onboarding record
        expect(user.onboarding).to be_nil

        # Record the time before the update
        time_before = Time.current

        put '/api/v1/user_preferences', params: valid_update_params, headers: headers

        expect(response).to have_http_status(:ok)

        # Verify onboarding record was created and notification_time_setting was updated
        user.reload
        expect(user.onboarding).to be_present
        expect(user.onboarding.notification_time_setting).to be_present
        expect(user.onboarding.notification_time_setting).to be >= time_before
        expect(user.onboarding.notification_time_setting).to be <= Time.current
      end

      it 'updates existing onboarding notification time when preferences are updated' do
        # Create an existing onboarding record with an old notification time
        old_time = 1.hour.ago
        existing_onboarding = create(:onboarding, user: user, notification_time_setting: old_time)

        # Record the time before the update
        time_before = Time.current

        put '/api/v1/user_preferences', params: valid_update_params, headers: headers

        expect(response).to have_http_status(:ok)

        # Verify the existing onboarding record's notification_time_setting was updated
        existing_onboarding.reload
        expect(existing_onboarding.notification_time_setting).to be_present
        expect(existing_onboarding.notification_time_setting).to be >= time_before
        expect(existing_onboarding.notification_time_setting).to be <= Time.current
        expect(existing_onboarding.notification_time_setting).to be > old_time
      end

      it 'updates only notification_time when timezone is not provided' do
        params = { user_preference: { notification_time: '18:30:00' } }
        put '/api/v1/user_preferences', params: params, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['notification_time']).to eq('18:30')
        expect(json_response['data']['timezone']).to eq('Asia/Kolkata') # Should remain unchanged
      end

      it 'updates only timezone when notification_time is not provided' do
        params = { user_preference: { timezone: 'Europe/London' } }
        put '/api/v1/user_preferences', params: params, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['notification_time']).to eq('14:30') # Should remain unchanged
        expect(json_response['data']['timezone']).to eq('Europe/London')
      end

      it 'allows empty values for notification_time and timezone' do
        put '/api/v1/user_preferences', params: invalid_update_params, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['notification_time']).to be_nil
        expect(json_response['data']['timezone']).to eq('')
        expect(json_response['message']).to eq('User preferences updated successfully')
      end
    end

    context 'with valid authentication but no existing preferences' do
      it 'creates and updates new user preferences' do
        expect {
          put '/api/v1/user_preferences', params: valid_update_params, headers: headers
        }.to change(UserPreference, :count).by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['notification_time']).to eq('09:00')
        expect(json_response['data']['timezone']).to eq('America/New_York')
        expect(json_response['message']).to eq('User preferences updated successfully')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        put '/api/v1/user_preferences', params: valid_update_params

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing authorization token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        put '/api/v1/user_preferences', params: valid_update_params, headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid token')
      end
    end
  end

  describe 'PATCH /api/v1/user_preferences' do
    let(:valid_update_params) do
      {
        user_preference: {
          notification_time: '20:15:00',
          timezone: 'Australia/Sydney'
        }
      }
    end

    context 'with valid authentication and existing preferences' do
      before { user_preference } # Create the user preference

      it 'updates the user preferences via PATCH' do
        patch '/api/v1/user_preferences', params: valid_update_params, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['notification_time']).to eq('20:15')
        expect(json_response['data']['timezone']).to eq('Australia/Sydney')
        expect(json_response['message']).to eq('User preferences updated successfully')
      end
    end
  end
end
