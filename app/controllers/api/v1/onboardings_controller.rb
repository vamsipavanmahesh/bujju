class Api::V1::OnboardingsController < Api::V1::AuthController
  before_action :set_onboarding, only: [ :show ]

  # GET /api/v1/onboarding
  def show
    render json: {
      success: true,
      data: ActiveModelSerializers::SerializableResource.new(@onboarding).as_json
    }
  end

  private

  def set_onboarding
    @onboarding = current_user.onboarding

    unless @onboarding
      # Create onboarding record if it doesn't exist
      @onboarding = current_user.create_onboarding!
    end
  end
end
