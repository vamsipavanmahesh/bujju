require 'rails_helper'

RSpec.describe 'Api::V1::Onboardings', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:onboarding) { create(:onboarding, user: user) }
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

  describe 'GET /api/v1/onboarding' do
    context 'with valid authentication and existing onboarding' do
      before { onboarding } # Create the onboarding

      it 'returns the onboarding settings' do
        get '/api/v1/onboarding', headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['id']).to eq(onboarding.id)
        expect(json_response['data']).to have_key('notification_time_setting')
        expect(json_response['data']).to have_key('created_at')
        expect(json_response['data']).to have_key('updated_at')
      end
    end

    context 'with valid authentication but no onboarding' do
      it 'creates and returns new onboarding' do
        expect {
          get '/api/v1/onboarding', headers: headers
        }.to change(Onboarding, :count).by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']).to have_key('id')
        expect(json_response['data']['notification_time_setting']).to be_nil
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/onboarding'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing authorization token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        get '/api/v1/onboarding', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid token')
      end
    end
  end
end
