class Api::V1::ConnectionsController < Api::V1::AuthController
  before_action :set_connection, only: [ :show, :update, :destroy ]

  # GET /api/v1/connections
  def index
    connections = current_user.connections.order(:name)
    render json: {
      success: true,
      data: ActiveModelSerializers::SerializableResource.new(connections).as_json
    }
  end

  # GET /api/v1/connections/:id
  def show
    render json: {
      success: true,
      data: ActiveModelSerializers::SerializableResource.new(@connection).as_json
    }
  end

  # POST /api/v1/connections
  def create
    connection = current_user.connections.build(connection_params)

    if connection.save
      render json: {
        success: true,
        data: ActiveModelSerializers::SerializableResource.new(connection).as_json,
        message: "Connection created successfully"
      }, status: :created
    else
      render json: {
        success: false,
        errors: connection.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/connections/:id
  def update
    if @connection.update(connection_params)
      render json: {
        success: true,
        data: ActiveModelSerializers::SerializableResource.new(@connection).as_json,
        message: "Connection updated successfully"
      }
    else
      render json: {
        success: false,
        errors: @connection.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/connections/:id
  def destroy
    @connection.destroy
    render json: {
      success: true,
      message: "Connection deleted successfully"
    }
  end

  private

  def set_connection
    @connection = current_user.connections.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: "Connection not found"
    }, status: :not_found
  end

  def connection_params
    params.require(:connection).permit(:name, :phone_number, :relationship)
  end
end
