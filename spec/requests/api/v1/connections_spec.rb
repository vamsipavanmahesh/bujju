require 'rails_helper'

RSpec.describe 'Api::V1::Connections', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:connection) { create(:connection, user: user) }
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

  describe 'GET /api/v1/connections' do
    context 'with valid authentication' do
      before do
        create_list(:connection, 3, user: user)
        create(:connection, user: other_user) # Should not be included
      end

      it 'returns all connections for the current user' do
        get '/api/v1/connections', headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to eq(3)
        expect(json_response['data'].first).to have_key('id')
        expect(json_response['data'].first).to have_key('name')
        expect(json_response['data'].first).to have_key('phone_number')
        expect(json_response['data'].first).to have_key('relationship')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/connections'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing authorization token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        get '/api/v1/connections', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid token')
      end
    end
  end

  describe 'GET /api/v1/connections/:id' do
    context 'with valid authentication and existing connection' do
      it 'returns the connection' do
        get "/api/v1/connections/#{connection.id}", headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['id']).to eq(connection.id)
        expect(json_response['data']['name']).to eq(connection.name)
        expect(json_response['data']['phone_number']).to eq(connection.phone_number)
        expect(json_response['data']['relationship']).to eq(connection.relationship)
      end
    end

    context 'with non-existent connection' do
      it 'returns not found' do
        get '/api/v1/connections/999', headers: headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Connection not found')
      end
    end

    context 'with connection belonging to another user' do
      let(:other_connection) { create(:connection, user: other_user) }

      it 'returns not found' do
        get "/api/v1/connections/#{other_connection.id}", headers: headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Connection not found')
      end
    end
  end

  describe 'POST /api/v1/connections' do
    let(:valid_attributes) { { connection: { name: 'John Doe', phone_number: '+1234567890', relationship: 'colleague' } } }
    let(:invalid_attributes) { { connection: { name: '', phone_number: '', relationship: '' } } }

    context 'with valid authentication and valid attributes' do
      it 'creates a new connection' do
        expect do
          post '/api/v1/connections', params: valid_attributes, headers: headers
        end.to change(user.connections, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['name']).to eq('John Doe')
        expect(json_response['data']['phone_number']).to eq('+1234567890')
        expect(json_response['data']['relationship']).to eq('colleague')
        expect(json_response['message']).to eq('Connection created successfully')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        post '/api/v1/connections', params: invalid_attributes, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to include("Name can't be blank")
        expect(json_response['errors']).to include("Phone number can't be blank")
        expect(json_response['errors']).to include("Relationship can't be blank")
      end
    end
  end

  describe 'PUT /api/v1/connections/:id' do
    let(:update_attributes) { { connection: { name: 'Updated Name', phone_number: '+9876543210', relationship: 'family' } } }
    let(:invalid_attributes) { { connection: { name: '', phone_number: '', relationship: '' } } }

    context 'with valid authentication and valid attributes' do
      it 'updates the connection' do
        put "/api/v1/connections/#{connection.id}", params: update_attributes, headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['name']).to eq('Updated Name')
        expect(json_response['data']['phone_number']).to eq('+9876543210')
        expect(json_response['data']['relationship']).to eq('family')
        expect(json_response['message']).to eq('Connection updated successfully')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        put "/api/v1/connections/#{connection.id}", params: invalid_attributes, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to include("Name can't be blank")
        expect(json_response['errors']).to include("Phone number can't be blank")
        expect(json_response['errors']).to include("Relationship can't be blank")
      end
    end

    context 'with non-existent connection' do
      it 'returns not found' do
        put '/api/v1/connections/999', params: update_attributes, headers: headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Connection not found')
      end
    end
  end

  describe 'DELETE /api/v1/connections/:id' do
    context 'with valid authentication and existing connection' do
      it 'deletes the connection' do
        connection # Create the connection
        expect do
          delete "/api/v1/connections/#{connection.id}", headers: headers
        end.to change(user.connections, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Connection deleted successfully')
      end
    end

    context 'with non-existent connection' do
      it 'returns not found' do
        delete '/api/v1/connections/999', headers: headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Connection not found')
      end
    end
  end
end
